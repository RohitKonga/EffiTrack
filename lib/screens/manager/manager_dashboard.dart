import 'package:flutter/material.dart';
import 'team_attendance_screen.dart';
import 'assign_task_screen.dart';
import 'task_status_screen.dart';
import 'leave_approval_screen.dart';
import 'announcements_management_screen.dart';
import '../../services/api_service.dart';
import '../employee/attendance_screen.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
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
                  builder: (context) => const AttendanceScreen(),
                ),
              );
            },
            child: const Text('My Attendance'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeamAttendanceScreen(),
                ),
              );
            },
            child: const Text('Team Attendance'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AssignTaskScreen(),
                ),
              );
            },
            child: const Text('Assign Task'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TaskStatusScreen(),
                ),
              );
            },
            child: const Text('Task Status'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaveApprovalScreen(),
                ),
              );
            },
            child: const Text('Leave Approval'),
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
        ],
      ),
    );
  }
}
