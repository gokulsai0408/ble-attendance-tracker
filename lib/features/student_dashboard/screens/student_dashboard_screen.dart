import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/attendance_stats_card.dart';
import '../widgets/recent_attendance_list.dart';
import '../controllers/student_dashboard_controller.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back, Student!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const AttendanceStatsCard(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Attendance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const RecentAttendanceList(),
          ],
        ),
      ),
      floatingActionButton: Consumer<StudentDashboardController>(
        builder: (context, controller, child) {
          return FloatingActionButton.extended(
            onPressed: controller.isScanning 
                ? controller.stopScan 
                : () => controller.startAttendanceScan(context),
            label: Text(controller.isScanning ? 'Scanning...' : 'Scan for Class'),
            icon: controller.isScanning 
                ? const SizedBox(
                    width: 18, 
                    height: 18, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  )
                : const Icon(Icons.bluetooth_searching),
          );
        },
      ),
    );
  }
}
