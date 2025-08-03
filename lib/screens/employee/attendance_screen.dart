import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'dart:async';

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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    // Start real-time updates every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _fetchHistory();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
        print('🔍 HISTORY DATA: $data');
        setState(() {
          history = data.cast<Map<String, dynamic>>();

          // Determine if currently checked in
          final open = history.cast<Map<String, dynamic>>().firstWhere(
            (rec) => rec['checkOut'] == null,
            orElse: () => <String, dynamic>{},
          );
          if (open.isNotEmpty) {
            checkedIn = true;
            checkInTime = DateTime.parse(open['checkIn']);
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
      // Capture device current time (local timezone)
      final now = DateTime.now();
      final deviceTime = now.toIso8601String();

      print('🔍 DEVICE TIME CAPTURED: $deviceTime');
      print('🔍 DEVICE TIME TYPE: ${deviceTime.runtimeType}');

      final requestBody = {'deviceTime': deviceTime};
      print('🔍 REQUEST BODY: $requestBody');

      final res = await apiService.post('/attendance/checkin', requestBody);
      print('🔍 RESPONSE STATUS: ${res.statusCode}');
      print('🔍 RESPONSE BODY: ${res.body}');

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
      // Capture device current time (local timezone)
      final now = DateTime.now();
      final deviceTime = now.toIso8601String();

      print('🔍 DEVICE TIME CAPTURED (CHECKOUT): $deviceTime');
      print('🔍 DEVICE TIME TYPE (CHECKOUT): ${deviceTime.runtimeType}');

      final requestBody = {'deviceTime': deviceTime};
      print('🔍 REQUEST BODY (CHECKOUT): $requestBody');

      final res = await apiService.post('/attendance/checkout', requestBody);
      print('🔍 RESPONSE STATUS (CHECKOUT): ${res.statusCode}');
      print('🔍 RESPONSE BODY (CHECKOUT): ${res.body}');

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
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Attendance'),
            if (checkedIn) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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
                              final isCurrentSession =
                                  record['checkOut'] == null;

                              // For current session, show stored device time
                              String checkInDisplay =
                                  record['deviceCheckIn'] != null
                                  ? record['deviceCheckIn']
                                        .toString()
                                        .substring(11, 16)
                                  : (record['checkIn'] != null
                                        ? record['checkIn']
                                              .toString()
                                              .substring(11, 16)
                                        : '-');

                              String checkOutDisplay;
                              String hoursDisplay;

                              if (isCurrentSession) {
                                // Show "Active" for current session (not real-time)
                                checkOutDisplay = 'Active';
                                hoursDisplay = 'Calculating...';
                              } else {
                                // Show stored device time for completed sessions
                                checkOutDisplay =
                                    record['deviceCheckOut'] != null
                                    ? record['deviceCheckOut']
                                          .toString()
                                          .substring(11, 16)
                                    : (record['checkOut'] != null
                                          ? record['checkOut']
                                                .toString()
                                                .substring(11, 16)
                                          : '-');
                                hoursDisplay = record['workingHours'] != null
                                    ? record['workingHours'].toStringAsFixed(2)
                                    : '-';
                              }

                              return ListTile(
                                title: Text(
                                  'Date: ${record['checkIn']?.toString().substring(0, 10) ?? '-'}',
                                ),
                                subtitle: Text(
                                  'In: $checkInDisplay  '
                                  'Out: $checkOutDisplay  '
                                  'Hours: $hoursDisplay',
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
