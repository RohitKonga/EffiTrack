import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class TeamAttendanceScreen extends StatefulWidget {
  const TeamAttendanceScreen({super.key});

  @override
  State<TeamAttendanceScreen> createState() => _TeamAttendanceScreenState();
}

class _TeamAttendanceScreenState extends State<TeamAttendanceScreen> {
  Map<String, dynamic>? teamData;
  bool _loading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  String? _managerDepartment;

  @override
  void initState() {
    super.initState();
    _fetchManagerInfo();
  }

  Future<void> _fetchManagerInfo() async {
    try {
      final res = await apiService.get('/profile');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _managerDepartment = data['department'];
        });
        _fetchTeamAttendance();
      } else {
        setState(() {
          _error = 'Failed to load manager info';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _fetchTeamAttendance() async {
    if (_managerDepartment == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dateString =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final res = await apiService.get(
        '/attendance/team/$_managerDepartment?date=$dateString',
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          teamData = data;
        });
      } else {
        setState(() {
          _error = 'Failed to load team attendance';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              onSurface: Colors.indigo.shade700,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchTeamAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Date',
            onPressed: _selectDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTeamAttendance,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading team attendance...'),
                    ],
                  ),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchTeamAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchTeamAttendance,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with date
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.group,
                                      color: Colors.indigo.shade600,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${teamData?['department'] ?? 'Team'} Team Attendance',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.indigo.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Statistics
                        if (teamData?['statistics'] != null) ...[
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Team Statistics',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Present',
                                          teamData!['statistics']['present']
                                              .toString(),
                                          Colors.green,
                                          Icons.check_circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Absent',
                                          teamData!['statistics']['absent']
                                              .toString(),
                                          Colors.red,
                                          Icons.cancel,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Total',
                                          teamData!['statistics']['total']
                                              .toString(),
                                          Colors.blue,
                                          Icons.people,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.trending_up,
                                          color: Colors.indigo.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Team Attendance Rate: ${teamData!['statistics']['attendanceRate']}%',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.indigo.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Team Members List
                        Text(
                          'Team Members',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (teamData?['teamMembers'] != null) ...[
                          ...List.generate(
                            (teamData!['teamMembers'] as List).length,
                            (index) {
                              final member = teamData!['teamMembers'][index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        member['status'] == 'Present'
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    child: Icon(
                                      member['status'] == 'Present'
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: member['status'] == 'Present'
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                  title: Text(
                                    member['name'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member['email'],
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (member['checkInTime'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Check-in: ${_formatTime(member['checkInTime'])}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                      if (member['checkOutTime'] != null) ...[
                                        Text(
                                          'Check-out: ${_formatTime(member['checkOutTime'])}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                      if (member['workingHours'] != null) ...[
                                        Text(
                                          'Hours: ${member['workingHours'].toStringAsFixed(1)}h',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: member['status'] == 'Present'
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      member['status'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: member['status'] == 'Present'
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ] else ...[
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'No team members found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return 'N/A';
    try {
      final date = DateTime.parse(timeString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
