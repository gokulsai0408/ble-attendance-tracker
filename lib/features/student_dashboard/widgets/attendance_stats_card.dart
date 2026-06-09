import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class AttendanceStatsCard extends StatelessWidget {
  const AttendanceStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 50.0,
              lineWidth: 10.0,
              percent: 0.85,
              center: const Text(
                "85%",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              progressColor: Theme.of(context).primaryColor,
              backgroundColor: Colors.grey.shade200,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
            ),
            const SizedBox(width: 20),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Attendance',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '34/40 Classes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'On Track',
                  style: TextStyle(fontSize: 14, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
