import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/user_management_page.dart';
import 'models/user_model.dart';

// PAGE BARU PRESENSI
import 'pages/presensi_page.dart';
import 'pages/history_page.dart';
import 'pages/admin_presensi_page.dart';

void main() {
  runApp(const SkadutaApp());
}

class SkadutaApp extends StatelessWidget {
  const SkadutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorSchemeSeed: Colors.orange,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );

    return MaterialApp(
      title: 'Skaduta Presensi',
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        // admin presensi tidak butuh argumen
        '/admin-presensi': (context) => const AdminPresensiPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          final user = settings.arguments as UserModel;
          return MaterialPageRoute(builder: (_) => DashboardPage(user: user));
        }
        if (settings.name == '/user-management') {
          return MaterialPageRoute(builder: (_) => const UserManagementPage());
        }
        if (settings.name == '/presensi') {
          final user = settings.arguments as UserModel;
          return MaterialPageRoute(builder: (_) => PresensiPage(user: user));
        }
        if (settings.name == '/history') {
          final user = settings.arguments as UserModel;
          return MaterialPageRoute(builder: (_) => HistoryPage(user: user));
        }
        return null;
      },
    );
  }
}
