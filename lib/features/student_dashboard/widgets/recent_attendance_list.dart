import 'package:flutter/material.dart';

class RecentAttendanceList extends StatelessWidget {
  const RecentAttendanceList({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final records = [
      {'course': 'Mobile Computing', 'date': 'Today, 10:00 AM', 'status': 'Present'},
      {'course': 'Computer Networks', 'date': 'Yesterday, 2:00 PM', 'status': 'Present'},
      {'course': 'Software Engineering', 'date': '24 Oct, 9:00 AM', 'status': 'Absent'},
      {'course': 'Database Systems', 'date': '23 Oct, 11:00 AM', 'status': 'Present'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final isPresent = record['status'] == 'Present';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
            child: Icon(
              isPresent ? Icons.check : Icons.close,
              color: isPresent ? Colors.green : Colors.red,
            ),
          ),
          title: Text(record['course']!, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(record['date']!),
          trailing: Text(
            record['status']!,
            style: TextStyle(
              color: isPresent ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
