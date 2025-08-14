import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskReportsScreen extends StatefulWidget {
  const TaskReportsScreen({super.key});

  @override
  State<TaskReportsScreen> createState() => _TaskReportsScreenState();
}

class _TaskReportsScreenState extends State<TaskReportsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> reports = [];
  bool _loading = true;
  String? _error;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchTaskReports();

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

  Future<void> _fetchTaskReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // For now, using mock data. Replace with actual API call when backend is ready
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      setState(() {
        reports = [
          {
            'employee': 'Alice Johnson',
            'department': 'Design',
            'assigned': 8,
            'completed': 6,
            'pending': 2,
            'completionRate': 75.0,
            'avatar': '👩‍🎨',
          },
          {
            'employee': 'Bob Smith',
            'department': 'Development',
            'assigned': 12,
            'completed': 10,
            'pending': 2,
            'completionRate': 83.3,
            'avatar': '👨‍💻',
          },
          {
            'employee': 'Carol Davis',
            'department': 'Marketing',
            'assigned': 5,
            'completed': 4,
            'pending': 1,
            'completionRate': 80.0,
            'avatar': '👩‍💼',
          },
          {
            'employee': 'David Wilson',
            'department': 'Sales',
            'assigned': 15,
            'completed': 12,
            'pending': 3,
            'completionRate': 80.0,
            'avatar': '👨‍💼',
          },
          {
            'employee': 'Emma Brown',
            'department': 'HR',
            'assigned': 6,
            'completed': 5,
            'pending': 1,
            'completionRate': 83.3,
            'avatar': '👩‍💼',
          },
        ];
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load task reports: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Color _getCompletionRateColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 75) return Colors.orange;
    if (rate >= 60) return Colors.yellow.shade700;
    return Colors.red;
  }

  IconData _getCompletionRateIcon(double rate) {
    if (rate >= 90) return Icons.trending_up;
    if (rate >= 75) return Icons.check_circle;
    if (rate >= 60) return Icons.warning;
    return Icons.error;
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
                            Icons.assessment,
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
                                'Task Reports',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                              Text(
                                'Track team performance and productivity',
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
                            onPressed: _fetchTaskReports,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Summary Cards
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Total Tasks',
                            value: reports.fold<int>(
                              0,
                              (sum, report) =>
                                  sum + (report['assigned'] as int),
                            ),
                            icon: Icons.assignment,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Completed',
                            value: reports.fold<int>(
                              0,
                              (sum, report) =>
                                  sum + (report['completed'] as int),
                            ),
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Pending',
                            value: reports.fold<int>(
                              0,
                              (sum, report) => sum + (report['pending'] as int),
                            ),
                            icon: Icons.pending,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

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
                                  'Loading task reports...',
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
                                  onPressed: _fetchTaskReports,
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
                        : RefreshIndicator(
                            onRefresh: _fetchTaskReports,
                            color: Colors.purple.shade600,
                            child: reports.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.assessment_outlined,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No task reports available',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Task reports will appear here once tasks are assigned',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    itemCount: reports.length,
                                    itemBuilder: (context, index) {
                                      final report = reports[index];
                                      final completionRate =
                                          report['completionRate'] as double;
                                      final rateColor = _getCompletionRateColor(
                                        completionRate,
                                      );

                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
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
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            children: [
                                              // Employee Info
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.purple.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      report['avatar'],
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          report['employee'],
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
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .blue
                                                                .shade50,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .blue
                                                                  .shade200,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            report['department'],
                                                            style:
                                                                GoogleFonts.poppins(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Colors
                                                                      .blue
                                                                      .shade700,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: rateColor
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: rateColor
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      _getCompletionRateIcon(
                                                        completionRate,
                                                      ),
                                                      color: rateColor,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 20),

                                              // Task Statistics
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildStatCard(
                                                      title: 'Assigned',
                                                      value: report['assigned']
                                                          .toString(),
                                                      icon: Icons.assignment,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: _buildStatCard(
                                                      title: 'Completed',
                                                      value: report['completed']
                                                          .toString(),
                                                      icon: Icons.check_circle,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: _buildStatCard(
                                                      title: 'Pending',
                                                      value: report['pending']
                                                          .toString(),
                                                      icon: Icons.pending,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 16),

                                              // Progress Bar
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Completion Rate',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: Colors
                                                                  .grey
                                                                  .shade700,
                                                            ),
                                                      ),
                                                      Text(
                                                        '${completionRate.toStringAsFixed(1)}%',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: rateColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  LinearProgressIndicator(
                                                    value: completionRate / 100,
                                                    backgroundColor:
                                                        Colors.grey.shade200,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(rateColor),
                                                    minHeight: 8,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
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

  Widget _buildSummaryCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
