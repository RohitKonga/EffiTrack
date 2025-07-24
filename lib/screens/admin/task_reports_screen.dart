import 'package:flutter/material.dart';

class TaskReportsScreen extends StatelessWidget {
  const TaskReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> reports = [
      {'employee': 'Alice', 'assigned': '5', 'completed': '4'},
      {'employee': 'Bob', 'assigned': '3', 'completed': '2'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Task Reports')),
      body: ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return ListTile(
            title: Text('Employee: ${report['employee']}'),
            subtitle: Text(
              'Assigned: ${report['assigned']}  Completed: ${report['completed']}',
            ),
          );
        },
      ),
    );
  }
}
