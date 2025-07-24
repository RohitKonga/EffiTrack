import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  Map<String, dynamic>? stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await apiService.get('/analytics/stats');
      if (res.statusCode == 200) {
        setState(() {
          stats = jsonDecode(res.body);
        });
      } else {
        setState(() {
          _error = 'Failed to load analytics';
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
      appBar: AppBar(title: const Text('Analytics Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : stats == null
          ? const Center(child: Text('No analytics data.'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Number of Employees: ${stats!['numEmployees']}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Total Tasks Assigned: ${stats!['totalTasks']}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Tasks Completed: ${stats!['completedTasks']}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Attendance Percentage: ${stats!['attendancePercent']}%',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Leaves Requested: ${stats!['leavesRequested']}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Leaves Approved: ${stats!['leavesApproved']}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Charts and trends can be added here using charts_flutter or fl_chart.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}
