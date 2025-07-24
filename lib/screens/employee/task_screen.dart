import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<Map<String, dynamic>> tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await apiService.get('/tasks/my');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          tasks = data.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() {
          _error = 'Failed to load tasks';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(int index, String newStatus) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final taskId = tasks[index]['_id'];
      final res = await apiService.put('/tasks/$taskId/status', {
        'status': newStatus,
      });
      if (res.statusCode == 200) {
        await _fetchTasks();
      } else {
        setState(() {
          _error = 'Failed to update status';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showTaskDetails(int index) {
    final task = tasks[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task['title'] ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${task['description'] ?? ''}'),
            Text(
              'Deadline: ${task['deadline'] != null ? task['deadline'].toString().substring(0, 10) : '-'}',
            ),
            Text('Status: ${task['status']}'),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: task['status'],
              items: ['To Do', 'In Progress', 'Completed']
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _updateStatus(index, value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : tasks.isEmpty
          ? const Center(child: Text('No tasks assigned.'))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(task['title'] ?? ''),
                    subtitle: Text(
                      'Deadline: ${task['deadline'] != null ? task['deadline'].toString().substring(0, 10) : '-'}\nStatus: ${task['status']}',
                    ),
                    isThreeLine: true,
                    onTap: () => _showTaskDetails(index),
                    trailing: DropdownButton<String>(
                      value: task['status'],
                      items: ['To Do', 'In Progress', 'Completed']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) _updateStatus(index, value);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
