import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

// Utility function to convert UTC time to local time for display
String _formatLocalTime(String? utcTimeString) {
  if (utcTimeString == null) return '-';
  try {
    final utcTime = DateTime.parse(utcTimeString);
    final localTime = utcTime.toLocal();
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return '-';
  }
}

// Utility function to format date for display
String _formatDate(String? utcTimeString) {
  if (utcTimeString == null) return '-';
  try {
    final utcTime = DateTime.parse(utcTimeString);
    final localTime = utcTime.toLocal();
    return '${localTime.day.toString().padLeft(2, '0')}/${localTime.month.toString().padLeft(2, '0')}/${localTime.year}';
  } catch (e) {
    return '-';
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool checkedIn = false;
  DateTime? checkInTime;
  DateTime? checkOutTime;
  List<Map<String, dynamic>> history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await apiService.get('/attendance/history');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          history = data.cast<Map<String, dynamic>>();
          // Determine if currently checked in
          final open = history.cast<Map<String, dynamic>>().firstWhere(
            (rec) => rec['checkOut'] == null,
            orElse: () => <String, dynamic>{},
          );
          if (open.isNotEmpty) {
            checkedIn = true;
            // Parse UTC time and convert to local time
            final utcTime = DateTime.parse(open['checkIn']);
            checkInTime = utcTime.toLocal();
            checkOutTime = null;
          } else {
            checkedIn = false;
            checkInTime = null;
            checkOutTime = null;
          }
        });
      } else {
        setState(() {
          _error = 'Failed to load history';
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

  Future<void> _checkIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now(); // Device time
      final deviceTimeString = now.toIso8601String(); // Send device time

      final res = await apiService.post('/attendance/checkin', {
        "checkIn": deviceTimeString,
        "timezone": now.timeZoneName,
      });
      if (res.statusCode == 200) {
        await _fetchHistory();
      } else {
        final data = jsonDecode(res.body);
        setState(() {
          _error = data['msg'] ?? 'Check-in failed';
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

  Future<void> _checkOut() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now(); // Device time
      final deviceTimeString = now.toIso8601String(); // Send device time

      final res = await apiService.post('/attendance/checkout', {
        "checkOut": deviceTimeString,
        "timezone": now.timeZoneName,
      });
      if (res.statusCode == 200) {
        await _fetchHistory();
      } else {
        final data = jsonDecode(res.body);
        setState(() {
          _error = data['msg'] ?? 'Check-out failed';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: checkedIn ? null : _checkIn,
                        child: const Text('Check In'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: checkedIn ? _checkOut : null,
                        child: const Text('Check Out'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    checkedIn
                        ? 'Checked in at: ${checkInTime != null ? _formatLocalTime(checkInTime!.toIso8601String()) : '-'}'
                        : 'Not checked in',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Attendance History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: history.isEmpty
                        ? const Text('No attendance records.')
                        : ListView.builder(
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              final record = history[index];
                              return ListTile(
                                title: Text(
                                  'Date: ${_formatDate(record['checkIn']?.toString())}',
                                ),
                                subtitle: Text(
                                  'In: ${_formatLocalTime(record['checkIn']?.toString())}  '
                                  'Out: ${_formatLocalTime(record['checkOut']?.toString())}  '
                                  'Hours: ${record['workingHours'] != null ? record['workingHours'].toStringAsFixed(2) : '-'}',
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
