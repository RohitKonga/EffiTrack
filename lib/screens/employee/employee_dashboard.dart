import 'package:flutter/material.dart';
import 'attendance_screen.dart';
import 'task_screen.dart';
import 'leave_screen.dart';
import 'profile_screen.dart';
import 'announcements_screen.dart';
import '../../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
              child: Column(
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Top Bar with Logout
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
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.logout,
                                  color: Colors.red.shade600,
                                  size: 20,
                                ),
                                tooltip: 'Logout',
                                onPressed: () => ApiService.logout(context),
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
                              colors: [
                                Colors.indigo.shade400,
                                Colors.indigo.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
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
                                  Icons.work,
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
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu Grid
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GridView.count(
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
                                builder: (context) => const AnnouncementsScreen(),
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
                              // TODO: Add support screen
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
                  ),
                ],
              ),
            ),
          ),
        ),
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
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
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
