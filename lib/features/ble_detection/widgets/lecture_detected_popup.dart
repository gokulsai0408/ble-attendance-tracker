import 'package:flutter/material.dart';
import '../models/ble_beacon_detection.dart';

class LectureDetectedPopup extends StatelessWidget {
  final BleBeaconDetection detection;
  final String courseName;
  final String classroomName;
  final VoidCallback onMarkAttendance;

  const LectureDetectedPopup({
    super.key,
    required this.detection,
    required this.courseName,
    required this.classroomName,
    required this.onMarkAttendance,
  });

  static void show(
    BuildContext context, 
    BleBeaconDetection detection, 
    String course, 
    String classroom, 
    VoidCallback onMark
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LectureDetectedPopup(
        detection: detection,
        courseName: course,
        classroomName: classroom,
        onMarkAttendance: onMark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.sensors, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Lecture Beacon Detected',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            courseName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          Text(
            'Classroom: $classroomName',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: detection.isPresenceValid ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  detection.isPresenceValid ? Icons.check_circle : Icons.warning,
                  size: 20,
                  color: detection.isPresenceValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Avg RSSI: ${detection.averageRssi.toStringAsFixed(1)} dBm',
                  style: TextStyle(
                    fontSize: 14, 
                    color: detection.isPresenceValid ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onMarkAttendance();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Confirm Presence'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
