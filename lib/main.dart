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
  final _roles = ['Employee', 'Manager', 'Admin'];
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
            Navigator.pushReplacementNamed(context, '/employee');
          } else if (role == 'Manager') {
            Navigator.pushReplacementNamed(context, '/manager');
          } else if (role == 'Admin') {
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
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Role:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            ..._roles.map(
              (role) => RadioListTile<String>(
                title: Text(role),
                value: role,
                groupValue: _selectedRole,
                onChanged: (value) => setState(() => _selectedRole = value),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (_) => setState(() {}),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
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
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text("Don't have an account? Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
