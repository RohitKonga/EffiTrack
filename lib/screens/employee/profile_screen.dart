import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _phone = '';
  String _department = '';
  final _departments = ['Design', 'Development', 'Marketing', 'Sales', 'HR'];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  
  // Password change fields
  final _passwordFormKey = GlobalKey<FormState>();
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _changingPassword = false;
  bool _showPasswordSection = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchProfile();

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

  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await apiService.get('/profile');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _name = data['name'] ?? '';
          _email = data['email'] ?? '';
          _phone = data['phone'] ?? '';
          _department = data['department'] ?? '';
        });
      } else {
        setState(() {
          _error = 'Failed to load profile';
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

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    _passwordFormKey.currentState!.save();
    
    setState(() {
      _changingPassword = true;
      _error = null;
    });
    
    try {
      final res = await apiService.put('/profile/password', {
        'currentPassword': _currentPassword,
        'newPassword': _newPassword,
      });
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['msg'] ?? 'Password changed successfully',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() {
          _showPasswordSection = false;
          _currentPassword = '';
          _newPassword = '';
          _confirmPassword = '';
          _passwordFormKey.currentState?.reset();
        });
      } else {
        final data = jsonDecode(res.body);
        setState(() {
          _error = data['msg'] ?? 'Failed to change password';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _changingPassword = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    _formKey.currentState!.save();
    try {
      final res = await apiService.put('/profile', {
        'name': _name,
        'phone': _phone,
        'department': _department,
      });
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Profile updated successfully!',
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
      } else {
        setState(() {
          _error = 'Failed to update profile';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error';
      });
    } finally {
      setState(() {
        _saving = false;
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
                            Icons.person,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Profile',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                'Manage your personal information',
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

                  // Content
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading profile...',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Error Message
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
                                            Icons.error,
                                            color: Colors.red.shade600,
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
                                    const SizedBox(height: 24),
                                  ],

                                  // Profile Picture Section
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
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
                                            color: Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _name.isNotEmpty
                                              ? _name
                                              : 'Your Name',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _department.isNotEmpty
                                              ? _department
                                              : 'Department',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Form Fields
                                  _buildFormSection(
                                    'Personal Information',
                                    Icons.info,
                                    [
                                      _buildFormField(
                                        'Full Name',
                                        Icons.person_outline,
                                        _name,
                                        (value) => _name = value ?? '',
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                            ? 'Please enter your name'
                                            : null,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildFormField(
                                        'Email Address',
                                        Icons.email_outlined,
                                        _email,
                                        (value) => _email = value ?? '',
                                        enabled: false,
                                        validator: (value) =>
                                            value == null ||
                                                !value.contains('@')
                                            ? 'Please enter a valid email'
                                            : null,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildFormField(
                                        'Phone Number',
                                        Icons.phone_outlined,
                                        _phone,
                                        (value) => _phone = value ?? '',
                                        keyboardType: TextInputType.phone,
                                        validator: (value) =>
                                            value == null || value.length < 8
                                            ? 'Please enter a valid phone number'
                                            : null,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildDropdownField(
                                        'Department',
                                        Icons.business_outlined,
                                        _department,
                                        _departments,
                                        onChanged: null, // disabled
                                        enabled: false,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 32),

                                  // Password Change Section
                                  _buildFormSection(
                                    'Change Password',
                                    Icons.lock_outline,
                                    [
                                      if (!_showPasswordSection) ...[
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _showPasswordSection = true;
                                                _currentPassword = '';
                                                _newPassword = '';
                                                _confirmPassword = '';
                                              });
                                            },
                                            icon: Icon(Icons.edit, color: Colors.blue.shade600),
                                            label: Text(
                                              'Change Password',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade600,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: Colors.blue.shade300),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        Form(
                                          key: _passwordFormKey,
                                          child: Column(
                                            children: [
                                              _buildPasswordField(
                                                'Current Password',
                                                Icons.lock_outline,
                                                _currentPassword,
                                                (value) => _currentPassword = value ?? '',
                                                _obscureCurrentPassword,
                                                () {
                                                  setState(() {
                                                    _obscureCurrentPassword = !_obscureCurrentPassword;
                                                  });
                                                },
                                                validator: (value) =>
                                                    value == null || value.isEmpty
                                                        ? 'Please enter your current password'
                                                        : null,
                                              ),
                                              const SizedBox(height: 20),
                                              _buildPasswordField(
                                                'New Password',
                                                Icons.lock,
                                                _newPassword,
                                                (value) => _newPassword = value ?? '',
                                                _obscureNewPassword,
                                                () {
                                                  setState(() {
                                                    _obscureNewPassword = !_obscureNewPassword;
                                                  });
                                                },
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return 'Please enter a new password';
                                                  }
                                                  if (value.length < 6) {
                                                    return 'Password must be at least 6 characters';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 20),
                                              _buildPasswordField(
                                                'Confirm New Password',
                                                Icons.lock,
                                                _confirmPassword,
                                                (value) => _confirmPassword = value ?? '',
                                                _obscureConfirmPassword,
                                                () {
                                                  setState(() {
                                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                                  });
                                                },
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return 'Please confirm your new password';
                                                  }
                                                  if (value != _newPassword) {
                                                    return 'Passwords do not match';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: _changingPassword
                                                          ? null
                                                          : () {
                                                              setState(() {
                                                                _showPasswordSection = false;
                                                                _currentPassword = '';
                                                                _newPassword = '';
                                                                _confirmPassword = '';
                                                                _passwordFormKey.currentState?.reset();
                                                              });
                                                            },
                                                      style: OutlinedButton.styleFrom(
                                                        side: BorderSide(color: Colors.grey.shade300),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                                      ),
                                                      child: Text(
                                                        'Cancel',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.grey.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: _changingPassword ? null : _changePassword,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.blue.shade600,
                                                        foregroundColor: Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                                      ),
                                                      child: _changingPassword
                                                          ? SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                              ),
                                                            )
                                                          : Text(
                                                              'Change Password',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  const SizedBox(height: 32),

                                  // Save Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: _saving ? null : _saveProfile,
                                      icon: _saving
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : Icon(Icons.save, size: 24),
                                      label: Text(
                                        _saving ? 'Saving...' : 'Save Profile',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 4,
                                        shadowColor: Colors.blue.shade300,
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

  Widget _buildFormSection(String title, IconData icon, List<Widget> children) {
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
                child: Icon(icon, color: Colors.blue.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFormField(
    String label,
    IconData icon,
    String initialValue,
    Function(String?) onSaved, {
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          onSaved: onSaved,
          validator: validator,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blue.shade600),
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
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    IconData icon,
    String value,
    List<String> items, {
    ValueChanged<String?>? onChanged,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value.isNotEmpty ? value : null,
          isExpanded: true,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator: enabled ? validator : null,
          menuMaxHeight: 320,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blue.shade600),
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
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: enabled ? Colors.blue.shade600 : Colors.grey,
          ),
          dropdownColor: Colors.white,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    IconData icon,
    String value,
    Function(String?) onSaved,
    bool obscureText,
    VoidCallback onToggleVisibility, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          obscureText: obscureText,
          onSaved: onSaved,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blue.shade600),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed: onToggleVisibility,
            ),
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
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
