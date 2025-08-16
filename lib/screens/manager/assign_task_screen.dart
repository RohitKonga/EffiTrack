import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _employee, _title, _desc, _deadline;
  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();

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

  Future<void> _fetchEmployees() async {
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
          // Fetch employees from the same department
          try {
            final employeeRes = await apiService.get(
              '/profile/department/$department',
            );
            if (employeeRes.statusCode == 200) {
              final employees = jsonDecode(employeeRes.body);
              final List<Map<String, dynamic>> employeeList = [];

              for (var emp in employees) {
                if (emp['role'] == 'Employee') {
                  employeeList.add({
                    'id': emp['_id'],
                    'name': emp['name'],
                    'email': emp['email'],
                  });
                }
              }

              if (employeeList.isNotEmpty) {
                setState(() {
                  _employees = employeeList;
                  _loading = false;
                });
              } else {
                // Fallback: add some sample employees if none found
                setState(() {
                  _employees = [
                    {
                      'id': '1',
                      'name': 'Sample Employee 1',
                      'email': 'emp1@example.com',
                    },
                    {
                      'id': '2',
                      'name': 'Sample Employee 2',
                      'email': 'emp2@example.com',
                    },
                  ];
                  _loading = false;
                  _error =
                      'No employees found in department. Using sample data.';
                });
              }
            } else {
              // Fallback: add sample employees if API fails
              setState(() {
                _employees = [
                  {
                    'id': '1',
                    'name': 'Sample Employee 1',
                    'email': 'emp1@example.com',
                  },
                  {
                    'id': '2',
                    'name': 'Sample Employee 2',
                    'email': 'emp2@example.com',
                  },
                ];
                _loading = false;
                _error = 'Failed to load employees. Using sample data.';
              });
            }
          } catch (e) {
            // Fallback: add sample employees on error
            setState(() {
              _employees = [
                {
                  'id': '1',
                  'name': 'Sample Employee 1',
                  'email': 'emp1@example.com',
                },
                {
                  'id': '2',
                  'name': 'Sample Employee 2',
                  'email': 'emp2@example.com',
                },
              ];
              _loading = false;
              _error = 'Network error. Using sample data.';
            });
          }
        } else {
          // Fallback: add sample employees if department is null
          setState(() {
            _employees = [
              {
                'id': '1',
                'name': 'Sample Employee 1',
                'email': 'emp1@example.com',
              },
              {
                'id': '2',
                'name': 'Sample Employee 2',
                'email': 'emp2@example.com',
              },
            ];
            _loading = false;
            _error = 'Department not found. Using sample data.';
          });
        }
      } else {
        // Fallback: add sample employees if profile fetch fails
        setState(() {
          _employees = [
            {
              'id': '1',
              'name': 'Sample Employee 1',
              'email': 'emp1@example.com',
            },
            {
              'id': '2',
              'name': 'Sample Employee 2',
              'email': 'emp2@example.com',
            },
          ];
          _loading = false;
          _error = 'Failed to load profile. Using sample data.';
        });
      }
    } catch (e) {
      // Fallback: add sample employees on any error
      setState(() {
        _employees = [
          {'id': '1', 'name': 'Sample Employee 1', 'email': 'emp1@example.com'},
          {'id': '2', 'name': 'Sample Employee 2', 'email': 'emp2@example.com'},
        ];
        _loading = false;
        _error = 'Network error. Using sample data.';
      });
    }
  }

  Future<void> _assignTask() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _submitting = true;
      });

      try {
        final selectedEmployee = _employees.firstWhere(
          (e) => e['name'] == _employee,
        );

        final res = await apiService.post('/tasks', {
          'title': _title,
          'description': _desc,
          'assignedTo': selectedEmployee['id'],
          'dueDate': _deadline,
          'priority': 'Medium',
          'status': 'To Do',
        });

        if (res.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Task "$_title" assigned to $_employee successfully!${(_desc != null && _desc!.trim().isNotEmpty) ? ' (Desc: ${_desc!.trim()})' : ''}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          setState(() {
            _employee = null;
            _title = null;
            _desc = null;
            _deadline = null;
            _submitting = false;
            _error = null; // Clear any previous errors
          });
          _formKey.currentState!.reset();
        } else {
          setState(() {
            _submitting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to assign task',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _submitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Network error while assigning task',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null) {
      setState(() {
        _deadline =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
                            Icons.assignment_add,
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
                                'Assign Task',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                              Text(
                                'Delegate tasks to your team members',
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

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Error Display
                            if (_error != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.red.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Employee Selection
                            _buildFormSection(
                              'Select Employee',
                              Icons.person,
                              _loading
                                  ? Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.purple.shade600,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Loading employees...',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : _buildEmployeeDropdown(),
                            ),

                            const SizedBox(height: 24),

                            // Task Title
                            _buildFormSection(
                              'Task Title',
                              Icons.title,
                              _buildTitleField(),
                            ),

                            const SizedBox(height: 24),

                            // Task Description
                            _buildFormSection(
                              'Task Description',
                              Icons.description,
                              _buildDescriptionField(),
                            ),

                            const SizedBox(height: 24),

                            // Deadline
                            _buildFormSection(
                              'Deadline',
                              Icons.calendar_today,
                              _buildDeadlineField(),
                            ),

                            const SizedBox(height: 32),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _submitting ? null : _assignTask,
                                icon: _submitting
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Icon(Icons.send, size: 24),
                                label: Text(
                                  _submitting ? 'Assigning...' : 'Assign Task',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.purple.shade300,
                                ),
                              ),
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

  Widget _buildFormSection(String title, IconData icon, Widget child) {
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
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.purple.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmployeeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _employee,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Choose an employee',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: _employees
          .map(
            (e) => DropdownMenuItem<String>(
              value: e['name'] as String,
              child: Text(
                e['name'] as String,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
              ),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _employee = value),
      validator: (value) => value == null ? 'Please select an employee' : null,
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.purple.shade600),
      dropdownColor: Colors.white,
      menuMaxHeight: 320,
      style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      onSaved: (value) => _title = value,
      validator: (value) =>
          value == null || value.isEmpty ? 'Please enter a task title' : null,
      decoration: InputDecoration(
        hintText: 'Enter task title',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 16),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      onSaved: (value) => _desc = value,
      validator: (value) => value == null || value.isEmpty
          ? 'Please enter a task description'
          : null,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Describe the task in detail',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 16),
    );
  }

  Widget _buildDeadlineField() {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: _deadline),
      onTap: _selectDate,
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select a deadline' : null,
      decoration: InputDecoration(
        hintText: 'Select deadline',
        suffixIcon: Icon(Icons.calendar_today, color: Colors.purple.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 16),
    );
  }
}
