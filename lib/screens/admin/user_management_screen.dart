import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await apiService.get(
        '/profile/all',
      ); // Adjust endpoint as needed
      if (res.statusCode == 200) {
        setState(() {
          users = jsonDecode(res.body);
        });
      } else {
        setState(() {
          _error = 'Failed to load users';
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

  Future<void> _deleteUser(String userId) async {
    try {
      final res = await apiService.post('/profile/delete', {
        'id': userId,
      }); // Adjust endpoint as needed
      if (res.statusCode == 200) {
        _fetchUsers();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete user')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error')));
    }
  }

  Future<void> _addUserDialog() async {
    final _formKey = GlobalKey<FormState>();
    String? name, email, password, role, phone, department;
    final roles = ['Employee', 'Manager', 'Admin'];
    bool loading = false;
    String? error;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add User'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (error != null) ...[
                        Text(error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                      ],
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Name'),
                        onSaved: (v) => name = v,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter name' : null,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        onSaved: (v) => email = v,
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Enter valid email'
                            : null,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        onSaved: (v) => password = v,
                        validator: (v) =>
                            v == null || v.length < 6 ? 'Min 6 chars' : null,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Role'),
                        value: role,
                        items: roles
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => role = v),
                        validator: (v) => v == null ? 'Select role' : null,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Phone'),
                        onSaved: (v) => phone = v,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Department',
                        ),
                        onSaved: (v) => department = v,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          _formKey.currentState!.save();
                          setState(() => loading = true);
                          try {
                            final res = await apiService
                                .post('/auth/register', {
                                  'name': name,
                                  'email': email,
                                  'password': password,
                                  'role': role,
                                  'phone': phone,
                                  'department': department,
                                });
                            final data = jsonDecode(res.body);
                            if (res.statusCode == 200 &&
                                data['token'] != null) {
                              Navigator.pop(context);
                              _fetchUsers();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('User added!')),
                              );
                            } else {
                              setState(
                                () =>
                                    error = data['msg'] ?? 'Failed to add user',
                              );
                            }
                          } catch (e) {
                            setState(() => error = 'Network error');
                          } finally {
                            setState(() => loading = false);
                          }
                        },
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user['name'] ?? ''),
                  subtitle: Text('Role: ${user['role'] ?? ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _deleteUser(user['_id'] ?? user['id'] ?? ''),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUserDialog,
        child: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
