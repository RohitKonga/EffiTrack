import 'package:flutter/material.dart';

class AttendanceReportsScreen extends StatelessWidget {
  const AttendanceReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> reports = [
      {'department': 'Sales', 'present': '10', 'absent': '2'},
      {'department': 'HR', 'present': '5', 'absent': '1'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Reports')),
      body: ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return ListTile(
            title: Text('Department: ${report['department']}'),
            subtitle: Text(
              'Present: ${report['present']}  Absent: ${report['absent']}',
            ),
          );
        },
      ),
    );
  }
}
