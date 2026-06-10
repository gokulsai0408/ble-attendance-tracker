import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/attendance_stats_card.dart';
import '../widgets/recent_attendance_list.dart';
import '../controllers/student_dashboard_controller.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically start the BLE scan and backend connection upon login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentDashboardController>().startAttendanceSession(context);
    });
  }

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
            _buildAutomaticStatusIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Your Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
          if (!controller.isSessionActive) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => controller.endAttendanceSession(context),
            label: const Text('End Class Session'),
            backgroundColor: Colors.red,
            icon: const Icon(Icons.stop),
          );
        },
      ),
    );
  }

  Widget _buildAutomaticStatusIndicator() {
    return Consumer<StudentDashboardController>(
      builder: (context, controller, child) {
        Color statusColor;
        String statusText;
        IconData statusIcon;

        switch (controller.presenceStatus) {
          case StudentPresenceStatus.inClass:
            statusColor = Colors.green;
            statusText = "OK, Attendance is getting marked!";
            statusIcon = Icons.check_circle;
            break;
          case StudentPresenceStatus.outOfRange:
            statusColor = Colors.orange;
            statusText = "Out of Range / Signal Lost";
            statusIcon = Icons.warning;
            break;
          case StudentPresenceStatus.searching:
          default:
            statusColor = Colors.blue;
            statusText = "Scanning for Lecture Beacon...";
            statusIcon = Icons.radar;
            break;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              if (controller.isScanning && controller.presenceStatus == StudentPresenceStatus.searching)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (controller.currentDetection != null)
                      Text(
                        "Signal Strength: ${controller.currentDetection!.averageRssi.toStringAsFixed(0)} dBm",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
