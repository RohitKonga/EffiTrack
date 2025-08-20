import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

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

class _AttendanceScreenState extends State<AttendanceScreen>
    with TickerProviderStateMixin {
  bool checkedIn = false;
  DateTime? checkInTime;
  DateTime? checkOutTime;
  List<Map<String, dynamic>> history = [];
  bool _loading = true;
  String? _error;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  String _workingHours = '00:00:00';
  Timer? _workingHoursTimer;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _updateWorkingHours();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _slideController.forward();

    // Start timer to update working hours every second when checked in
    _workingHoursTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (checkedIn) {
        _updateWorkingHours();
      }
    });
  }

  void _updateWorkingHours() {
    if (checkedIn && checkInTime != null) {
      final now = DateTime.now();
      final difference = now.difference(checkInTime!);

      final hours = difference.inHours.toString().padLeft(2, '0');
      final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');

      setState(() {
        _workingHours = '$hours:$minutes:$seconds';
      });
    } else {
      setState(() {
        _workingHours = '00:00:00';
      });
    }
  }

  String _formatWorkingHours(dynamic workingHours) {
    if (workingHours == null) return '-';

    try {
      final hours = double.parse(workingHours.toString());
      final totalMinutes = (hours * 60).round();

      final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
      final m = (totalMinutes % 60).toString().padLeft(2, '0');

      return '$h:$m';
    } catch (e) {
      return '-';
    }
  }

  bool _hasCheckedInToday() {
    if (history.isEmpty) return false;

    final today = DateTime.now();
    final todayDate =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    return history.any((record) {
      final recordDate = _formatDate(record['checkIn']?.toString());
      return recordDate == todayDate;
    });
  }

  bool _hasCompletedTodaysSession() {
    if (history.isEmpty) return false;

    final today = DateTime.now();
    final todayDate =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    return history.any((record) {
      final recordDate = _formatDate(record['checkIn']?.toString());
      return recordDate == todayDate && record['checkOut'] != null;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _workingHoursTimer?.cancel();
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
            _pulseController.repeat(reverse: true);
            _updateWorkingHours(); // Update working hours when checked in
          } else {
            checkedIn = false;
            checkInTime = null;
            checkOutTime = null;
            _pulseController.stop();
            _pulseController.reset();
            _updateWorkingHours(); // Reset working hours when not checked in
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

    // Store ScaffoldMessenger reference before async operation to avoid BuildContext warning
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final now = DateTime.now(); // Device time
      final deviceTimeString = now
          .toUtc()
          .toIso8601String(); // Send UTC time for consistency

      final res = await apiService.post('/attendance/checkin', {
        "checkIn": deviceTimeString,
        "timezone": now.timeZoneName,
        "deviceTime":
            now.millisecondsSinceEpoch, // Additional timestamp for verification
      });

      if (res.statusCode == 200) {
        await _fetchHistory();
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                'Check-in successful at ${_formatLocalTime(now.toIso8601String())}',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final data = jsonDecode(res.body);
        setState(() {
          _error = data['msg'] ?? 'Check-in failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: ${e.toString()}';
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

    // Store ScaffoldMessenger reference before async operation to avoid BuildContext warning
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final now = DateTime.now(); // Device time
      final deviceTimeString = now
          .toUtc()
          .toIso8601String(); // Send UTC time for consistency

      final res = await apiService.post('/attendance/checkout', {
        "checkOut": deviceTimeString,
        "timezone": now.timeZoneName,
        "deviceTime":
            now.millisecondsSinceEpoch, // Additional timestamp for verification
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _fetchHistory();

        // Show success message with working hours feedback
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check-out successful!',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (data['additionalInfo'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      data['additionalInfo'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        // Show "don't forget to check in tomorrow" message after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Don\'t forget to check in tomorrow! 🌅',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.blue.shade600,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      } else {
        final data = jsonDecode(res.body);
        setState(() {
          _error = data['msg'] ?? 'Check-out failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: ${e.toString()}';
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade50,
              Colors.purple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.indigo,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading attendance...',
                        style: TextStyle(fontSize: 16, color: Colors.indigo),
                      ),
                    ],
                  ),
                )
              : SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.access_time,
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
                                    'Attendance',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Track your work hours',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Error Display
                      if (_error != null) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Status Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: checkedIn
                                ? [Colors.green.shade400, Colors.green.shade600]
                                : [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (checkedIn ? Colors.green : Colors.orange)
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      checkedIn
                                          ? Icons.check_circle
                                          : Icons.schedule,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    checkedIn
                                        ? 'Currently Working'
                                        : 'Not Checked In',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    checkedIn
                                        ? 'Checked in at ${checkInTime != null ? _formatLocalTime(checkInTime!.toIso8601String()) : '-'}'
                                        : 'Ready to start your day',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Daily Status Indicator
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: checkedIn
                                    ? Colors.green.shade100
                                    : _hasCheckedInToday()
                                    ? Colors.blue.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                checkedIn
                                    ? Icons.check_circle
                                    : _hasCompletedTodaysSession()
                                    ? Icons.done_all
                                    : Icons.info_outline,
                                color: checkedIn
                                    ? Colors.green.shade600
                                    : _hasCompletedTodaysSession()
                                    ? Colors.blue.shade600
                                    : Colors.orange.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    checkedIn
                                        ? 'Today\'s Session'
                                        : 'Daily Status',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    checkedIn
                                        ? 'You are currently working today'
                                        : _hasCompletedTodaysSession()
                                        ? 'You have already completed today\'s session'
                                        : 'You have not checked in today',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: checkedIn
                                    ? Colors.green.shade100
                                    : _hasCompletedTodaysSession()
                                    ? Colors.blue.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: checkedIn
                                      ? Colors.green.shade300
                                      : _hasCompletedTodaysSession()
                                      ? Colors.blue.shade300
                                      : Colors.orange.shade300,
                                ),
                              ),
                              child: Text(
                                checkedIn
                                    ? 'ACTIVE'
                                    : _hasCompletedTodaysSession()
                                    ? 'COMPLETED'
                                    : 'PENDING',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: checkedIn
                                      ? Colors.green.shade700
                                      : _hasCompletedTodaysSession()
                                      ? Colors.blue.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                onPressed: (checkedIn || _hasCompletedTodaysSession()) ? null : _checkIn,
                                text: 'Check In',
                                icon: Icons.login,
                                color: Colors.green,
                                isLoading: _loading && !checkedIn,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionButton(
                                onPressed: checkedIn ? _checkOut : null,
                                text: 'Check Out',
                                icon: Icons.logout,
                                color: Colors.red,
                                isLoading: _loading && checkedIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Working Hours Display (when checked in)
                      if (checkedIn) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.access_time,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Working Hours',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _workingHours,
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // History Section
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.history,
                                    color: Colors.indigo.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Attendance History',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: history.isEmpty
                                    ? _buildEmptyState()
                                    : _buildHistoryList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
    required Color color,
    required bool isLoading,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.history, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance records yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your attendance history will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final record = history[index];
        final isToday =
            _formatDate(record['checkIn']?.toString()) ==
            _formatDate(DateTime.now().toIso8601String());

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isToday ? Colors.indigo.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isToday ? Icons.today : Icons.calendar_today,
                color: isToday ? Colors.indigo.shade600 : Colors.grey.shade600,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Text(
                  _formatDate(record['checkIn']?.toString()),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade700,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'TODAY',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTimeChip(
                      'In',
                      _formatLocalTime(record['checkIn']?.toString()),
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildTimeChip(
                      'Out',
                      _formatLocalTime(record['checkOut']?.toString()),
                      Colors.red,
                    ),
                    const Spacer(),
                    _buildTimeChip(
                      'Hours',
                      _formatWorkingHours(record['workingHours']),
                      Colors.blue.shade600,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeChip(String label, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            time,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
