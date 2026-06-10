import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ble_beacon_detection.dart';

class BleAttendanceService {
  static const String targetUuid = "12345678-1234-1234-1234-123456789abc";
  static const String targetName = "AttendanceBeacon";
  
  final _detectionController = StreamController<BleBeaconDetection?>.broadcast();
  Stream<BleBeaconDetection?> get detectionStream => _detectionController.stream;

  final _isScanningController = StreamController<bool>.broadcast();
  Stream<bool> get isScanningStream => _isScanningController.stream;

  Timer? _periodicTimer;
  StreamSubscription? _scanSubscription;
  final Map<String, List<int>> _rssiBuffer = {};

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    }
    return true;
  }

  /// Unified scanning method
  Future<void> startScanning() async {
    if (!await requestPermissions()) {
      _detectionController.addError("Permissions denied");
      return;
    }

    _performScanCycle();
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _performScanCycle();
    });
  }

  Future<void> _performScanCycle() async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      _detectionController.addError("Bluetooth is off");
      return;
    }

    _isScanningController.add(true);
    _rssiBuffer.clear();

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == targetName || r.advertisementData.serviceUuids.contains(Guid(targetUuid))) {
          _rssiBuffer.putIfAbsent(r.device.remoteId.toString(), () => []).add(r.rssi);
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Scan error: $e");
    } finally {
      _isScanningController.add(false);
      _processScanResults();
    }
  }

  void _processScanResults() {
    if (_rssiBuffer.isEmpty) {
      _detectionController.add(null);
      return;
    }
    final entry = _rssiBuffer.entries.first;
    _detectionController.add(BleBeaconDetection(
      deviceId: entry.key,
      deviceName: targetName,
      serviceUuid: targetUuid,
      rssiValues: entry.value,
      detectedAt: DateTime.now(),
    ));
  }

  Future<void> stopScanning() async {
    _periodicTimer?.cancel();
    _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();
    _isScanningController.add(false);
  }

  void dispose() {
    _periodicTimer?.cancel();
    _scanSubscription?.cancel();
    _detectionController.close();
    _isScanningController.close();
  }
}
