import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      barrierDismissible: false,
      builder: (context) => _buildLogoutDialog(context),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    apiService._token = null;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  static Widget _buildLogoutDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.purple.shade50,
              Colors.indigo.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade200, width: 2),
              ),
              child: Icon(
                Icons.logout_rounded,
                size: 48,
                color: Colors.red.shade600,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Confirm Logout',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Message
            Text(
              'Are you sure you want to logout from your account?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                ),

                const SizedBox(width: 16),

                // Logout Button
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade500, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade300.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final apiService = ApiService();
