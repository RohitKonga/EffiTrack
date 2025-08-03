import 'package:flutter/material.dart';
import 'user_management_screen.dart';
import 'attendance_reports_screen.dart';
import 'task_reports_screen.dart';
import 'leave_policies_screen.dart';
import 'announcements_management_screen.dart';
import 'analytics_dashboard_screen.dart';
import '../../services/api_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ApiService.logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserManagementScreen(),
                ),
              );
            },
            child: const Text('User Management'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceReportsScreen(),
                ),
              );
            },
            child: const Text('Attendance Reports'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TaskReportsScreen(),
                ),
              );
            },
            child: const Text('Task Reports'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeavePoliciesScreen(),
                ),
              );
            },
            child: const Text('Leave Policies'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnnouncementsManagementScreen(),
                ),
              );
            },
            child: const Text('Announcements Management'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsDashboardScreen(),
                ),
              );
            },
            child: const Text('Analytics Dashboard'),
          ),
        ],
      ),
    );
  }
}
