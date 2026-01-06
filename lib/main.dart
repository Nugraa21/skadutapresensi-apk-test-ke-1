import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'services/fake_gps_service.dart';

import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/user_management_page.dart';
import 'pages/presensi_page.dart';
import 'pages/history_page.dart';
import 'pages/admin_presensi_page.dart';
import 'pages/admin_user_list_page.dart';
import 'pages/rekap_page.dart';

import 'models/user_model.dart';
import 'api/api_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 BYPASS SSL SELF-SIGNED
  HttpOverrides.global = MyHttpOverrides();

  runApp(const SkadutaApp());
}

class SkadutaApp extends StatefulWidget {
  const SkadutaApp({super.key});

  @override
  State<SkadutaApp> createState() => _SkadutaAppState();
}

class _SkadutaAppState extends State<SkadutaApp> with WidgetsBindingObserver {
  Widget _initialPage = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FakeGpsService.stop();
    super.dispose();
  }

  /// ===============================
  /// APP LIFECYCLE (INI KUNCI 🔥)
  /// ===============================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      bool fake = await _checkFakeGps();
      if (fake) {
        _forceBlockFakeGps();
      }
    }
  }

  /// ===============================
  /// INIT APP
  /// ===============================
  Future<void> _initApp() async {
    bool fake = await _checkFakeGps();

    if (fake) {
      _showFakeGpsBlock();
    } else {
      FakeGpsService.start(onFakeDetected: _forceBlockFakeGps);
      _checkLoginStatus();
    }
  }

  /// ===============================
  /// CEK FAKE GPS
  /// ===============================
  Future<bool> _checkFakeGps() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return position.isMocked;
  }

  /// ===============================
  /// FORCE BLOCK (GLOBAL)
  /// ===============================
  void _forceBlockFakeGps() {
    if (_blocked || !mounted) return;

    _blocked = true;
    FakeGpsService.stop();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _fakeGpsBlockedPage()),
      (route) => false,
    );
  }

  /// ===============================
  /// CEK LOGIN
  /// ===============================
  Future<void> _checkLoginStatus() async {
    final userInfo = await ApiService.getCurrentUser();

    if (userInfo != null) {
      final user = UserModel(
        id: userInfo['id']!,
        username: '',
        namaLengkap: userInfo['nama_lengkap']!,
        nipNisn: '',
        role: userInfo['role']!,
      );

      if (mounted) {
        setState(() {
          _initialPage = DashboardPage(user: user);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _initialPage = const LoginPage();
        });
      }
    }
  }

  /// ===============================
  /// HALAMAN BLOKIR FAKE GPS
  /// ===============================
  Widget _fakeGpsBlockedPage() {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gps_off, color: Colors.red, size: 90),
                const SizedBox(height: 16),
                const Text(
                  "FAKE GPS TERDETEKSI",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Matikan Fake GPS terlebih dahulu untuk menggunakan aplikasi presensi.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    _blocked = false;
                    setState(() {
                      _initialPage = const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    });
                    await Future.delayed(const Duration(seconds: 1));
                    _initApp();
                  },
                  child: const Text("CEK ULANG"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFakeGpsBlock() {
    setState(() {
      _initialPage = _fakeGpsBlockedPage();
    });
  }

  /// ===============================
  /// BUILD
  /// ===============================
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skaduta Presensi',
      debugShowCheckedModeBanner: false,
      home: _initialPage,
      routes: {
        '/login': (_) => const LoginPage(),
        '/admin-presensi': (_) => const AdminPresensiPage(),
        '/rekap': (_) => const RekapPage(),
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
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) =>
                PresensiPage(user: args['user'], initialJenis: args['jenis']),
          );
        }
        if (settings.name == '/history') {
          final user = settings.arguments as UserModel;
          return MaterialPageRoute(builder: (_) => HistoryPage(user: user));
        }
        if (settings.name == '/admin-user-list') {
          return MaterialPageRoute(builder: (_) => const AdminUserListPage());
        }
        return null;
      },
    );
  }
}
