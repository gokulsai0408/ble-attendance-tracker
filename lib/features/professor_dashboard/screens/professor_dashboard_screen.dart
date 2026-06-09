import 'package:flutter/material.dart';
import '../widgets/course_stats_card.dart';
import '../widgets/live_attendance_card.dart';
import 'professor_analytics_screen.dart';

class ProfessorDashboardScreen extends StatelessWidget {
  const ProfessorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfessorAnalyticsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Active Lectures',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            LiveAttendanceCard(
              courseName: 'Mobile Computing',
              room: 'LH-201',
              presentCount: 42,
              totalCount: 50,
            ),
            SizedBox(height: 24),
            Text(
              'Your Courses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            CourseStatsCard(
              courseName: 'Mobile Computing',
              attendanceRate: 0.88,
              totalStudents: 50,
            ),
            SizedBox(height: 12),
            CourseStatsCard(
              courseName: 'Computer Networks',
              attendanceRate: 0.75,
              totalStudents: 45,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Starting Bluetooth Broadcast...'))
          );
        },
        label: const Text('Start New Session'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
