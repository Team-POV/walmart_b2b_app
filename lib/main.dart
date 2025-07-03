import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_signup_screen.dart';
import 'screens/supplier_login_screen.dart';
import 'screens/supplier_signup_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/supplier_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supply Chain Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0071CE), // Walmart blue
          primary: const Color(0xFF0071CE),
          secondary: const Color(0xFF004C91),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0071CE),
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-signup': (context) => const AdminSignupScreen(),
        '/supplier-login': (context) => const SupplierLoginScreen(),
        '/supplier-signup': (context) => const SupplierSignupScreen(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/supplier-dashboard': (context) => const SupplierDashboard(),
      },
    );
  }
}