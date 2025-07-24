import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name,
      _email,
      _password,
      _confirmPassword,
      _selectedRole,
      _phone,
      _department;
  final _roles = ['Employee', 'Manager', 'Admin'];
  bool _loading = false;
  String? _error;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    _formKey.currentState!.save();
    if (_password != _confirmPassword) {
      setState(() {
        _error = 'Passwords do not match';
        _loading = false;
      });
      return;
    }
    try {
      final res = await apiService.post('/auth/register', {
        'name': _name,
        'email': _email,
        'password': _password,
        'role': _selectedRole,
        'phone': _phone,
        'department': _department,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['token'] != null) {
        apiService.setToken(data['token']);
        final role = data['user']['role'];
        if (role == 'Employee') {
          Navigator.pushReplacementNamed(context, '/employee');
        } else if (role == 'Manager') {
          Navigator.pushReplacementNamed(context, '/manager');
        } else if (role == 'Admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        }
      } else {
        setState(() {
          _error = data['msg'] ?? 'Registration failed';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your name' : null,
                onSaved: (value) => _name = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter a valid email'
                    : null,
                onSaved: (value) => _email = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value == null || value.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
                onSaved: (value) => _password = value,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
                obscureText: true,
                validator: (value) => value == null || value.length < 6
                    ? 'Confirm your password'
                    : null,
                onSaved: (value) => _confirmPassword = value,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Role'),
                value: _selectedRole,
                items: _roles
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedRole = value),
                validator: (value) => value == null ? 'Select a role' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                onSaved: (value) => _phone = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Department'),
                onSaved: (value) => _department = value,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('Register'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
