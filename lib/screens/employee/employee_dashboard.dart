import 'package:flutter/material.dart';
import 'attendance_screen.dart';
import 'task_screen.dart';
import 'leave_screen.dart';
import 'profile_screen.dart';
import 'announcements_screen.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Real-time data
  final Map<String, dynamic> _stats = {
    'totalTasks': 0,
    'completedTasks': 0,
    'pendingLeaves': 0,
    'attendanceToday': false,
  };
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeStats();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployeeStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Fetch task statistics
      final taskRes = await apiService.get('/tasks/my');
      if (taskRes.statusCode == 200) {
        final tasks = jsonDecode(taskRes.body);
        int completed = 0;

        for (var task in tasks) {
          if (task['status'] == 'Completed') {
            completed++;
          }
        }

        _stats['totalTasks'] = tasks.length;
        _stats['completedTasks'] = completed;
      }

      // Fetch leave statistics
      final leaveRes = await apiService.get('/leaves/my');
      if (leaveRes.statusCode == 200) {
        final leaves = jsonDecode(leaveRes.body);
        int pending = 0;

        for (var leave in leaves) {
          if (leave['status'] == 'Pending') {
            pending++;
          }
        }

        _stats['pendingLeaves'] = pending;
      }

      // Check today's attendance
      final today = DateTime.now().toIso8601String().split('T')[0];
      final attendanceRes = await apiService.get('/attendance/history');
      if (attendanceRes.statusCode == 200) {
        final history = jsonDecode(attendanceRes.body);
        bool checkedInToday = false;

        for (var record in history) {
          final recordDate = record['checkIn'] != null
              ? DateTime.parse(
                  record['checkIn'],
                ).toIso8601String().split('T')[0]
              : null;

          if (recordDate == today && record['checkOut'] == null) {
            checkedInToday = true;
            break;
          }
        }

        _stats['attendanceToday'] = checkedInToday;
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard stats';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.indigo.shade50,
              Colors.purple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.indigo.shade600,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome Back!',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo.shade700,
                                      ),
                                    ),
                                    Text(
                                      'Employee Dashboard',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.logout,
                                    color: Colors.red.shade600,
                                    size: 20,
                                  ),
                                  tooltip: 'Logout',
                                  onPressed: () async {
                                    await NotificationService()
                                        .clearTokenOnServer();
                                    if (!context.mounted) return;
                                    await ApiService.logout(context);
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Quick Stats Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.blue.shade300, Colors.blue],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: _loading
                                ? Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'Loading workspace stats...',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : _error != null
                                ? Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Error Loading Stats',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _error!,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: _fetchEmployeeStats,
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.work,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Your Workspace',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Manage your daily tasks and activities',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.9),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.refresh,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            onPressed: _fetchEmployeeStats,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildStatItem(
                                              'Total Tasks',
                                              _stats['totalTasks'].toString(),
                                              Icons.assignment,
                                              Colors.blue.shade300,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildStatItem(
                                              'Completed',
                                              _stats['completedTasks']
                                                  .toString(),
                                              Icons.check_circle,
                                              Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildStatItem(
                                              'Pending Leaves',
                                              _stats['pendingLeaves']
                                                  .toString(),
                                              Icons.event_busy,
                                              Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildStatItem(
                                              'Status',
                                              _stats['attendanceToday']
                                                  ? 'In'
                                                  : 'Out',
                                              _stats['attendanceToday']
                                                  ? Icons.check_circle
                                                  : Icons.schedule,
                                              _stats['attendanceToday']
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Menu Grid
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          _buildMenuCard(
                            context,
                            'Attendance',
                            Icons.access_time,
                            Colors.green,
                            'Track your work hours',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AttendanceScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            context,
                            'Tasks',
                            Icons.task_alt,
                            Colors.blue,
                            'View assigned tasks',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TaskScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            context,
                            'Leave Requests',
                            Icons.event_note,
                            Colors.orange,
                            'Apply for leave',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LeaveScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            context,
                            'Profile',
                            Icons.person,
                            Colors.purple,
                            'Manage your profile',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            context,
                            'Announcements',
                            Icons.announcement,
                            Colors.teal,
                            'Company updates',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AnnouncementsScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            context,
                            'Support',
                            Icons.help_outline,
                            Colors.grey,
                            'Get help & support',
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Support feature coming soon!',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.indigo.shade600,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.1),
                        color.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
