import 'package:flutter/material.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _employee, _title, _desc, _deadline;
  final _employees = ['Alice', 'Bob', 'Charlie'];

  void _assignTask() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task $_title assigned! Desc: $_desc, Deadline: $_deadline',
          ),
        ),
      );
      setState(() {
        _employee = null;
        _title = null;
        _desc = null;
        _deadline = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Employee'),
                value: _employee,
                items: _employees
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _employee = value),
                validator: (value) => value == null ? 'Select employee' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Task Title'),
                onSaved: (value) => _title = value,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) => _desc = value,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter description' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Deadline (YYYY-MM-DD)',
                ),
                onSaved: (value) => _deadline = value,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter deadline' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _assignTask,
                child: const Text('Assign Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
