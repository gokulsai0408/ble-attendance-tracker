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

  int _validIntervals = 0;
  bool _hasShownPopup = false;
  bool _isReporting = false;

  BleBeaconDetection? _currentDetection;
  BleBeaconDetection? get currentDetection => _currentDetection;

  // For testing, we use a mock session ID.
  // In production, this would be determined by the specific beacon UID or room.
  final String _activeSessionId = "SESSION_ID_123";

  StudentDashboardController() {
    _bleService.isScanningStream.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });

    _bleService.detectionStream.listen(_handleDetectionCycle);
  }

  void _handleDetectionCycle(BleBeaconDetection? detection) async {
    _currentDetection = detection;
    
    if (detection == null || !detection.isPresenceValid) {
      // If we move away, stop marking as in class
      if (_presenceStatus == StudentPresenceStatus.inClass) {
        _presenceStatus = StudentPresenceStatus.outOfRange;
        notifyListeners();
      }
    } else {
      // Automatically report to backend if we detect the beacon
      if (!_isReporting && _isSessionActive) {
        await _reportPresenceToBackend(detection);
      }
    }
  }

  Future<void> _reportPresenceToBackend(BleBeaconDetection detection) async {
    _isReporting = true;
    try {
      // This checks if the student is "enrolled" and nearby via backend logic
      final isVerifiedOnServer = await _attendanceApi.markAttendance(
        userId: AuthState.instance.uid ?? "STUDENT_GOKUL",
        courseId: _activeSessionId,
        beaconId: detection.deviceId,
      );

      if (isVerifiedOnServer) {
        _presenceStatus = StudentPresenceStatus.inClass;
        _validIntervals++;
        
        if (!_hasShownPopup) {
          _hasShownPopup = true;
          // Triggering the popup once to welcome the student
        }
      } else {
        _presenceStatus = StudentPresenceStatus.outOfRange;
      }
    } catch (e) {
      debugPrint("Automatic reporting failed: $e");
    } finally {
      _isReporting = false;
      notifyListeners();
    }
  }

  Future<void> startAttendanceSession(BuildContext context) async {
    if (_isSessionActive) return;

    _isSessionActive = true;
    _validIntervals = 0;
    _hasShownPopup = false;
    _presenceStatus = StudentPresenceStatus.searching;
    notifyListeners();

    // Scan listener for the initial AirPods-style popup
    StreamSubscription? popupSub;
    popupSub = _bleService.detectionStream.listen((detection) {
      if (detection != null && detection.isPresenceValid && !_hasShownPopup && context.mounted) {
        _hasShownPopup = true;
        LectureDetectedPopup.show(
          context,
          detection,
          "Mobile Computing",
          "LH-201",
          () {}, // Auto-confirms in background
        );
        popupSub?.cancel();
      }
    });

    await _bleService.startScanning();
  }

  Future<void> endAttendanceSession(BuildContext context) async {
    await _bleService.stopScanning();
    _isSessionActive = false;

    final validMinutes = (_validIntervals * 30) ~/ 60;
    final bool isPresent = validMinutes >= 1; // 1 min threshold for demo

    await _attendanceApi.markFinalAttendance(
      userId: AuthState.instance.uid ?? "STUDENT_GOKUL",
      courseId: _activeSessionId,
      validMinutes: validMinutes,
      isPresent: isPresent,
    );

    if (context.mounted) {
      _showFinalStatusDialog(context, validMinutes, isPresent);
    }
    
    notifyListeners();
  }

  void _showFinalStatusDialog(BuildContext context, int minutes, bool isPresent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPresent ? "Attendance Recorded" : "Insufficient Presence"),
        content: Text("You were present for $minutes minutes.\nStatus: ${isPresent ? "PRESENT" : "ABSENT"}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }
}
