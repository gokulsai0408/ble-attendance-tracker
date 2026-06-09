import 'package:flutter/material.dart';
import '../../ble_detection/services/ble_service.dart';
import '../../ble_detection/widgets/ble_detection_popup.dart';

class StudentDashboardController extends ChangeNotifier {
  final BleService _bleService = BleService();
  bool _isScanning = false;

  bool get isScanning => _isScanning;

  Future<void> startAttendanceScan(BuildContext context) async {
    _isScanning = true;
    notifyListeners();

    // Start the real scan in the background (don't await it here)
    _bleService.startScan().catchError((e) {
      debugPrint("Scan error: $e");
    });
    
    // Simulate finding a lecture hall after 2 seconds for demo purposes
    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      
      if (_isScanning) {
        _isScanning = false;
        notifyListeners();
        _bleService.stopScan();
        
        BleDetectionPopup.show(
          context, 
          "Mobile Computing", 
          "LH-201", 
          () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attendance Marked Successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                )
              );
            }
          }
        );
      }
    });
  }

  void stopScan() {
    _isScanning = false;
    _bleService.stopScan();
    notifyListeners();
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }
}
