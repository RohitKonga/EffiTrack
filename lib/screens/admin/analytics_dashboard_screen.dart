import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic> _stats = {
    'totalEmployees': 0,
    'totalTasks': 0,
    'completedTasks': 0,
    'attendanceRate': 0.0,
    'pendingTasks': 0,
    'overdueTasks': 0,
    'avgTaskCompletion': 0.0,
    'departmentStats': [],
  };
  bool _loading = true;
  String? _error;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();

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

  Future<void> _fetchAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Fetch user count
      final userRes = await apiService.get('/profile/all');
      if (userRes.statusCode == 200) {
        final users = jsonDecode(userRes.body);
        _stats['totalEmployees'] = users.length;
      }

      // Fetch task statistics
      final taskRes = await apiService.get('/tasks/all');
      if (taskRes.statusCode == 200) {
        final tasks = jsonDecode(taskRes.body);
        int completed = 0;
        int pending = 0;
        int overdue = 0;

        for (var task in tasks) {
          if (task['status'] == 'Completed') {
            completed++;
          } else if (task['status'] == 'To Do' ||
              task['status'] == 'In Progress') {
            pending++;
          }

          // Check if overdue
          if (task['dueDate'] != null) {
            try {
              final dueDate = DateTime.parse(task['dueDate']);
              if (dueDate.isBefore(DateTime.now()) &&
                  task['status'] != 'Completed') {
                overdue++;
              }
            } catch (e) {
              // Invalid date format
            }
          }
        }

        _stats['totalTasks'] = tasks.length;
        _stats['completedTasks'] = completed;
        _stats['pendingTasks'] = pending;
        _stats['overdueTasks'] = overdue;

        if (tasks.length > 0) {
          _stats['avgTaskCompletion'] = (completed / tasks.length * 100)
              .roundToDouble();
        }
      }

      // Fetch attendance rate (today's attendance)
      final today = DateTime.now().toIso8601String().split('T')[0];
      final attendanceRes = await apiService.get(
        '/attendance/reports?date=$today',
      );
      if (attendanceRes.statusCode == 200) {
        final data = jsonDecode(attendanceRes.body);
        if (data['hasData'] && data['employeeReports'] != null) {
          final totalEmployees =
              data['employeeTotalStats']['totalEmployees'] ?? 0;
          final presentEmployees =
              data['employeeTotalStats']['presentEmployees'] ?? 0;
          if (totalEmployees > 0) {
            _stats['attendanceRate'] = (presentEmployees / totalEmployees * 100)
                .roundToDouble();
          }
        }
      }

      // Fetch department statistics
      final deptRes = await apiService.get('/profile/departments');
      if (deptRes.statusCode == 200) {
        final departments = jsonDecode(deptRes.body);
        List<Map<String, dynamic>> deptStats = [];

        for (var dept in departments) {
          final deptName = dept['name'];
          final deptTaskRes = await apiService.get(
            '/tasks/department/$deptName',
          );
          if (deptTaskRes.statusCode == 200) {
            final deptTasks = jsonDecode(deptTaskRes.body);
            int deptCompleted = 0;
            int deptTotal = deptTasks.length;

            for (var task in deptTasks) {
              if (task['status'] == 'Completed') {
                deptCompleted++;
              }
            }

            deptStats.add({
              'name': deptName,
              'totalTasks': deptTotal,
              'completedTasks': deptCompleted,
              'completionRate': deptTotal > 0
                  ? (deptCompleted / deptTotal * 100).roundToDouble()
                  : 0.0,
            });
          }
        }

        _stats['departmentStats'] = deptStats;
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load analytics';
        _loading = false;
      });
    }
  }

  Color _getProgressColor(double value) {
    if (value >= 90) return Colors.green;
    if (value >= 75) return Colors.orange;
    if (value >= 60) return Colors.yellow.shade700;
    return Colors.red;
  }

  // IconData _getProgressIcon(double value) {
  //   if (value >= 90) return Icons.trending_up;
  //   if (value >= 75) return Icons.check_circle;
  //   if (value >= 60) return Icons.warning;
  //   return Icons.error;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.indigo.shade50,
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
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
                            Icons.analytics,
                            color: Colors.purple.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analytics Dashboard',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                              Text(
                                'Comprehensive insights and metrics',
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
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: Colors.purple.shade600,
                              size: 20,
                            ),
                            onPressed: _fetchAnalytics,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.purple,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading analytics...',
                                  style: TextStyle(color: Colors.purple),
                                ),
                              ],
                            ),
                          )
                        : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.red.shade700,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _fetchAnalytics,
                                  icon: Icon(Icons.refresh),
                                  label: Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _stats['totalEmployees'] == 0 &&
                              _stats['totalTasks'] == 0 &&
                              _stats['departmentStats'].isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.analytics_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No analytics data available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Analytics will appear here once data is available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchAnalytics,
                            color: Colors.purple.shade600,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Key Metrics Cards
                                  Text(
                                    'Key Metrics',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // First Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMetricCard(
                                          title: 'Total Employees',
                                          value: _stats['totalEmployees']
                                              .toString(),
                                          icon: Icons.people,
                                          color: Colors.blue,
                                          subtitle: 'Active team members',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildMetricCard(
                                          title: 'Total Tasks',
                                          value: _stats['totalTasks']
                                              .toString(),
                                          icon: Icons.assignment,
                                          color: Colors.orange,
                                          subtitle: 'Assigned tasks',
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Second Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMetricCard(
                                          title: 'Completed Tasks',
                                          value: _stats['completedTasks']
                                              .toString(),
                                          icon: Icons.check_circle,
                                          color: Colors.green,
                                          subtitle: 'Successfully completed',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildMetricCard(
                                          title: 'Attendance Rate',
                                          value: '${_stats['attendanceRate']}%',
                                          icon: Icons.timeline,
                                          color: Colors.purple,
                                          subtitle: 'Average attendance',
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 32),

                                  // Performance Overview
                                  Text(
                                    'Performance Overview',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        _buildProgressRow(
                                          'Task Completion Rate',
                                          _stats['avgTaskCompletion'],
                                          Icons.assignment_turned_in,
                                        ),
                                        const SizedBox(height: 16),
                                        _buildProgressRow(
                                          'Leave Approval Rate',
                                          85.0, // Default value, can be updated when leave API is ready
                                          Icons.approval,
                                        ),
                                        const SizedBox(height: 16),
                                        _buildProgressRow(
                                          'Pending Tasks',
                                          _stats['totalTasks'] > 0
                                              ? ((_stats['totalTasks'] -
                                                            _stats['completedTasks']) /
                                                        _stats['totalTasks'] *
                                                        100)
                                                    .roundToDouble()
                                              : 0.0,
                                          Icons.pending,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // Department Performance
                                  Text(
                                    'Department Performance',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  ...(_stats['departmentStats']
                                          as List<Map<String, dynamic>>)
                                      .map((dept) {
                                        final deptName = dept['name'];
                                        final deptStats = dept;

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.purple.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons.business,
                                                      color: Colors
                                                          .purple
                                                          .shade600,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          deptName,
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .grey
                                                                    .shade800,
                                                              ),
                                                        ),
                                                        Text(
                                                          '${deptStats['totalTasks']} tasks',
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .grey
                                                                    .shade600,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _getProgressColor(
                                                        deptStats['completionRate'],
                                                      ).withValues(alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: _getProgressColor(
                                                          deptStats['completionRate'],
                                                        ).withValues(alpha: 0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      '${deptStats['completionRate']}%',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: _getProgressColor(
                                                          deptStats['completionRate'],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              LinearProgressIndicator(
                                                value:
                                                    deptStats['completionRate'] /
                                                    100,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      _getProgressColor(
                                                        deptStats['completionRate'],
                                                      ),
                                                    ),
                                                minHeight: 6,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),

                                  const SizedBox(height: 32),

                                  // Quick Stats
                                  Text(
                                    'Quick Stats',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildQuickStatCard(
                                          title: 'Pending Tasks',
                                          value: _stats['pendingTasks']
                                              .toString(),
                                          icon: Icons.schedule,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildQuickStatCard(
                                          title: 'Overdue Tasks',
                                          value: _stats['overdueTasks']
                                              .toString(),
                                          icon: Icons.warning,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildQuickStatCard(
                                          title: 'Leaves Requested',
                                          value:
                                              '15', // Default value, can be updated when leave API is ready
                                          icon: Icons.event_note,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildQuickStatCard(
                                          title: 'Leaves Approved',
                                          value:
                                              '12', // Default value, can be updated when leave API is ready
                                          icon: Icons.check_circle_outline,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: color.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String title, double value, IconData icon) {
    final color = _getProgressColor(value);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: value / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '${value.toStringAsFixed(1)}%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
