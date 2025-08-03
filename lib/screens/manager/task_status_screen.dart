import 'package:flutter/material.dart';

class TaskStatusScreen extends StatelessWidget {
  const TaskStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> tasks = [
      {'employee': 'Alice', 'title': 'Prepare Report', 'status': 'Completed'},
      {'employee': 'Bob', 'title': 'Client Meeting', 'status': 'In Progress'},
      {'employee': 'Charlie', 'title': 'Update Website', 'status': 'To Do'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Task Status')),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text('${task['title']}'),
            subtitle: Text('Employee: ${task['employee']}'),
            trailing: Text(task['status'] ?? ''),
          );
        },
      ),
    );
  }
}
