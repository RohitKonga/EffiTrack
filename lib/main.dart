import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'screens/auth/register_screen.dart';
import 'dart:convert';
import 'screens/employee/employee_dashboard.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

void main() {
  runApp(const EffiTrackApp());
}

class EffiTrackApp extends StatefulWidget {
  const EffiTrackApp({super.key});

  @override
  State<EffiTrackApp> createState() => _EffiTrackAppState();
}

class _EffiTrackAppState extends State<EffiTrackApp> {
  Widget? _home;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    await apiService.loadToken();
    if (apiService.token != null) {
      try {
        final res = await apiService.get('/profile');
        if (res.statusCode == 200) {
          final user = jsonDecode(res.body);
          if (user['role'] == 'Employee') {
            setState(() {
              _home = const EmployeeDashboard();
            });
          } else if (user['role'] == 'Manager') {
            setState(() {
              _home = const ManagerDashboard();
            });
          } else if (user['role'] == 'Admin') {
            setState(() {
              _home = const AdminDashboard();
            });
          } else {
            setState(() {
              _home = const LoginScreen();
            });
          }
        } else {
          setState(() {
            _home = const LoginScreen();
          });
        }
      } catch (e) {
        setState(() {
          _home = const LoginScreen();
        });
      }
    } else {
      setState(() {
        _home = const LoginScreen();
      });
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EffiTrack – TimeManager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.indigo.shade50,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => _loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : (_home ?? const LoginScreen()),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/employee': (context) => const EmployeeDashboard(),
        '/manager': (context) => const ManagerDashboard(),
        '/admin': (context) => const AdminDashboard(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/login');
    });
    return const Scaffold(
      body: Center(
        child: Text(
          'EFFITRACK',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _selectedRole;
  final _roles = ['Admin', 'Manager', 'Employee'];
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final res = await apiService.post('/auth/login', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['token'] != null) {
        apiService.setToken(data['token']);
        final role = data['user']['role'];
        if (role == _selectedRole) {
          setState(() => _errorMessage = null);
          if (role == 'Employee') {
            // ignore: use_build_context_synchronously
            Navigator.pushReplacementNamed(context, '/employee');
          } else if (role == 'Manager') {
            // ignore: use_build_context_synchronously
            Navigator.pushReplacementNamed(context, '/manager');
          } else if (role == 'Admin') {
            // ignore: use_build_context_synchronously
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            setState(() => _errorMessage = 'Unknown user role.');
          }
        } else {
          setState(
            () => _errorMessage =
                'Selected role does not match your account role.',
          );
        }
      } else {
        setState(() => _errorMessage = data['msg'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Logo/Title
                Icon(
                  Icons.track_changes,
                  size: 60,
                  color: Colors.indigo.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'EffiTrack',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Time Management System',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.indigo.shade500,
                  ),
                ),
                const SizedBox(height: 32),

                // Error Display
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Form Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Role:',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._roles.map(
                          (role) => RadioListTile<String>(
                            title: Text(role, style: GoogleFonts.poppins()),
                            value: role,
                            groupValue: _selectedRole,
                            onChanged: (value) =>
                                setState(() => _selectedRole = value),
                            activeColor: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _selectedRole == null ||
                            _emailController.text.isEmpty ||
                            _passwordController.text.isEmpty ||
                            _loading
                        ? null
                        : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        'Register',
                        style: GoogleFonts.poppins(
                          color: Colors.indigo.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
