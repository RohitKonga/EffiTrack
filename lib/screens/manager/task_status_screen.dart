import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class TaskStatusScreen extends StatefulWidget {
  const TaskStatusScreen({super.key});

  @override
  State<TaskStatusScreen> createState() => _TaskStatusScreenState();
}

class _TaskStatusScreenState extends State<TaskStatusScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> tasks = [];
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = {
    'total': 0,
    'completed': 0,
    'inProgress': 0,
    'toDo': 0,
  };

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchTasks();

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

  Future<void> _fetchTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Fetch manager's profile to get department
      final profileRes = await apiService.get('/profile');
      if (profileRes.statusCode == 200) {
        final profile = jsonDecode(profileRes.body);
        final department = profile['department'];

        if (department != null) {
          // Fetch tasks from the same department
          final taskRes = await apiService.get('/tasks/department/$department');
          if (taskRes.statusCode == 200) {
            final List<dynamic> data = jsonDecode(taskRes.body);
            final List<Map<String, dynamic>> taskList = data
                .map((item) => item as Map<String, dynamic>)
                .toList();

            // Calculate summary
            int completed = 0;
            int inProgress = 0;
            int toDo = 0;

            for (var task in taskList) {
              final status = _getTaskStatus(task['status']);
              switch (status) {
                case 'Completed':
                  completed++;
                  break;
                case 'In Progress':
                  inProgress++;
                  break;
                case 'To Do':
                  toDo++;
                  break;
              }
            }

            setState(() {
              tasks = taskList;
              _summary = {
                'total': taskList.length,
                'completed': completed,
                'inProgress': inProgress,
                'toDo': toDo,
              };
              _loading = false;
            });
          } else {
            setState(() {
              _error = 'Failed to load tasks';
              _loading = false;
            });
          }
        } else {
          setState(() {
            _error = 'Department not found';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load profile';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error';
        _loading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'to do':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in progress':
        return Icons.pending;
      case 'to do':
        return Icons.schedule;
      case 'overdue':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String _getAssignedToName(dynamic assignedTo) {
    if (assignedTo == null) return 'Unknown';
    if (assignedTo is String) return assignedTo;
    if (assignedTo is Map<String, dynamic>) {
      return assignedTo['name'] ?? assignedTo['fullName'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  String _getTaskTitle(dynamic title) {
    if (title == null) return 'Unknown Task';
    if (title is String) return title;
    if (title is Map<String, dynamic>) {
      return title['title'] ?? title['name'] ?? 'Unknown Task';
    }
    return 'Unknown Task';
  }

  String _getTaskPriority(dynamic priority) {
    if (priority == null) return 'Medium';
    if (priority is String) return priority;
    if (priority is Map<String, dynamic>) {
      return priority['priority'] ?? priority['name'] ?? 'Medium';
    }
    return 'Medium';
  }

  String _getTaskStatus(dynamic status) {
    if (status == null) return 'To Do';
    if (status is String) return status;
    if (status is Map<String, dynamic>) {
      return status['status'] ?? status['name'] ?? 'To Do';
    }
    return 'To Do';
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _summary['completed'] ?? 0;
    final inProgressCount = _summary['inProgress'] ?? 0;
    final toDoCount = _summary['toDo'] ?? 0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade50,
              Colors.blue.shade50,
              Colors.indigo.shade50,
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
                            Icons.task_alt,
                            color: Colors.teal.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Task Status',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                              Text(
                                'View team task status',
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

                  // Statistics Cards
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Completed',
                            completedCount.toString(),
                            Colors.green,
                            Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'In Progress',
                            inProgressCount.toString(),
                            Colors.orange,
                            Icons.pending,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'To Do',
                            toDoCount.toString(),
                            Colors.blue,
                            Icons.schedule,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tasks List
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team Tasks',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_loading) ...[
                            Expanded(
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.teal.shade600,
                                ),
                              ),
                            ),
                          ] else if (_error != null) ...[
                            Expanded(
                              child: Center(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ] else if (tasks.isEmpty) ...[
                            Expanded(
                              child: Center(
                                child: Container(
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
                                    mainAxisSize: MainAxisSize.min,
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
                                          Icons.task_outlined,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Tasks Found',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No tasks have been assigned yet',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _fetchTasks,
                                color: Colors.teal.shade600,
                                child: ListView.builder(
                                  itemCount: tasks.length,
                                  itemBuilder: (context, index) {
                                    final task = tasks[index];
                                    return _buildTaskCard(task);
                                  },
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final status = _getTaskStatus(task['status']);
    final priority = _getTaskPriority(task['priority']);
    final statusColor = _getStatusColor(status);
    final priorityColor = _getPriorityColor(priority);

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
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTaskTitle(task['title']),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getAssignedToName(task['assignedTo']),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _getTaskPriority(task['priority']),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Details Row
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Due Date',
                  _formatDate(task['deadline']),
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Status',
                  status,
                  Icons.info,
                  statusColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status Badge (Read-only)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(_getStatusIcon(status), color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Status: $status',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No due date';
    try {
      if (date is String) {
        final parsed = DateTime.parse(date);
        return '${parsed.day}/${parsed.month}/${parsed.year}';
      }
      return 'Invalid date';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
