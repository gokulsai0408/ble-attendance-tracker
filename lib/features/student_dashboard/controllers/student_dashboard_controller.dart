import 'dart:async';
import 'package:flutter/material.dart';
import '../../ble_detection/services/ble_attendance_service.dart';
import '../../ble_detection/models/ble_beacon_detection.dart';
import '../../ble_detection/widgets/lecture_detected_popup.dart';
import '../../attendance/services/attendance_api_service.dart';
import '../../auth/services/auth_state.dart';

enum StudentPresenceStatus {
  searching,
  inClass,
  outOfRange,
}

class StudentDashboardController extends ChangeNotifier {
  final BleAttendanceService _bleService = BleAttendanceService();
  final AttendanceApiService _attendanceApi = AttendanceApiService();

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  bool _isSessionActive = false;
  bool get isSessionActive => _isSessionActive;

  StudentPresenceStatus _presenceStatus = StudentPresenceStatus.searching;
  StudentPresenceStatus get presenceStatus => _presenceStatus;

  int _totalIntervals = 0;
  int _validIntervals = 0;
  bool _hasShownPopup = false;

  BleBeaconDetection? _currentDetection;
  BleBeaconDetection? get currentDetection => _currentDetection;

  StudentDashboardController() {
    _bleService.isScanningStream.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });

    _bleService.detectionStream.listen(_handleDetectionCycle);
  }

  void _handleDetectionCycle(BleBeaconDetection? detection) {
    _currentDetection = detection;
    
    if (detection == null) {
      // If we were in class and now beacon is gone
      if (_presenceStatus == StudentPresenceStatus.inClass) {
        _presenceStatus = StudentPresenceStatus.outOfRange;
      } else if (_presenceStatus != StudentPresenceStatus.outOfRange) {
         _presenceStatus = StudentPresenceStatus.searching;
      }
    } else {
      if (detection.isPresenceValid) {
        _presenceStatus = StudentPresenceStatus.inClass;
        _validIntervals++;
      } else {
        _presenceStatus = StudentPresenceStatus.outOfRange;
      }
    }

    if (_isSessionActive) {
      _totalIntervals++;
      notifyListeners();
    }
  }

  Future<void> startAttendanceSession(BuildContext context) async {
    if (_isSessionActive) return;

    _isSessionActive = true;
    _totalIntervals = 0;
    _validIntervals = 0;
    _hasShownPopup = false;
    _presenceStatus = StudentPresenceStatus.searching;
    notifyListeners();

    // One-time listener for the initial detection popup
    StreamSubscription? subscription;
    subscription = _bleService.detectionStream.listen((detection) {
      if (detection != null &&
          detection.isPresenceValid &&
          !_hasShownPopup &&
          context.mounted) {
        _hasShownPopup = true;
        LectureDetectedPopup.show(
          context,
          detection,
          "Mobile Computing",
          "LH-201",
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Automatic Tracking Enabled")),
            );
          },
        );
        subscription?.cancel();
      }
    });

    await _bleService.startScanning();
  }

  Future<void> endAttendanceSession(BuildContext context) async {
    await _bleService.stopScanning();
    _isSessionActive = false;

    final validMinutes = (_validIntervals * 30) ~/ 60;
    final bool isPresent = validMinutes >= 50;

    if (context.mounted) {
      _showFinalStatusDialog(context, validMinutes, isPresent);
    }

    await _attendanceApi.markFinalAttendance(
      userId: AuthState.instance.uid ?? "STUDENT_GOKUL",
      courseId: "MC_101",
      validMinutes: validMinutes,
      isPresent: isPresent,
    );
    notifyListeners();
  }

  void _showFinalStatusDialog(BuildContext context, int minutes, bool isPresent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPresent ? "Attendance Recorded" : "Session Summary"),
        content: Text(
            "Total Valid Presence: $minutes minutes.\n\nStatus: ${isPresent ? "PRESENT" : "ABSENT (Insufficient Presence)"}"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  // Compatibility methods
  Future<void> startAttendanceScan(BuildContext context) => startAttendanceSession(context);
  void stopScan() => _bleService.stopScanning();

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }
}
