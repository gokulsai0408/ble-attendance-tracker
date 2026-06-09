import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  static const String targetUuid = "12345678-1234-1234-1234-123456789abc";
  
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final _scanResultsController = StreamController<List<ScanResult>>.broadcast();
  
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

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

  Future<void> startScan() async {
    bool hasPermission = await requestPermissions();
    if (!hasPermission) return;

    // Stop existing scan
    await FlutterBluePlus.stopScan();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      // For testing: add all results, or filter by a name like "ESP32"
      final filteredResults = results.where((r) {
        return r.device.platformName.isNotEmpty;
      }).toList();
      
      _scanResultsController.add(filteredResults);
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      // withServices: [Guid(targetUuid)], // Removed for broader detection during testing
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  void dispose() {
    _scanResultsController.close();
    _scanSubscription?.cancel();
  }
}
