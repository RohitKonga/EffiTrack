import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class AttendanceReportsScreen extends StatefulWidget {
  const AttendanceReportsScreen({super.key});

  @override
  State<AttendanceReportsScreen> createState() =>
      _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends State<AttendanceReportsScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? reportData;
  bool _loading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedStatsTabIndex =
      0; // 0 -> first available (Manager if present), 1 -> second
  int _selectedDepartmentTabIndex = 0; // 0 -> Manager, 1 -> Employee

  @override
  void initState() {
    super.initState();
    _fetchAttendanceReports();

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

  Future<void> _fetchAttendanceReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Format date as YYYY-MM-DD
      final dateString =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final res = await apiService.get('/attendance/reports?date=$dateString');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          reportData = data;
          // Reset selected tab if needed based on available tabs
          final hasManager = reportData?['managerTotalStats'] != null;
          final hasEmployee = reportData?['employeeTotalStats'] != null;
          if (hasManager && !hasEmployee) {
            _selectedStatsTabIndex = 0; // only Manager
          } else if (!hasManager && hasEmployee) {
            _selectedStatsTabIndex = 0; // only Employee as first
          } else {
            _selectedStatsTabIndex = 0; // default to first tab (Manager)
          }
        });
      } else {
        setState(() {
          _error = 'Failed to load attendance reports';
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
              primary: Colors.purple.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.purple.shade700,
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
      _fetchAttendanceReports();
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
                                'Attendance Reports',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                              Text(
                                'Track team attendance and performance',
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
                              Icons.calendar_today,
                              color: Colors.purple.shade600,
                              size: 20,
                            ),
                            onPressed: _selectDate,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                            onPressed: _fetchAttendanceReports,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Date Selection Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calendar_month,
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
                                'Selected Date',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _selectDate,
                          icon: Icon(Icons.edit_calendar),
                          label: Text('Change Date'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                  'Loading attendance reports...',
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
                                  onPressed: _fetchAttendanceReports,
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
                            onRefresh: _fetchAttendanceReports,
                            color: Colors.purple.shade600,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Overall Statistics with Tabs
                                  if (reportData?['managerTotalStats'] !=
                                          null ||
                                      reportData?['employeeTotalStats'] !=
                                          null) ...[
                                    Text(
                                      'Overall Statistics',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStatisticsTabs(),
                                    const SizedBox(height: 16),
                                    _buildSelectedStatisticsCard(),
                                    const SizedBox(height: 24),
                                  ],

                                  // Department Reports
                                  if (reportData?['managerReports'] != null ||
                                      reportData?['employeeReports'] !=
                                          null) ...[
                                    Text(
                                      'Department Reports',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildDepartmentTabs(),
                                    const SizedBox(height: 16),
                                    _buildSelectedDepartmentReports(),
                                  ],

                                  // No data message (department level)
                                  if ((reportData?['employeeReports'] == null ||
                                          (reportData!['employeeReports']
                                                  as List)
                                              .isEmpty) &&
                                      (reportData?['managerReports'] == null ||
                                          (reportData!['managerReports']
                                                  as List)
                                              .isEmpty) &&
                                      (reportData?['employeeTotalStats'] ==
                                              null ||
                                          reportData!['employeeTotalStats']['total'] ==
                                              '0') &&
                                      (reportData?['managerTotalStats'] ==
                                              null ||
                                          reportData!['managerTotalStats']['total'] ==
                                              '0')) ...[
                                    Container(
                                      padding: const EdgeInsets.all(40),
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
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Icon(
                                              Icons.business_outlined,
                                              size: 48,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No Department Data Available',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No department reports found for the selected date',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

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

  // Build the two tabs (Manager / Employee)
  Widget _buildStatisticsTabs() {
    final hasManager = reportData?['managerTotalStats'] != null;
    final hasEmployee = reportData?['employeeTotalStats'] != null;

    final tabs = <Map<String, dynamic>>[];
    if (hasManager) {
      tabs.add({'label': 'Manager', 'color': Colors.orange});
    }
    if (hasEmployee) {
      tabs.add({'label': 'Employee', 'color': Colors.blue});
    }

    if (tabs.length <= 1) return const SizedBox.shrink();

    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = _selectedStatsTabIndex == index;
        final Color color = tabs[index]['color'] as Color;
        final String label = tabs[index]['label'] as String;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedStatsTabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              margin: EdgeInsets.only(
                right: index == 0 ? 6 : 0,
                left: index == 1 ? 6 : 0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasManager && index == 0 && hasEmployee
                        ? Icons.manage_accounts
                        : (hasManager && !hasEmployee
                              ? Icons.manage_accounts
                              : Icons.people),
                    color: isSelected ? Colors.white : color,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // Build the two tabs for department reports (Manager / Employee)
  Widget _buildDepartmentTabs() {
    final hasManager =
        reportData?['managerReports'] != null &&
        (reportData!['managerReports'] as List).isNotEmpty;
    final hasEmployee =
        reportData?['employeeReports'] != null &&
        (reportData!['employeeReports'] as List).isNotEmpty;

    final tabs = <Map<String, dynamic>>[];
    if (hasManager) {
      tabs.add({'label': 'Manager', 'color': Colors.orange});
    }
    if (hasEmployee) {
      tabs.add({'label': 'Employee', 'color': Colors.blue});
    }

    if (tabs.length <= 1) return const SizedBox.shrink();

    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = _selectedDepartmentTabIndex == index;
        final Color color = tabs[index]['color'] as Color;
        final String label = tabs[index]['label'] as String;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDepartmentTabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              margin: EdgeInsets.only(
                right: index == 0 ? 6 : 0,
                left: index == 1 ? 6 : 0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasManager && index == 0 && hasEmployee
                        ? Icons.manage_accounts
                        : (hasManager && !hasEmployee
                              ? Icons.manage_accounts
                              : Icons.people),
                    color: isSelected ? Colors.white : color,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // Render selected statistics card based on active tab
  Widget _buildSelectedStatisticsCard() {
    final hasManager = reportData?['managerTotalStats'] != null;
    final hasEmployee = reportData?['employeeTotalStats'] != null;

    if (!hasManager && !hasEmployee) return const SizedBox.shrink();

    // Determine which stats to show based on selected tab and availability
    if (hasManager && hasEmployee) {
      return _buildStatisticsCard(
        title: _selectedStatsTabIndex == 0
            ? 'Manager Statistics'
            : 'Employee Statistics',
        icon: _selectedStatsTabIndex == 0
            ? Icons.manage_accounts
            : Icons.people,
        color: _selectedStatsTabIndex == 0 ? Colors.orange : Colors.blue,
        stats: _selectedStatsTabIndex == 0
            ? (reportData!['managerTotalStats'] as Map<String, dynamic>)
            : (reportData!['employeeTotalStats'] as Map<String, dynamic>),
      );
    } else if (hasManager) {
      return _buildStatisticsCard(
        title: 'Manager Statistics',
        icon: Icons.manage_accounts,
        color: Colors.orange,
        stats: reportData!['managerTotalStats'],
      );
    } else {
      return _buildStatisticsCard(
        title: 'Employee Statistics',
        icon: Icons.people,
        color: Colors.blue,
        stats: reportData!['employeeTotalStats'],
      );
    }
  }

  // Render selected department reports based on active tab
  Widget _buildSelectedDepartmentReports() {
    final hasManager =
        reportData?['managerReports'] != null &&
        (reportData!['managerReports'] as List).isNotEmpty;
    final hasEmployee =
        reportData?['employeeReports'] != null &&
        (reportData!['employeeReports'] as List).isNotEmpty;

    if (!hasManager && !hasEmployee) return const SizedBox.shrink();

    // Determine which reports to show based on selected tab and availability
    if (hasManager && hasEmployee) {
      if (_selectedDepartmentTabIndex == 0) {
        // Show Manager reports
        return Column(
          children: List.generate(
            (reportData!['managerReports'] as List).length,
            (index) {
              final report = reportData!['managerReports'][index];
              return _buildDepartmentReportCard(
                report: report,
                color: Colors.orange,
                icon: Icons.manage_accounts,
              );
            },
          ),
        );
      } else {
        // Show Employee reports
        return Column(
          children: List.generate(
            (reportData!['employeeReports'] as List).length,
            (index) {
              final report = reportData!['employeeReports'][index];
              return _buildDepartmentReportCard(
                report: report,
                color: Colors.blue,
                icon: Icons.people,
              );
            },
          ),
        );
      }
    } else if (hasManager) {
      // Only Manager reports available
      return Column(
        children: List.generate(
          (reportData!['managerReports'] as List).length,
          (index) {
            final report = reportData!['managerReports'][index];
            return _buildDepartmentReportCard(
              report: report,
              color: Colors.orange,
              icon: Icons.manage_accounts,
            );
          },
        ),
      );
    } else {
      // Only Employee reports available
      return Column(
        children: List.generate(
          (reportData!['employeeReports'] as List).length,
          (index) {
            final report = reportData!['employeeReports'][index];
            return _buildDepartmentReportCard(
              report: report,
              color: Colors.blue,
              icon: Icons.people,
            );
          },
        ),
      );
    }
  }

  Widget _buildStatisticsCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, dynamic> stats,
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Present',
                  stats['present'].toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Absent',
                  stats['absent'].toString(),
                  Colors.red,
                  Icons.cancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats['total'].toString(),
                  color,
                  icon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$title Attendance Rate: ${stats['percentage']}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentReportCard({
    required Map<String, dynamic> report,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  report['department'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${report['percentage']}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Present',
                  report['present'].toString(),
                  Colors.green.shade100,
                  Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  'Absent',
                  report['absent'].toString(),
                  Colors.red.shade100,
                  Colors.red.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  'Total',
                  report['total'].toString(),
                  color.withValues(alpha: 0.1),
                  color,
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildMiniStat(
    String label,
    String value,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
