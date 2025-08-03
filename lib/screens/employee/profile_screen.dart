import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _phone = '';
  String _department = '';
  final _departments = ['Design', 'Development', 'Marketing', 'Sales', 'HR'];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
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
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      onSaved: (value) => _name = value ?? '',
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter name' : null,
                    ),
                    TextFormField(
                      initialValue: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                      onSaved: (value) => _email = value ?? '',
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Enter valid email'
                          : null,
                    ),
                    TextFormField(
                      initialValue: _phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                      onSaved: (value) => _phone = value ?? '',
                      validator: (value) => value == null || value.length < 8
                          ? 'Enter valid phone'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: _department.isNotEmpty ? _department : null,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                      ),
                      items: _departments
                          .map(
                            (dept) => DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _department = value ?? ''),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please select a department'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    _saving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _saveProfile,
                            child: const Text('Save'),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
