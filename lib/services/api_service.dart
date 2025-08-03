import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ApiService {
  static const String baseUrl = 'https://effitrack.onrender.com/api';
  String? _token;

  void setToken(String? token) {
    _token = token;
    if (token != null) saveToken(token);
  }

  String? get token => _token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'x-auth-token': _token!,
  };

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool auth = false,
  }) {
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );
  }

  Future<http.Response> get(String endpoint, {bool auth = false}) {
    return http.get(Uri.parse('$baseUrl$endpoint'), headers: _headers);
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool auth = false,
  }) {
    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );
  }

  Future<http.Response> delete(String endpoint, {bool auth = false}) {
    return http.delete(Uri.parse('$baseUrl$endpoint'), headers: _headers);
  }

  Future<http.Response> getWithoutAuth(String endpoint) {
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) _token = token;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    _token = null;
  }

  static Future<void> logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    apiService._token = null;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}

final apiService = ApiService();
