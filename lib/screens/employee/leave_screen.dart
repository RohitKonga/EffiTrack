import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _leaveType, _reason;
  DateTimeRange? _dateRange;
  final _leaveTypes = ['Sick Leave', 'Casual Leave', 'Earned Leave'];
  List<Map<String, dynamic>> leaveHistory = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLeaveHistory();
  }

  Future<void> _fetchLeaveHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await apiService.get('/leaves/my');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          leaveHistory = data.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() {
          _error = 'Failed to load leave history';
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

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate() || _dateRange == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    _formKey.currentState!.save();
    try {
      final res = await apiService.post('/leaves/request', {
        'type': _leaveType,
        'startDate': _dateRange!.start.toIso8601String(),
        'endDate': _dateRange!.end.toIso8601String(),
        'reason': _reason,
      });
      if (res.statusCode == 200) {
        await _fetchLeaveHistory();
        setState(() {
          _leaveType = null;
          _reason = null;
          _dateRange = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted!')),
        );
      } else {
        setState(() {
          _error = 'Failed to submit leave request';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error';
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Requests')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Leave Type',
                          ),
                          value: _leaveType,
                          items: _leaveTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _leaveType = value),
                          validator: (value) =>
                              value == null ? 'Select leave type' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Reason',
                          ),
                          onSaved: (value) => _reason = value,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter reason'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _dateRange == null
                                    ? 'Select Dates'
                                    : '${_dateRange!.start.toString().substring(0, 10)} to ${_dateRange!.end.toString().substring(0, 10)}',
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime(2025),
                                );
                                if (picked != null) {
                                  setState(() => _dateRange = picked);
                                }
                              },
                              child: const Text('Pick Dates'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _submitting
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _submitLeaveRequest,
                                child: const Text('Request Leave'),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Leave History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: leaveHistory.isEmpty
                        ? const Text('No leave requests.')
                        : ListView.builder(
                            itemCount: leaveHistory.length,
                            itemBuilder: (context, index) {
                              final leave = leaveHistory[index];
                              return ListTile(
                                title: Text('${leave['type']}'),
                                subtitle: Text(
                                  'Dates: ${leave['startDate']?.toString().substring(0, 10) ?? '-'} to ${leave['endDate']?.toString().substring(0, 10) ?? '-'}\nStatus: ${leave['status']}',
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
