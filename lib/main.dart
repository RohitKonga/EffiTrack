import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'dart:convert';
import 'screens/employee/employee_dashboard.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
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
          await NotificationService().syncDeviceTokenIfNeeded();
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
