import 'package:flutter/material.dart';

class LiveAttendanceCard extends StatelessWidget {
  final String courseName;
  final String room;
  final int presentCount;
  final int totalCount;

  const LiveAttendanceCard({
    super.key,
    required this.courseName,
    required this.room,
    required this.presentCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('Room: $room', style: TextStyle(color: Colors.blue.shade700)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Present', '$presentCount'),
                _buildStat('Absent', '${totalCount - presentCount}'),
                _buildStat('Total', '$totalCount'),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: presentCount / totalCount,
              backgroundColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
              minHeight: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
