import 'package:flutter/material.dart';

class CourseStatsCard extends StatelessWidget {
  final String courseName;
  final double attendanceRate;
  final int totalStudents;

  const CourseStatsCard({
    super.key,
    required this.courseName,
    required this.attendanceRate,
    required this.totalStudents,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$totalStudents Enrolled Students'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(attendanceRate * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
            ),
            const Text('Avg. Attendance', style: TextStyle(fontSize: 10)),
          ],
        ),
        onTap: () {
          // Navigate to details
        },
      ),
    );
  }
}
