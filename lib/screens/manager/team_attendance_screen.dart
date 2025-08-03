import 'package:flutter/material.dart';

class TeamAttendanceScreen extends StatelessWidget {
  const TeamAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> teamAttendance = [
      {'name': 'Alice', 'status': 'Present'},
      {'name': 'Bob', 'status': 'Absent'},
      {'name': 'Charlie', 'status': 'Present'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Team Attendance')),
      body: ListView.builder(
        itemCount: teamAttendance.length,
        itemBuilder: (context, index) {
          final member = teamAttendance[index];
          return ListTile(
            title: Text(member['name'] ?? ''),
            trailing: Text(member['status'] ?? ''),
          );
        },
      ),
    );
  }
}
