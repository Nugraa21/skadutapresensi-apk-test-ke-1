```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="com.example.skadutapresensi">

    <!-- PERMISSIONS (Perizinan pada aplikasi) -->

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="28" />
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"
        tools:ignore="ScopedStorage" />


    <!-- <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/> -->


    <!-- INTERNET -->
    <!-- <uses-permission android:name="android.permission.INTERNET"/> -->

    <!-- GPS -->
    <!-- <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/> -->
    <!-- <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/> -->

    <!-- NOTIFICATION (ANDROID 13+) -->
    <!-- <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/> -->

    <!-- FOREGROUND SERVICE (NOTIF STABIL) -->
    <!-- <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/> -->


    <!-- PERMISSIONS (Perizinan pada aplikasi) -->

    <application
        android:label="skadutapresensi"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">  

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />

    </application>

</manifest>

```
```yaml
name: skadutapresensi
description: "A new Flutter project."
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

version: 1.0.0+1

environment:
  sdk: ^3.8.1

dependencies:
  flutter:
    sdk: flutter

  # ================ menambahkan dependency ================

  camera: ^0.11.0+2              # untuk akses kamera
  geolocator: ^13.0.1            # untuk GPS
  permission_handler: ^11.3.1    # untuk izin
  flutter_map: ^7.0.2            # map
  latlong2: ^0.9.1               # untuk LatLng
  cupertino_icons: ^1.0.8        # icon iOS  
  http: ^1.6.0                   # untuk http request
  image_picker: ^1.1.2           # untuk pilih gambar dari galeri
  confetti: ^0.7.0               # untuk efek confetti
  url_launcher: ^6.3.0           # untuk buka url
  google_maps_flutter: ^2.7.0    # untuk google maps
  excel: ^4.0.3                  # untuk buat file excel
  path_provider: ^2.1.1          # untuk simpan file di device
  open_file: ^3.3.2              # biar langsung buka file setelah download
  encrypt: ^5.0.3                # For AES-256-CBC encryption/decryption (key: 'nugra21')
  cryptography: ^2.7.0           # For AES-256-CBC encryption/decryption (key: 'nugra21')
  shared_preferences: ^2.2.2     # For storing user data/device ID locally
  crypto: ^3.0.3                 # For hashing  
  device_info_plus: ^10.1.0      # For generating unique device ID (used in login/register)
  # ========================================================  


  # Sementara di-comment dulu ya dependency lama-nya biar gak bingung 

  # ================ dependency lama =======================
  # flutter_local_notifications: ^17.0.0
  # intl: ^0.18.1
  # shared_preferences: ^2.3.2   # For storing user data/device ID locally
  # device_info_plus: ^10.1.2    # For generating unique device ID (used in login/register)
  # uuid: ^4.0.0                 # For generating unique IDs
  # encrypt: ^5.0.1                # For AES-256-CBC encryption/decryption (key: 'nugra21')
  # http: ^1.2.1  # For API calls
  # geolocator: ^11.1.0  # For location (latitude/longitude) - assuming already used in presensi
  # image_picker: ^1.0.7  # For selfie and dokumen upload (base64)
  # path_provider: ^2.1.3  # For file paths (if needed for local storage)
  # Add any existing ones like intl, etc., if not already present
  # permission_handler: ^11.0.0
  # geolocator: ^13.0.1
  # flutter_map: ^7.0.2
  # latlong2: ^0.9.1
  # geolocator: ^12.0.0
  # device_info_plus: ^10.0.0    # For generating unique device ID (used in login/register)
  # image_picker: ^1.0.7
  # encrypt: ^5.0.1
  # ========================================================

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.13.1


flutter:
  uses-material-design: true
  assets:
    - assets/icon/app_icon.png

flutter_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
#  flutter pub run flutter_launcher_icons  // kadang lupa njer 
# dart run flutter_launcher_icons


```
```dart
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

```
```dart
import 'dart:convert';
import 'package:encrypt/encrypt.dart';

class ApiEncryption {
  static const String _key = "SkadutaPresensi2025SecureKey1234";

  static String decrypt(String encryptedBase64) {
    try {
      final key = Key.fromUtf8(_key);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final data = base64Decode(encryptedBase64);
      final iv = IV(data.sublist(0, 16));
      final encryptedData = data.sublist(16);
      final decrypted = encrypter.decrypt(Encrypted(encryptedData), iv: iv);
      print("DECRYPT BERHASIL!");
      return decrypted;
    } catch (e) {
      print("GAGAL DEKRIPSI: $e");
      rethrow;
    }
  }
}

```
```dart
// ==========================
// presensi_service.dart
// ==========================
import 'dart:convert';
import 'package:http/http.dart' as http;

class PresensiService {
  final String baseUrl = "http://10.10.77.132/skaduta_api";

  Future<Map<String, dynamic>> submitPresensi(
    String userId,
    double lat,
    double lng,
    String jenis,
    String keterangan,
    String selfiePath,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/presensi.php"),
    );

    request.fields['user_id'] = userId;
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();
    request.fields['jenis'] = jenis; // masuk, pulang, izin
    request.fields['keterangan'] = keterangan;
    request.files.add(await http.MultipartFile.fromPath('selfie', selfiePath));

    var response = await request.send();
    var result = await response.stream.bytesToString();
    return jsonDecode(result);
  }
}

```
```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class FakeGpsService {
  static StreamSubscription<Position>? _subscription;

  static Future<void> start({required VoidCallback onFakeDetected}) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _subscription?.cancel();

    _subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
          ),
        ).listen((Position position) {
          if (position.isMocked) {
            onFakeDetected();
          }
        });
  }

  static void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}

```
```dart
// lib/pages/user_management_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../api/api_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage>
    with TickerProviderStateMixin {
  bool _loading = true;
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  final TextEditingController _searchC = TextEditingController();
  Timer? _debounce;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _loadUsers();
    _searchC.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchC.removeListener(_onSearchChanged);
    _searchC.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _filterUsers);
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getUsers();
      final filtered = (data as List).where((u) {
        final role = (u['role']?.toString().toLowerCase() ?? '');
        return role == 'user' || role == 'admin' || role == 'superadmin';
      }).toList();

      setState(() {
        _users = filtered;
        _filteredUsers = filtered
          ..sort(
            (a, b) => (a['nama_lengkap'] ?? '').toString().compareTo(
              (b['nama_lengkap'] ?? '').toString(),
            ),
          );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat user: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterUsers() {
    final query = _searchC.text.toLowerCase().trim();
    setState(() {
      _filteredUsers =
          query.isEmpty
                ? _users
                : _users.where((u) {
                    final nama = (u['nama_lengkap'] ?? '')
                        .toString()
                        .toLowerCase();
                    final username = (u['username'] ?? '')
                        .toString()
                        .toLowerCase();
                    return nama.contains(query) || username.contains(query);
                  }).toList()
            ..sort(
              (a, b) => (a['nama_lengkap'] ?? '').toString().compareTo(
                (b['nama_lengkap'] ?? '').toString(),
              ),
            );
    });
  }

  // ================== TAMBAH USER BARU ==================
  Future<void> _addUser() async {
    final usernameC = TextEditingController();
    final namaC = TextEditingController();
    final nipC = TextEditingController();
    final passC = TextEditingController();
    String selectedRole = 'user';
    String selectedStatus = 'Karyawan';
    bool isLoading = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Tambah User Baru',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: usernameC,
                  decoration: InputDecoration(
                    labelText: 'Username *',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: namaC,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap *',
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nipC,
                  decoration: InputDecoration(
                    labelText: 'NIP/NIK (opsional)',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: const Icon(Icons.shield_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                      value: 'superadmin',
                      child: Text('Super Admin'),
                    ),
                  ],
                  onChanged: (val) => setStateModal(() => selectedRole = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    prefixIcon: const Icon(Icons.work_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Karyawan',
                      child: Text('Karyawan'),
                    ),
                    DropdownMenuItem(value: 'Guru', child: Text('Guru')),
                    DropdownMenuItem(
                      value: 'Staff Lain',
                      child: Text('Staff Lain'),
                    ),
                  ],
                  onChanged: (val) =>
                      setStateModal(() => selectedStatus = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passC,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (usernameC.text.trim().isEmpty ||
                                  namaC.text.trim().isEmpty ||
                                  passC.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Field bertanda * wajib diisi',
                                    ),
                                    backgroundColor: Color(0xFFEF4444),
                                  ),
                                );
                                return;
                              }

                              setStateModal(() => isLoading = true);

                              try {
                                final res = await ApiService.addUser(
                                  username: usernameC.text.trim(),
                                  namaLengkap: namaC.text.trim(),
                                  password: passC.text,
                                  nipNisn: nipC.text.trim().isEmpty
                                      ? null
                                      : nipC.text.trim(),
                                  role: selectedRole,
                                  status: selectedStatus,
                                );

                                if (res['status'] == true ||
                                    res['status'] == 'success') {
                                  Navigator.pop(ctx, true);
                                  _loadUsers();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'User berhasil ditambahkan',
                                      ),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res['message'] ?? 'Gagal menambah user',
                                      ),
                                      backgroundColor: const Color(0xFFEF4444),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('ERROR TAMBAH USER: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Terjadi kesalahan: $e'),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              } finally {
                                if (mounted)
                                  setStateModal(() => isLoading = false);
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Tambah User'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true) _loadUsers();
  }

  // ================== RESET DEVICE ID ==================
  Future<void> _resetDevice(String userId, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.phonelink_erase_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reset Device ID'),
          ],
        ),
        content: Text(
          'Yakin reset device untuk $nama?\nUser harus login ulang di HP baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.resetDeviceId(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Device ID direset'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  // ================== HAPUS USER ==================
  Future<void> _deleteUser(String id, String role) async {
    // Safety check ID
    print("ID YANG AKAN DIHAPUS: '$id'"); // <--- Tambah ini buat debug

    if (id.isEmpty || id == 'null' || id == '0' || id == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID user kosong atau tidak valid. Refresh list user.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      _loadUsers(); // Force reload biar data baru
      return;
    }

    if (role.toLowerCase() == 'superadmin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak boleh hapus superadmin'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFF44336)),
            SizedBox(width: 8),
            Text('Hapus User'),
          ],
        ),
        content: const Text(
          'Yakin ingin menghapus user ini? Tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.deleteUser(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'User dihapus'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  // ================== EDIT USER ==================
  Future<void> _editUser(Map<String, dynamic> user) async {
    final usernameC = TextEditingController(text: user['username']);
    final namaC = TextEditingController(text: user['nama_lengkap'] ?? '');
    final nipC = TextEditingController(text: user['nip_nisn'] ?? '');
    final passC = TextEditingController();

    String? selectedRole = (user['role'] ?? 'user').toString().toLowerCase();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Edit User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: usernameC,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: namaC,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.account_circle),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nipC,
                decoration: const InputDecoration(
                  labelText: 'NIP/NIK (opsional)',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.shield),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(
                    value: 'superadmin',
                    child: Text('Super Admin'),
                  ),
                ],
                onChanged: (val) => selectedRole = val,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passC,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru (kosongkan jika tidak ganti)',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      try {
                        final res = await ApiService.updateUser(
                          id: user['id'].toString(),
                          username: usernameC.text.trim(),
                          namaLengkap: namaC.text.trim(),
                          nipNisn: nipC.text.trim(),
                          role: selectedRole,
                          password: passC.text.isEmpty
                              ? null
                              : passC.text.trim(),
                        );

                        if (res['status'] == 'success' ||
                            res['status'] == true) {
                          Navigator.pop(ctx, true);
                          _loadUsers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User berhasil diperbarui'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Gagal update'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Kelola User & Admin'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadUsers,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: _addUser,
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B82F6), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 100,
                  16,
                  16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextField(
                          controller: _searchC,
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau username...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF3B82F6),
                            ),
                            suffixIcon: _searchC.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _searchC.clear,
                                  )
                                : null,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: ${_filteredUsers.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            const Icon(
                              Icons.people_outline_rounded,
                              color: Color(0xFF3B82F6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        color: const Color(0xFF3B82F6),
                        child: _filteredUsers.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _searchC.text.isNotEmpty
                                            ? Icons.search_off_rounded
                                            : Icons.people_outline_rounded,
                                        size: 80,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        _searchC.text.isNotEmpty
                                            ? 'Tidak ditemukan'
                                            : 'Belum ada user',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _filteredUsers.length,
                                itemBuilder: (ctx, i) {
                                  final u = _filteredUsers[i];
                                  final role = (u['role'] ?? 'user')
                                      .toString()
                                      .toLowerCase();

                                  Color badgeColor;
                                  String label;
                                  switch (role) {
                                    case 'superadmin':
                                      badgeColor = const Color(0xFFEF4444);
                                      label = 'SUPER';
                                      break;
                                    case 'admin':
                                      badgeColor = const Color(0xFF3B82F6);
                                      label = 'ADMIN';
                                      break;
                                    default:
                                      badgeColor = const Color(0xFF10B981);
                                      label = 'USER';
                                  }

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 6,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: badgeColor.withOpacity(
                                          0.1,
                                        ),
                                        child: Text(
                                          (u['username'] ?? '?')[0]
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: badgeColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        u['nama_lengkap'] ?? 'Tanpa Nama',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Username: ${u['username'] ?? '-'}',
                                          ),
                                          if (u['nip_nisn'] != null &&
                                              u['nip_nisn']
                                                  .toString()
                                                  .isNotEmpty)
                                            Text('NIP/NIK: ${u['nip_nisn']}'),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: badgeColor.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              label,
                                              style: TextStyle(
                                                color: badgeColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _editUser(u);
                                              } else if (value == 'delete') {
                                                _deleteUser(
                                                  u['id'].toString(),
                                                  role,
                                                );
                                              } else if (value ==
                                                      'reset_device' &&
                                                  role == 'user') {
                                                _resetDevice(
                                                  u['id'].toString(),
                                                  u['nama_lengkap'] ??
                                                      u['username'],
                                                );
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit),
                                                    SizedBox(width: 8),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Hapus'),
                                                  ],
                                                ),
                                              ),
                                              if (role == 'user')
                                                const PopupMenuItem(
                                                  value: 'reset_device',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.phonelink_erase,
                                                        color: Colors.orange,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text('Reset Device'),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

```
```dart
// pages/rekap_page.dart (ENHANCED: Modern UI with neumorphic cards, subtle gradients, hero animations, enhanced stats dashboard, responsive DataTable, consistent styling without functional changes - FIXED: Removed extra comma in Row children and syntax issues)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class RekapPage extends StatefulWidget {
  const RekapPage({super.key});
  @override
  State<RekapPage> createState() => _RekapPageState();
}

class _RekapPageState extends State<RekapPage> with TickerProviderStateMixin {
  bool _loading = false;
  List<dynamic> _data = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  Map<String, Map<String, String>> _pivot = {};
  List<String> _allDates = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final Map<int, String> _indonesianMonths = {
    1: 'Januari',
    2: 'Februari',
    3: 'Maret',
    4: 'April',
    5: 'Mei',
    6: 'Juni',
    7: 'Juli',
    8: 'Agustus',
    9: 'September',
    10: 'Oktober',
    11: 'November',
    12: 'Desember',
  };

  final Map<String, String> _dayNames = {
    'Mon': 'Sen',
    'Tue': 'Sel',
    'Wed': 'Rab',
    'Thu': 'Kam',
    'Fri': 'Jum',
    'Sat': 'Sab',
    'Sun': 'Min',
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _loadRekap();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadRekap() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getRekap(
        month: _selectedMonth.toString().padLeft(2, '0'),
        year: _selectedYear.toString(),
      );
      setState(() => _data = data);
      _processPivot();
      _animController.forward(from: 0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal load data: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _processPivot() {
    _pivot.clear();
    _generateAllDates();

    for (var item in _data) {
      final nama = item['nama_lengkap'] ?? 'Tanpa Nama';
      final rawDate = item['created_at'] ?? '';
      final tgl = rawDate.length >= 10 ? rawDate.substring(0, 10) : '';
      final jenis = item['jenis'] ?? '-';
      final status = item['status'] ?? 'Pending';

      final shortJenis = _getShortJenis(jenis, status);

      _pivot.putIfAbsent(nama, () => {});
      if (tgl.isNotEmpty && _allDates.contains(tgl)) {
        if (_pivot[nama]![tgl] == null ||
            ['PF', 'I', 'R', 'PN'].indexOf(shortJenis) <
                ['PF', 'I', 'R', 'PN'].indexOf(_pivot[nama]![tgl]!)) {
          _pivot[nama]![tgl] = shortJenis;
        }
      }
    }
  }

  String _getShortJenis(String jenis, String status) {
    if (status != 'Disetujui') {
      return 'NA'; // Tidak disetujui
    }

    switch (jenis) {
      case 'Masuk':
      case 'Pulang':
        return 'R'; // Regular (hijau)
      case 'Penugasan_Masuk':
      case 'Penugasan_Pulang':
        return 'PN'; // Penugasan Normal (oren)
      case 'Penugasan_Full':
        return 'PF'; // Penugasan Full (kuning)
      case 'Izin':
        return 'I'; // Izin (biru)
      case 'Pulang Cepat':
        return 'PC'; // Pulang Cepat (amber, if needed)
      default:
        return '-';
    }
  }

  void _generateAllDates() {
    _allDates.clear();
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedYear, _selectedMonth, day);
      _allDates.add(DateFormat('yyyy-MM-dd').format(date));
    }
  }

  bool _isWeekend(String dateStr) {
    final date = DateTime.parse(dateStr);
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  bool _isFuture(String dateStr) {
    final date = DateTime.parse(dateStr);
    return date.isAfter(DateTime.now());
  }

  String _getIndonesianMonth(int month) {
    return _indonesianMonths[month] ?? month.toString();
  }

  String _getIndonesianDayAbbrev(DateTime date) {
    final englishAbbrev = DateFormat('EEE', 'en_US').format(date);
    return _dayNames[englishAbbrev] ?? englishAbbrev;
  }

  Color _getFlutterColor(String code) {
    switch (code) {
      case 'R':
        return Colors.green; // Hijau for regular
      case 'PN':
        return Colors.orange; // Oren for penugasan normal
      case 'PF':
        return Colors.amber; // Kuning for penugasan full
      case 'I':
        return Colors.blue; // Biru for izin
      case 'NA':
        return Colors.red[700]!; // Abu merah for not approved
      case 'PC':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getBgColorHex(String code) {
    switch (code) {
      case 'R':
        return 'FF4CAF50'; // Hijau
      case 'PN':
        return 'FFFF9800'; // Oren
      case 'PF':
        return 'FFFFB74D'; // Kuning
      case 'I':
        return 'FF2196F3'; // Biru
      case 'NA':
        return 'FFD32F2F'; // Abu merah
      case 'PC':
        return 'FFFFB74D';
      default:
        return 'FFE6E6E6'; // Abu-abu muda
    }
  }

  xls.ExcelColor _getExcelBgColor(String code) {
    final hex = _getBgColorHex(code);
    return xls.ExcelColor.fromHexString('#$hex');
  }

  xls.ExcelColor _getExcelFontColor() {
    return xls.ExcelColor.fromHexString('#FFFFFF');
  }

  xls.ExcelColor _getExcelGrayColor(String hexFull) {
    return xls.ExcelColor.fromHexString('#$hexFull');
  }

  Future<void> _exportToExcel() async {
    if (_data.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data kosong!')));
      }
      return;
    }

    Directory? dir;
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin penyimpanan ditolak')),
          );
        }
        return;
      }
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) await dir.create(recursive: true);
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      dir = await getApplicationDocumentsDirectory();
    } else {
      dir = await getTemporaryDirectory();
    }

    final fileName =
        'Rekap_Absensi_${_getIndonesianMonth(_selectedMonth)} $_selectedYear.xlsx';
    final path = '${dir.path}/$fileName';

    var excel = xls.Excel.createExcel();
    excel.delete('Sheet1');
    xls.Sheet lengkapSheet = excel['Rekap Lengkap'];
    xls.Sheet harianSheet = excel['Rekap Harian'];

    // Sheet Rekap Lengkap (detail)
    lengkapSheet.appendRow([
      xls.TextCellValue('No'),
      xls.TextCellValue('Nama'),
      xls.TextCellValue('Tanggal'),
      xls.TextCellValue('Jenis'),
      xls.TextCellValue('Status'),
      xls.TextCellValue('Keterangan'),
    ]);

    int no = 1;
    for (var item in _data) {
      final jenis = item['jenis'] ?? '-';
      final status = item['status'] ?? 'Pending';
      final keterangan = status != 'Disetujui'
          ? 'Tidak Disetujui'
          : (item['keterangan'] ?? '-');
      lengkapSheet.appendRow([
        xls.TextCellValue(no.toString()),
        xls.TextCellValue(item['nama_lengkap'] ?? '-'),
        xls.TextCellValue(item['created_at']?.substring(0, 10) ?? '-'),
        xls.TextCellValue(jenis),
        xls.TextCellValue(status),
        xls.TextCellValue(keterangan),
      ]);
      no++;
    }

    // Sheet Rekap Harian
    List<xls.CellValue> header = [xls.TextCellValue('Nama')];
    for (var d in _allDates) {
      header.add(xls.TextCellValue(d.substring(8, 10)));
    }
    harianSheet.appendRow(header);

    // Styling header
    for (int i = 0; i < header.length; i++) {
      final cell = harianSheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.cellStyle = xls.CellStyle(
        bold: true,
        backgroundColorHex: _getExcelGrayColor('FFE6E6E6'),
        horizontalAlign: xls.HorizontalAlign.Center,
      );
    }

    List<String> names = _pivot.keys.toList()..sort();
    int rowIndex = 1;
    for (var nama in names) {
      List<xls.CellValue> row = [xls.TextCellValue(nama)];
      List<String> values = [];
      for (var d in _allDates) {
        String value;
        if (_isWeekend(d)) {
          value = 'Libur';
        } else if (_isFuture(d)) {
          value = '';
        } else {
          value = _pivot[nama]![d] ?? '-';
        }
        row.add(xls.TextCellValue(value));
        values.add(value);
      }
      harianSheet.appendRow(row);

      // Styling data cells (columns 1+)
      for (int i = 0; i < values.length; i++) {
        final value = values[i];
        final cell = harianSheet.cell(
          xls.CellIndex.indexByColumnRow(
            columnIndex: i + 1,
            rowIndex: rowIndex,
          ),
        );
        if (value == 'Libur') {
          cell.cellStyle = xls.CellStyle(
            backgroundColorHex: _getExcelGrayColor('FFD9D9D9'),
          );
        } else if (value != '' && value != '-') {
          cell.cellStyle = xls.CellStyle(
            backgroundColorHex: _getExcelBgColor(value),
            fontColorHex: _getExcelFontColor(),
            bold: true,
            horizontalAlign: xls.HorizontalAlign.Center,
          );
        }
      }
      rowIndex++;
    }

    await File(path).writeAsBytes(excel.encode()!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil diexport: $fileName'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'BUKA',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(path),
          ),
        ),
      );
    }
  }

  void _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (picked != null &&
        (picked.month != _selectedMonth || picked.year != _selectedYear)) {
      setState(() {
        _selectedMonth = picked.month;
        _selectedYear = picked.year;
      });
      _loadRekap();
    }
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _legendItem('R', 'Masuk/Pulang Biasa', Colors.green),
        _legendItem('PN', 'Penugasan Masuk/Pulang', Colors.orange),
        _legendItem('PF', 'Penugasan Full', Colors.amber),
        _legendItem('I', 'Izin', Colors.blue),
        _legendItem('NA', 'Tidak Disetujui', Colors.red[700]!),
        _legendItem('-', 'Tidak Hadir', Colors.grey[400]!),
        _legendItem('Libur', 'Weekend', Colors.grey[300]!),
      ],
    );
  }

  Widget _legendItem(String code, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$code - $label',
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  int _getStats(String code) {
    int count = 0;
    for (var nama in _pivot.keys) {
      for (var d in _allDates) {
        if (!_isWeekend(d) && !_isFuture(d) && _pivot[nama]![d] == code) {
          count++;
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalTeachers = _pivot.keys.length;
    final totalDays = _allDates.length;
    final presentDays =
        _getStats('R') + _getStats('PN') + _getStats('PF') + _getStats('I');
    final absentDays =
        totalTeachers * (totalDays - _allDates.where(_isWeekend).length) -
        presentDays;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Rekap Absensi Guru',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showMonthPicker,
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Pilih Bulan',
          ),
          Hero(
            tag: 'refresh_rekap',
            child: IconButton(
              onPressed: _loadRekap,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
          ),
          IconButton(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Excel',
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.9),
                const Color(0xFF3B82F6).withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF3B82F6).withOpacity(0.05), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF3B82F6),
                ),
              )
            : _data.isEmpty
            ? Center(
                child: Container(
                  margin: const EdgeInsets.all(40),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.05),
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 80,
                        color: const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Tidak ada data untuk periode ini',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coba pilih bulan lain atau tunggu data baru',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF9CA3AF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 80,
                    16,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Dashboard Cards
                      const SizedBox(height: 24),
                      // Info Card Periode
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Periode Rekap',
                                    style: TextStyle(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${_getIndonesianMonth(_selectedMonth)} $_selectedYear',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total Entri',
                                    style: TextStyle(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${_data.length}',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF3B82F6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Legend Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Keterangan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildLegend(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Title
                      const Text(
                        'Rekap Harian Guru',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // DataTable Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 70,
                              dataRowHeight: 70,
                              columnSpacing: 12,
                              headingTextStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1F2937),
                              ),
                              columns: [
                                const DataColumn(
                                  label: Text(
                                    'Nama Guru',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                ..._allDates.map((d) {
                                  final dayNum = d.substring(8);
                                  final isWeekend = _isWeekend(d);
                                  final date = DateTime.parse(d);
                                  final dayAbbrev = _getIndonesianDayAbbrev(
                                    date,
                                  );
                                  return DataColumn(
                                    label: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dayNum,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        Text(
                                          dayAbbrev,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isWeekend
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              rows: (_pivot.keys.toList()..sort()).map((nama) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          nama,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ..._allDates.map((d) {
                                      if (_isWeekend(d)) {
                                        return DataCell(
                                          Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Libur',
                                                style: TextStyle(
                                                  color: Color(0xFF6B7280),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      if (_isFuture(d)) {
                                        return const DataCell(Text(''));
                                      }
                                      final val = _pivot[nama]![d] ?? '-';
                                      final flutterColor = _getFlutterColor(
                                        val,
                                      );

                                      return DataCell(
                                        Center(
                                          child: val == '-'
                                              ? Text(
                                                  val,
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF6B7280,
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: flutterColor
                                                        .withOpacity(0.2),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: flutterColor
                                                          .withOpacity(0.5),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      val,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: flutterColor,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

```
```dart
// pages/presensi_page.dart
// VERSI FINAL – SELFIE KAMERA FULLSCREEN + TOMBOL KIRIM SELALU KELIHATAN + ATURAN JAM BARU (VALIDASI JAM DI SERVER SAJA)
// Tidak ada perubahan di Dart karena validasi jam sudah di-handle di PHP server dengan timezone Jogja.
// Client hanya validasi lokasi dan field input.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:intl/intl.dart';

import '../api/api_service.dart';
import '../models/user_model.dart';

List<CameraDescription> cameras = [];

class PresensiPage extends StatefulWidget {
  final UserModel user;
  final String initialJenis;

  const PresensiPage({
    super.key,
    required this.user,
    required this.initialJenis,
  });

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage>
    with TickerProviderStateMixin {
  Position? _position;
  late String _jenis;
  final TextEditingController _ketC = TextEditingController();
  final TextEditingController _infoC = TextEditingController();
  File? _selfieFile;
  File? _dokumenFile;
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  static const double sekolahLat = -7.7771639173358516;
  static const double sekolahLng = 110.36716347232226;
  static const double maxRadius = 120;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _jenis = widget.initialJenis;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat();
    if (_isMapNeeded) _initLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ketC.dispose();
    _infoC.dispose();
    super.dispose();
  }

  bool get _isMapNeeded => _jenis == 'Masuk' || _jenis == 'Pulang';
  bool get _isPenugasan => _jenis.startsWith('Penugasan');
  bool get _isIzin => _jenis == 'Izin';
  bool get _isPulangCepat => _jenis == 'Pulang Cepat';
  bool get _wajibSelfie =>
      _jenis == 'Masuk' || _jenis == 'Pulang' || _isPulangCepat;

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled)
      return _showSnack('Aktifkan layanan lokasi untuk melanjutkan');

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied)
        return _showSnack('Izin lokasi diperlukan');
    }
    if (perm == LocationPermission.deniedForever)
      return _showSnack('Izin lokasi ditolak permanen. Buka pengaturan.');

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _position = pos);
    } catch (e) {
      _showSnack('Gagal mendeteksi lokasi. Coba lagi.');
    }
  }

  double _distanceToSchool() {
    if (_position == null) return 999999;
    return Geolocator.distanceBetween(
      _position!.latitude,
      _position!.longitude,
      sekolahLat,
      sekolahLng,
    );
  }

  Future<void> _openCameraSelfie() async {
    if (cameras.isEmpty) cameras = await availableCameras();
    if (cameras.isEmpty) {
      _showSnack('Kamera tidak tersedia');
      return;
    }
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraSelfieScreen(initialCamera: cameras.first),
      ),
    );
    if (result is File) setState(() => _selfieFile = result);
  }

  Future<void> _pickDokumen() async {
    final doc = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (doc != null) setState(() => _dokumenFile = File(doc.path));
  }

  Future<void> _submitPresensi() async {
    if (_isMapNeeded) {
      if (_position == null) return _showSnack('Menunggu deteksi lokasi');
      final jarak = _distanceToSchool();
      if (jarak > maxRadius)
        return _showSnack(
          'Lokasi di luar radius sekolah (${jarak.toStringAsFixed(0)} m)',
        );
    }

    if (_wajibSelfie && _selfieFile == null)
      return _showSnack('Silakan ambil foto selfie');
    if (_isIzin || _isPulangCepat) {
      if (_ketC.text.trim().isEmpty) return _showSnack('Isi keterangan');
      if (_isIzin && _dokumenFile == null)
        return _showSnack('Unggah bukti izin');
    }
    if (_isPenugasan) {
      if (_infoC.text.trim().isEmpty)
        return _showSnack('Isi informasi penugasan');
      if (_dokumenFile == null) return _showSnack('Unggah dokumen penugasan');
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.submitPresensi(
        userId: widget.user.id,
        jenis: _jenis,
        keterangan: _ketC.text.trim(),
        informasi: _infoC.text.trim(),
        dokumenBase64: _dokumenFile != null
            ? base64Encode(await _dokumenFile!.readAsBytes())
            : '',
        latitude: _position?.latitude.toString() ?? '0',
        longitude: _position?.longitude.toString() ?? '0',
        base64Image: _selfieFile != null
            ? base64Encode(await _selfieFile!.readAsBytes())
            : '',
      );

      if (res['status'] == true)
        _showSuccessDialog();
      else
        _showSnack(res['message'] ?? 'Gagal mengirim presensi');
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                "Presensi Berhasil",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Presensi $_jenis telah tercatat.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              const Text(
                "Terima kasih",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted)
        Navigator.of(context)
          ..pop()
          ..pop();
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: msg.contains('Berhasil')
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildMap() {
    final jarak = _distanceToSchool();
    final inRadius = jarak <= maxRadius;

    return Container(
      height: 420,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _position != null
                    ? lat_lng.LatLng(_position!.latitude, _position!.longitude)
                    : lat_lng.LatLng(sekolahLat, sekolahLng),
                initialZoom: 17.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => CircleLayer(
                    circles: [
                      CircleMarker(
                        point: lat_lng.LatLng(sekolahLat, sekolahLng),
                        radius: maxRadius + (_pulseAnimation.value * 20),
                        useRadiusInMeter: true,
                        color: Colors.transparent,
                        borderColor: inRadius
                            ? const Color(0xFF10B981).withOpacity(0.4)
                            : const Color(0xFFEF4444).withOpacity(0.4),
                        borderStrokeWidth: 3,
                      ),
                    ],
                  ),
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: lat_lng.LatLng(sekolahLat, sekolahLng),
                      radius: maxRadius,
                      useRadiusInMeter: true,
                      color: inRadius
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : const Color(0xFFEF4444).withOpacity(0.15),
                      borderColor: inRadius
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: lat_lng.LatLng(sekolahLat, sekolahLng),
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 32,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF374151),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Sekolah",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_position != null)
                      Marker(
                        point: lat_lng.LatLng(
                          _position!.latitude,
                          _position!.longitude,
                        ),
                        width: 90,
                        height: 80,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                size: 28,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 70,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Anda",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: inRadius
                        ? [
                            const Color(0xFF10B981).withOpacity(0.9),
                            const Color(0xFF10B981).withOpacity(0.7),
                          ]
                        : [
                            const Color(0xFFEF4444).withOpacity(0.9),
                            const Color(0xFFEF4444).withOpacity(0.7),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      inRadius
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inRadius
                                ? "Dalam Wilayah Sekolah"
                                : "Di Luar Wilayah",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "${jarak.toStringAsFixed(0)} m dari lokasi sekolah",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController c,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 3,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _jenis.replaceAll('_', ' '),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B82F6), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _jenis == 'Masuk'
                          ? 'Selamat Datang'
                          : _jenis == 'Pulang'
                          ? 'Selamat Pulang'
                          : 'Presensi $_jenis',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isMapNeeded
                          ? 'Pastikan posisi Anda di wilayah sekolah'
                          : 'Lengkapi informasi berikut',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_isMapNeeded) ...[
                      _buildMap(),
                      const SizedBox(height: 24),
                    ],
                    if (_isIzin || _isPulangCepat)
                      _buildTextField(
                        _ketC,
                        'Keterangan / Alasan',
                        'Misalnya: Sakit, urusan keluarga...',
                        Icons.description_outlined,
                      ),
                    if (_isIzin || _isPulangCepat) const SizedBox(height: 16),
                    if (_isPenugasan)
                      _buildTextField(
                        _infoC,
                        'Informasi Penugasan',
                        'Deskripsikan tugas yang diberikan',
                        Icons.task_outlined,
                        maxLines: 4,
                      ),
                    if (_isPenugasan) const SizedBox(height: 16),
                    if (_wajibSelfie)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              title: const Text(
                                'Foto Selfie',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: const Text(
                                'Diperlukan untuk verifikasi',
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: _openCameraSelfie,
                            ),
                            if (_selfieFile != null)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selfieFile!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (_wajibSelfie) const SizedBox(height: 16),
                    if (_isIzin || _isPenugasan)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.attachment_outlined,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                              title: Text(
                                _isIzin ? 'Bukti Izin' : 'Dokumen Penugasan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: const Text('Pilih dari galeri'),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: _pickDokumen,
                            ),
                            if (_dokumenFile != null)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _dokumenFile!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submitPresensi,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.arrow_forward),
                      label: Text(
                        _loading ? 'Mengirim...' : 'Kirim Presensi',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CameraSelfieScreen extends StatefulWidget {
  final CameraDescription initialCamera;
  const CameraSelfieScreen({super.key, required this.initialCamera});

  @override
  State<CameraSelfieScreen> createState() => _CameraSelfieScreenState();
}

class _CameraSelfieScreenState extends State<CameraSelfieScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isRearCamera = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      _isRearCamera ? cameras.last : cameras.first,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _switchCamera() async {
    _isRearCamera = !_isRearCamera;
    _controller = CameraController(
      _isRearCamera ? cameras.last : cameras.first,
      ResolutionPreset.medium,
    );
    await _controller.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      Navigator.pop(context, File(image.path));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengambil foto')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Center(child: CameraPreview(_controller)),
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Arahkan kamera ke wajah Anda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.flip_camera_ios_outlined,
                            size: 32,
                            color: Colors.white,
                          ),
                          onPressed: _switchCamera,
                        ),
                        GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: const Icon(
                              Icons.circle,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_outlined,
                            size: 32,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Memuat kamera...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

```
```dart
import 'package:flutter/material.dart';
import '../api/api_service.dart'; // sesuaikan path
import '../models/user_model.dart'; // sesuaikan path

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _inputC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _inputC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final res = await ApiService.login(
        input: _inputC.text.trim(),
        password: _passC.text.trim(),
      );

      if (res['status'] == true) {
        final userData = res['user'] as Map<String, dynamic>;

        final user = UserModel.fromJson(userData);

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/dashboard', arguments: user);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Login gagal'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
            colors: [
              const Color(0xFF3B82F6),
              const Color(0xFF3B82F6).withOpacity(0.8),
              const Color(0xFF1E40AF).withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo & Judul
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Skaduta Presensi',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Silakan login untuk melanjutkan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Card Form
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Input Username / NIP / NIK
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _inputC,
                                      decoration: const InputDecoration(
                                        labelText: 'Username / NIP / NIK',
                                        labelStyle: TextStyle(
                                          color: Color(0xFF6B7280),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.person_outline_rounded,
                                          color: Color(0xFF6B7280),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 16),
                                      validator: (v) => v!.trim().isEmpty
                                          ? 'Wajib diisi'
                                          : null,
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Input Password
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _passC,
                                      obscureText: _obscure,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: const TextStyle(
                                          color: Color(0xFF6B7280),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                          color: Color(0xFF6B7280),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: const Color(0xFF6B7280),
                                          ),
                                          onPressed: () => setState(
                                            () => _obscure = !_obscure,
                                          ),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                      ),
                                      style: const TextStyle(fontSize: 16),
                                      validator: (v) =>
                                          v!.isEmpty ? 'Wajib diisi' : null,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Tombol Login
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF3B82F6,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 5,
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Masuk Sekarang',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Info Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 24,
                                color: Colors.white,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Hubungi admin untuk pembuatan akun baru atau kendala login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

```
```dart
// pages/history_page.dart (ENHANCED: Modern UI with subtle gradients, neumorphic cards, hero animations, improved empty state, full-screen image viewer with zoom, sorted & filtered list, consistent styling; FIXED: Dropdown with custom overlay for better visibility)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/user_model.dart';

class HistoryPage extends StatefulWidget {
  final UserModel user;
  const HistoryPage({super.key, required this.user});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  bool _loading = false;
  List<dynamic> _items = [];
  String _filterJenis =
      'All'; // All, Masuk, Pulang, Izin, Pulang Cepat, Penugasan_*

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _loadHistory();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getUserHistory(widget.user.id);
      setState(() {
        _items = data ?? [];
        _items.sort(
          (a, b) =>
              DateTime.parse(
                b['created_at'] ?? DateTime.now().toIso8601String(),
              ).compareTo(
                DateTime.parse(
                  a['created_at'] ?? DateTime.now().toIso8601String(),
                ),
              ),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal ambil histori: $e',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredItems {
    if (_filterJenis == 'All') return _items;
    return _items
        .where((item) => (item['jenis'] ?? '') == _filterJenis)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Riwayat Presensi',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _filterJenis,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
            color: const Color(0xFF1F2937),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 50),
            itemBuilder: (context) =>
                [
                      'All',
                      'Masuk',
                      'Pulang',
                      'Izin',
                      'Pulang Cepat',
                      'Penugasan_Masuk',
                      'Penugasan_Pulang',
                      'Penugasan_Full',
                    ]
                    .map(
                      (j) => PopupMenuItem(
                        value: j,
                        child: Text(
                          j,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                    .toList(),
            onSelected: (v) => setState(() => _filterJenis = v),
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.9),
                const Color(0xFF3B82F6).withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF3B82F6).withOpacity(0.05), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF3B82F6),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: const Color(0xFF3B82F6),
                  child: _buildContentList(),
                ),
        ),
      ),
    );
  }

  /// List utama di dalam RefreshIndicator
  Widget _buildContentList() {
    if (_filteredItems.isEmpty) {
      // Tetap pakai ListView supaya pull-to-refresh tetap bisa
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 100,
          16,
          20,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.1),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, color: Color(0xFF3B82F6), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Total: 0',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildEmptyView(),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 100,
        16,
        20,
      ),
      itemCount: _filteredItems.length + 1, // +1 buat header "Total"
      itemBuilder: (ctx, index) {
        if (index == 0) {
          // Header total di paling atas
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.1),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, color: Color(0xFF3B82F6), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${_filteredItems.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final item = _filteredItems[index - 1];

        final status = (item['status'] ?? 'Waiting').toString();
        Color statusColor = const Color(0xFFF59E0B);
        if (status == 'Disetujui') statusColor = const Color(0xFF10B981);
        if (status == 'Ditolak') statusColor = const Color(0xFFEF4444);

        final created = DateTime.parse(
          item['created_at'] ?? DateTime.now().toIso8601String(),
        );
        final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(created);

        final baseUrl = ApiService.baseUrl;

        final selfie = item['selfie'];
        final String? fotoUrl = (selfie != null && selfie.toString().isNotEmpty)
            ? '$baseUrl/selfie/$selfie'
            : null;

        final dokumen = item['dokumen'];
        final String? dokumenUrl =
            (dokumen != null && dokumen.toString().isNotEmpty)
            ? '$baseUrl/dokumen/$dokumen'
            : null;

        final informasi = item['informasi']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getColorForJenis(
                              item['jenis']?.toString() ?? '',
                            ).withOpacity(0.1),
                            _getColorForJenis(
                              item['jenis']?.toString() ?? '',
                            ).withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForJenis(item['jenis']?.toString() ?? ''),
                        color: _getColorForJenis(
                          item['jenis']?.toString() ?? '',
                        ),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['jenis']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Tanggal: $formattedDate',
                            style: TextStyle(
                              color: const Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status == 'Disetujui'
                                ? Icons.check_circle
                                : status == 'Ditolak'
                                ? Icons.cancel
                                : Icons.pending,
                            color: statusColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Keterangan: ${item['keterangan'] ?? '-'}',
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: 15,
                  ),
                ),
                if (informasi.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Info: $informasi',
                      style: TextStyle(
                        color: const Color(0xFF3B82F6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (dokumenUrl != null || fotoUrl != null)
                  Row(
                    children: [
                      if (dokumenUrl != null) ...[
                        Hero(
                          tag: 'dokumen_${item['id']}',
                          child: GestureDetector(
                            onTap: () => _showDokumen(dokumenUrl),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFF59E0B).withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attachment_rounded,
                                    size: 18,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dokumen',
                                    style: TextStyle(
                                      color: const Color(0xFFF59E0B),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (fotoUrl != null)
                        Hero(
                          tag: 'selfie_${item['id']}',
                          child: GestureDetector(
                            onTap: () => _showFullPhoto(fotoUrl),
                            child: Container(
                              height: 70,
                              width: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  fotoUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF3B82F6),
                                            ),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image_not_supported_rounded,
                                          size: 32,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
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
      },
    );
  }

  // Tampilan kalau kosong
  Widget _buildEmptyView() {
    return Container(
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3B82F6).withOpacity(0.05), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 80,
            color: const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada riwayat presensi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai absen hari ini untuk melihat riwayat',
            style: TextStyle(fontSize: 14, color: const Color(0xFF9CA3AF)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Full screen photo viewer
  void _showFullPhoto(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: 'selfie_${_filteredItems[0]['id']}', // Simplified for demo
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 300,
                          width: 300,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 300,
                        width: 300,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported_rounded,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simple dokumen viewer
  void _showDokumen(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_rounded,
                    size: 28,
                    color: Color(0xFFF59E0B),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Dokumen',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_drive_file_outlined,
                            size: 64,
                            color: Color(0xFF9CA3AF),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Tidak dapat menampilkan dokumen',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Tutup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForJenis(String jenis) {
    switch (jenis) {
      case 'Masuk':
      case 'Penugasan_Masuk':
        return Icons.login_rounded;
      case 'Pulang':
      case 'Penugasan_Pulang':
        return Icons.logout_rounded;
      case 'Izin':
        return Icons.block_rounded;
      case 'Pulang Cepat':
        return Icons.fast_forward_rounded;
      case 'Penugasan_Full':
        return Icons.assignment_turned_in_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _getColorForJenis(String jenis) {
    switch (jenis) {
      case 'Masuk':
      case 'Penugasan_Masuk':
        return const Color(0xFF10B981);
      case 'Pulang':
      case 'Penugasan_Pulang':
        return const Color(0xFFF59E0B);
      case 'Izin':
        return const Color(0xFFEF4444);
      case 'Pulang Cepat':
        return const Color(0xFF3B82F6);
      case 'Penugasan_Full':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

```
```dart
// lib/pages/dashboard_page.dart - DIPERBARUI: Tambah Menu Profile di AppBar + Tombol Ubah Password di halaman Profile (tampilan super keren & responsif)
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../api/api_service.dart';

class DashboardPage extends StatefulWidget {
  final UserModel user;
  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  String _currentLocation = 'Sedang memuat lokasi...';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _currentLocation = 'Lokasi GPS mati. Nyalain dulu ya!');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(
          () => _currentLocation = 'Izin lokasi ditolak. Buka pengaturan app.',
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(
        () =>
            _currentLocation = 'Izin lokasi ditolak permanen. Buka pengaturan.',
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        _currentLocation =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() => _currentLocation = 'Gagal baca lokasi: $e');
    }
  }

  // ================== HALAMAN PROFILE + UBAH PASSWORD ==================
  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProfilePage(user: widget.user)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          // TOMBOL PROFILE DI APPBAR (ICON PERSON)
          IconButton(
            icon: Hero(
              tag: 'avatar_${widget.user.id}',
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
            onPressed: _openProfile,
            tooltip: 'Profile',
          ),
          Hero(
            tag: 'logout',
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 28),
              onPressed: () async {
                await ApiService.logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.9),
                const Color(0xFF3B82F6).withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF3B82F6).withOpacity(0.05), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 100,
                    20,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Hero(
                            tag: 'avatar_${widget.user.id}',
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: cs.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, ${widget.user.namaLengkap}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Role: ${widget.user.role.toUpperCase()}',
                                  style: TextStyle(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withOpacity(0.05),
                              Colors.blue.withOpacity(0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: const Color(0xFF3B82F6),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _currentLocation,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_currentLocation.contains('memuat') ||
                                _currentLocation.contains('Gagal'))
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF3B82F6),
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 20,
                                ),
                                onPressed: _getCurrentLocation,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.user.role == 'user')
                        _buildUserSection(context),
                      if (widget.user.role == 'admin')
                        _buildAdminSection(context),
                      if (widget.user.role == 'superadmin')
                        _buildSuperAdminSection(context),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Hero(
        tag: 'card_${title.toLowerCase()}',
        child: Material(
          elevation: 8,
          shadowColor: color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            splashColor: color.withOpacity(0.2),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.white.withOpacity(0.95)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.1),
                          color.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 32, color: color),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 20,
                    color: color.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          icon: Icons.login_rounded,
          title: 'Absen Masuk Biasa',
          subtitle: 'Absen masuk harian (otomatis disetujui)',
          onTap: () => _navigateToPresensi(context, 'Masuk'),
          color: const Color(0xFF10B981),
        ),
        _card(
          icon: Icons.logout_rounded,
          title: 'Absen Pulang Biasa',
          subtitle: 'Absen pulang harian (otomatis disetujui)',
          onTap: () => _navigateToPresensi(context, 'Pulang'),
          color: const Color(0xFFF59E0B),
        ),
        _card(
          icon: Icons.fast_forward_rounded,
          title: 'Pulang Cepat Biasa',
          subtitle: 'Pulang lebih awal (otomatis disetujui)',
          onTap: () => _navigateToPresensi(context, 'Pulang Cepat'),
          color: const Color(0xFF3B82F6),
        ),
        _card(
          icon: Icons.block_rounded,
          title: 'Izin Tidak Masuk',
          subtitle: 'Ajukan izin (perlu persetujuan admin)',
          onTap: () => _navigateToPresensi(context, 'Izin'),
          color: const Color(0xFFEF4444),
        ),
        _card(
          icon: Icons.assignment_rounded,
          title: 'Penugasan',
          subtitle: 'Ajukan penugasan khusus (perlu persetujuan admin)',
          onTap: () => _showPenugasanSheet(context),
          color: const Color(0xFF8B5CF6),
        ),
        _card(
          icon: Icons.history_rounded,
          title: 'Riwayat Presensi',
          subtitle: 'Lihat riwayat presensi kamu',
          onTap: () {
            Navigator.pushNamed(context, '/history', arguments: widget.user);
          },
          color: const Color(0xFF6366F1),
        ),
      ],
    );
  }

  void _navigateToPresensi(BuildContext context, String jenis) {
    Navigator.pushNamed(
      context,
      '/presensi',
      arguments: {'user': widget.user, 'jenis': jenis},
    );
  }

  void _showPenugasanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    size: 28,
                    color: Color(0xFF8B5CF6),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Pilih Jenis Penugasan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _subCard(
                icon: Icons.login_rounded,
                title: 'Absen Masuk Penugasan',
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToPresensi(ctx, 'Penugasan_Masuk');
                },
                color: const Color(0xFF10B981),
              ),
              _subCard(
                icon: Icons.logout_rounded,
                title: 'Absen Pulang Penugasan',
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToPresensi(ctx, 'Penugasan_Pulang');
                },
                color: const Color(0xFFF59E0B),
              ),
              _subCard(
                icon: Icons.assignment_turned_in_rounded,
                title: 'Penugasan Full Day',
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToPresensi(ctx, 'Penugasan_Full');
                },
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20,
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          icon: Icons.list_alt_rounded,
          title: 'Kelola User Presensi',
          subtitle: 'Lihat list user, histori per user, dan konfirmasi absensi',
          onTap: () {
            Navigator.pushNamed(context, '/admin-user-list');
          },
          color: const Color(0xFF3B82F6),
        ),
        _card(
          icon: Icons.verified_user_rounded,
          title: 'Konfirmasi Absensi',
          subtitle: 'Setujui / tolak presensi user secara global',
          onTap: () {
            Navigator.pushNamed(context, '/admin-presensi');
          },
          color: const Color(0xFF10B981),
        ),
        _card(
          icon: Icons.table_chart_rounded,
          title: 'Rekap Absensi',
          subtitle: 'Lihat rekap presensi semua user',
          onTap: () {
            Navigator.pushNamed(context, '/rekap');
          },
          color: const Color(0xFF6366F1),
        ),
      ],
    );
  }

  Widget _buildSuperAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          icon: Icons.supervisor_account_rounded,
          title: 'Kelola User & Admin',
          subtitle: 'CRUD akun user dan admin, edit info, ganti password',
          onTap: () {
            Navigator.pushNamed(context, '/user-management');
          },
          color: const Color(0xFF8B5CF6),
        ),
        _card(
          icon: Icons.list_alt_rounded,
          title: 'Kelola User Presensi',
          subtitle: 'Lihat list user, histori per user, dan konfirmasi absensi',
          onTap: () {
            Navigator.pushNamed(context, '/admin-user-list');
          },
          color: const Color(0xFF3B82F6),
        ),
        _card(
          icon: Icons.verified_user_rounded,
          title: 'Konfirmasi Absensi',
          subtitle: 'Setujui / tolak presensi user secara global',
          onTap: () {
            Navigator.pushNamed(context, '/admin-presensi');
          },
          color: const Color(0xFF10B981),
        ),
        _card(
          icon: Icons.table_chart_rounded,
          title: 'Rekap Absensi',
          subtitle: 'Lihat rekap presensi semua user',
          onTap: () {
            Navigator.pushNamed(context, '/rekap');
          },
          color: const Color(0xFF6366F1),
        ),
      ],
    );
  }
}

// ================== HALAMAN PROFILE BARU (SUPER KEREN & RESPONSIF) ==================
class ProfilePage extends StatefulWidget {
  final UserModel user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = false;

  Future<void> _ubahPassword() async {
    final oldPassC = TextEditingController();
    final newPassC = TextEditingController();
    final confirmPassC = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          elevation: 20,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Ubah Password',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPassC,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password Lama',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPassC,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPassC,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (oldPassC.text.isEmpty ||
                          newPassC.text.isEmpty ||
                          confirmPassC.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Semua field wajib diisi'),
                          ),
                        );
                        return;
                      }
                      if (newPassC.text != confirmPassC.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password baru tidak cocok'),
                          ),
                        );
                        return;
                      }
                      if (newPassC.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password minimal 6 karakter'),
                          ),
                        );
                        return;
                      }

                      setStateDialog(() => isLoading = true);

                      try {
                        final loginRes = await ApiService.login(
                          input:
                              widget.user.username ?? widget.user.namaLengkap,
                          password: oldPassC.text,
                        );

                        if (loginRes['status'] != true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password lama salah'),
                            ),
                          );
                          return;
                        }

                        final updateRes = await ApiService.updateUser(
                          id: widget.user.id,
                          username: '',
                          namaLengkap: '',
                          nipNisn: '',
                          role: null,
                          password: newPassC.text,
                        );

                        if (updateRes['status'] == 'success' ||
                            updateRes['status'] == true) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password berhasil diubah!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                          await ApiService.logout();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                updateRes['message'] ?? 'Gagal ubah password',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      } finally {
                        if (mounted) setStateDialog(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B82F6), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'avatar_${widget.user.id}',
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(Icons.person, size: 80, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.user.namaLengkap,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    widget.user.role.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  avatar: const Icon(Icons.shield, color: Colors.white),
                ),
                const SizedBox(height: 40),
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _profileItem(
                          Icons.person_outline,
                          'Username',
                          widget.user.username ?? '-',
                        ),
                        const Divider(),
                        _profileItem(
                          Icons.badge_outlined,
                          'NIP/NIK',
                          widget.user.nipNisn ?? '-',
                        ),
                        const Divider(),
                        _profileItem(
                          Icons.shield_outlined,
                          'Role',
                          widget.user.role.toUpperCase(),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _ubahPassword,
                            icon: const Icon(Icons.lock_reset_rounded),
                            label: const Text(
                              'Ubah Password',
                              style: TextStyle(fontSize: 18),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

```
```dart
// lib/pages/admin_user_list_page.dart (ENHANCED: Modern UI with neumorphic cards, subtle gradients, hero animations, improved search with debounce, empty state, consistent styling for seamless UX)
import 'package:flutter/material.dart';
import 'dart:async';
import '../api/api_service.dart';
import 'admin_user_detail_page.dart';

class AdminUserListPage extends StatefulWidget {
  const AdminUserListPage({super.key});

  @override
  State<AdminUserListPage> createState() => _AdminUserListPageState();
}

class _AdminUserListPageState extends State<AdminUserListPage>
    with TickerProviderStateMixin {
  bool _loading = true;
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  final TextEditingController _searchC = TextEditingController();
  Timer? _debounce;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _loadUsers();
    _searchC.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchC.removeListener(_onSearchChanged);
    _searchC.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _filterUsers);
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getUsers();
      final filtered = (data as List)
          .where(
            (u) =>
                (u['role']?.toString().toLowerCase() ?? '') == 'user' &&
                (u['id']?.toString().isNotEmpty ?? false),
          )
          .toList();

      setState(() {
        _users = filtered;
        _filteredUsers = filtered
          ..sort(
            (a, b) => (a['nama_lengkap'] ?? '').toString().compareTo(
              (b['nama_lengkap'] ?? ''),
            ),
          );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat user: $e',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterUsers() {
    final query = _searchC.text.toLowerCase().trim();
    setState(() {
      _filteredUsers =
          query.isEmpty
                ? _users
                : _users.where((u) {
                    final nama = (u['nama_lengkap'] ?? u['nama'] ?? '')
                        .toString()
                        .toLowerCase();
                    final username = (u['username'] ?? '')
                        .toString()
                        .toLowerCase();
                    return nama.contains(query) || username.contains(query);
                  }).toList()
            ..sort(
              (a, b) => (a['nama_lengkap'] ?? '').toString().compareTo(
                (b['nama_lengkap'] ?? ''),
              ),
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Kelola User Presensi',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          Hero(
            tag: 'refresh_users',
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 28),
              onPressed: _loadUsers,
            ),
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.9),
                const Color(0xFF3B82F6).withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF3B82F6).withOpacity(0.05), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 100,
                  16,
                  16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.95)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextField(
                          controller: _searchC,
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau username...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: const Color(0xFF6B7280),
                              size: 24,
                            ),
                            suffixIcon: _searchC.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      color: Color(0xFF6B7280),
                                    ),
                                    onPressed: () {
                                      _searchC.clear();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3B82F6).withOpacity(0.05),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: ${_filteredUsers.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            Icon(
                              Icons.people_outline_rounded,
                              color: const Color(0xFF3B82F6),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF3B82F6),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        color: const Color(0xFF3B82F6),
                        child: _filteredUsers.isEmpty
                            ? Center(
                                child: Container(
                                  margin: const EdgeInsets.all(40),
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF3B82F6,
                                        ).withOpacity(0.05),
                                        Colors.white,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF3B82F6,
                                      ).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _searchC.text.isNotEmpty
                                            ? Icons.search_off_rounded
                                            : Icons.people_outline_rounded,
                                        size: 80,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        _searchC.text.isNotEmpty
                                            ? 'Tidak ditemukan user'
                                            : 'Belum ada user',
                                        style: const TextStyle(
                                          // fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (_searchC.text.isEmpty)
                                        Text(
                                          'Tambahkan user baru untuk memulai',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: const Color(0xFF9CA3AF),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _filteredUsers.length,
                                itemBuilder: (ctx, i) {
                                  final u = _filteredUsers[i];
                                  final nama =
                                      u['nama_lengkap'] ??
                                      u['nama'] ??
                                      'Unknown';
                                  final username = u['username'] ?? '';
                                  final nip = u['nip_nisn']?.toString() ?? '';
                                  final userId = u['id'].toString();

                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.white.withOpacity(0.95),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Hero(
                                      tag: 'user_${userId}',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AdminUserDetailPage(
                                                    userId: userId,
                                                    userName: nama,
                                                  ),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 60,
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        const Color(
                                                          0xFF3B82F6,
                                                        ).withOpacity(0.1),
                                                        const Color(
                                                          0xFF3B82F6,
                                                        ).withOpacity(0.05),
                                                      ],
                                                    ),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF3B82F6,
                                                      ).withOpacity(0.2),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      username.isNotEmpty
                                                          ? username[0]
                                                                .toUpperCase()
                                                          : 'U',
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF3B82F6,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        nama,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        'Username: $username',
                                                        style: TextStyle(
                                                          color: const Color(
                                                            0xFF6B7280,
                                                          ),
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      if (nip.isNotEmpty)
                                                        Text(
                                                          'NIP/NIK: $nip',
                                                          style: TextStyle(
                                                            color: const Color(
                                                              0xFF6B7280,
                                                            ),
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  color: const Color(
                                                    0xFF6B7280,
                                                  ),
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

```
```dart
// lib/pages/admin_user_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class AdminUserDetailPage extends StatefulWidget {
  const AdminUserDetailPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  bool _loading = true;
  List<dynamic> _history = [];
  List<dynamic> _waitingPresensi = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final historyData = await ApiService.getUserHistory(widget.userId);
      if (mounted) {
        setState(() {
          _history = historyData ?? [];
          _history.sort(
            (a, b) =>
                DateTime.parse(
                  b['created_at'] ?? DateTime.now().toIso8601String(),
                ).compareTo(
                  DateTime.parse(
                    a['created_at'] ?? DateTime.now().toIso8601String(),
                  ),
                ),
          );
        });
      }

      final allPresensi = await ApiService.getAllPresensi();
      final waiting = allPresensi
          .where(
            (p) =>
                p['user_id'].toString() == widget.userId &&
                (p['status'] ?? '').toString() == 'Waiting',
          )
          .toList();

      if (mounted) setState(() => _waitingPresensi = waiting);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      final res = await ApiService.updatePresensiStatus(id: id, status: status);
      if (!mounted) return;

      final message = res['message'] ?? 'Status diperbarui';
      final isSuccess = res['status'] == true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      if (isSuccess) _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showFullPhoto(String? url) {
    if (url == null || url.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: 'photo_${url.hashCode}',
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_rounded, size: 80),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullDokumen(String? url) {
    if (url == null || url.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_rounded,
                    size: 28,
                    color: Color(0xFFF59E0B),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Dokumen',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.insert_drive_file_outlined,
                              size: 64,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Tidak dapat menampilkan dokumen',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Tutup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getJenisIcon(String jenis) {
    switch (jenis) {
      case 'Masuk':
      case 'Penugasan_Masuk':
        return Icons.login_rounded;
      case 'Pulang':
      case 'Penugasan_Pulang':
        return Icons.logout_rounded;
      case 'Izin':
        return Icons.sick_rounded;
      case 'Pulang Cepat':
        return Icons.fast_forward_rounded;
      case 'Penugasan_Full':
        return Icons.assignment_turned_in_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _getJenisColor(String jenis) {
    switch (jenis) {
      case 'Masuk':
      case 'Penugasan_Masuk':
        return const Color(0xFF10B981);
      case 'Pulang':
      case 'Penugasan_Pulang':
        return const Color(0xFFF59E0B);
      case 'Izin':
        return const Color(0xFFEF4444);
      case 'Pulang Cepat':
        return const Color(0xFF3B82F6);
      case 'Penugasan_Full':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return const Color(0xFF10B981);
      case 'Ditolak':
        return const Color(0xFFEF4444);
      default: // Waiting
        return const Color(0xFFF59E0B);
    }
  }

  // Card yang dipakai di kedua tab
  Widget _buildPresensiCard(
    Map<String, dynamic> item, {
    bool showActions = false,
  }) {
    final baseUrl = ApiService.baseUrl;
    final fotoUrl = item['selfie']?.toString().isNotEmpty == true
        ? '$baseUrl/selfie/${item['selfie']}'
        : null;
    final dokumenUrl = item['dokumen']?.toString().isNotEmpty == true
        ? '$baseUrl/dokumen/${item['dokumen']}'
        : null;

    final jenisColor = _getJenisColor(item['jenis'] ?? '');
    final status = item['status'] ?? 'Waiting';
    final statusColor = _getStatusColor(status);

    final created = DateTime.parse(
      item['created_at'] ?? DateTime.now().toIso8601String(),
    );
    final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(created);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris utama: icon + foto (opsional) + info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        jenisColor.withOpacity(0.1),
                        jenisColor.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: jenisColor.withOpacity(0.2)),
                  ),
                  child: Icon(
                    _getJenisIcon(item['jenis'] ?? ''),
                    color: jenisColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                if (fotoUrl != null)
                  Hero(
                    tag: 'photo_${fotoUrl.hashCode}',
                    child: GestureDetector(
                      onTap: () => _showFullPhoto(fotoUrl),
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(fotoUrl, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['jenis'] ?? 'Tidak ada jenis',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tanggal: $formattedDate',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keterangan: ${item['keterangan'] ?? '-'}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item['informasi']?.toString().isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Info: ${item['informasi']}',
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Dokumen badge (jika ada) → dipindah ke bawah agar tidak overflow
            if (dokumenUrl != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Hero(
                  tag: 'dokumen_${dokumenUrl.hashCode}',
                  child: GestureDetector(
                    onTap: () => _showFullDokumen(dokumenUrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attachment_rounded,
                            size: 18,
                            color: Color(0xFFF59E0B),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Dokumen',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withOpacity(0.1), Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == 'Disetujui'
                        ? Icons.check_circle
                        : status == 'Ditolak'
                        ? Icons.cancel
                        : Icons.pending,
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Status: $status',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Tombol aksi hanya untuk tab Waiting
            if (showActions) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _updateStatus(item['id'].toString(), 'Disetujui'),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Setujui'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _updateStatus(item['id'].toString(), 'Ditolak'),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Tolak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_loading && _history.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Color(0xFF3B82F6),
        ),
      );
    }
    if (_history.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF3B82F6).withOpacity(0.05), Colors.white],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                size: 80,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(height: 20),
              Text(
                'Belum ada riwayat presensi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Riwayat akan muncul setelah presensi tercatat',
                style: TextStyle(color: Color(0xFF9CA3AF)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF3B82F6),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (_, i) =>
            _buildPresensiCard(_history[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _buildWaitingTab() {
    if (_loading && _waitingPresensi.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Color(0xFF3B82F6),
        ),
      );
    }
    if (_waitingPresensi.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF3B82F6).withOpacity(0.05), Colors.white],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pending_actions_rounded,
                size: 80,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(height: 20),
              Text(
                'Tidak ada presensi menunggu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Semua presensi telah diproses',
                style: TextStyle(color: Color(0xFF9CA3AF)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF3B82F6),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _waitingPresensi.length,
        itemBuilder: (_, i) => _buildPresensiCard(
          _waitingPresensi[i] as Map<String, dynamic>,
          showActions: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.userName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          Hero(
            tag: 'refresh_detail',
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 28),
              onPressed: _loadData,
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.9),
                const Color(0xFF3B82F6).withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: const Color(0xFF3B82F6).withOpacity(0.8),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.2),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(
                  icon: Icon(Icons.history_rounded, size: 24),
                  text: 'Riwayat',
                ),
                Tab(
                  icon: Icon(Icons.pending_actions_rounded, size: 24),
                  text: 'Waiting',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF3B82F6).withOpacity(0.05), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _loading && _history.isEmpty && _waitingPresensi.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF3B82F6),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 140,
                    16,
                    16,
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildHistoryTab(), _buildWaitingTab()],
                  ),
                ),
        ),
      ),
    );
  }
}

```
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';

class AdminPresensiPage extends StatefulWidget {
  const AdminPresensiPage({super.key});

  @override
  State<AdminPresensiPage> createState() => _AdminPresensiPageState();
}

class _AdminPresensiPageState extends State<AdminPresensiPage>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  List<dynamic> _items = [];
  String _filterStatus = 'All';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _loadPresensi();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadPresensi() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAllPresensi();
      setState(() {
        _items = data ?? [];
        _items.sort(
          (a, b) =>
              DateTime.parse(
                b['created_at'] ?? DateTime.now().toIso8601String(),
              ).compareTo(
                DateTime.parse(
                  a['created_at'] ?? DateTime.now().toIso8601String(),
                ),
              ),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal ambil data presensi: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredItems {
    if (_filterStatus == 'All') return _items;
    return _items
        .where((item) => (item['status'] ?? '') == _filterStatus)
        .toList();
  }

  String _shortenText(String text, {int maxLength = 50}) {
    if (text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  IconData _getJenisIconData(String jenis) {
    switch (jenis) {
      case 'Masuk':
      case 'Penugasan_Masuk':
        return Icons.login_rounded;
      case 'Pulang':
      case 'Penugasan_Pulang':
        return Icons.logout_rounded;
      case 'Izin':
        return Icons.sick_rounded;
      case 'Pulang Cepat':
        return Icons.fast_forward_rounded;
      case 'Penugasan':
      case 'Penugasan_Full':
        return Icons.assignment_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _getJenisColor(String jenis) {
    switch (jenis) {
      case 'Masuk':
      case 'Penugasan_Masuk':
        return Colors.green;
      case 'Pulang':
      case 'Penugasan_Pulang':
        return Colors.orange;
      case 'Izin':
        return Colors.red;
      case 'Pulang Cepat':
        return Colors.blue;
      case 'Penugasan':
      case 'Penugasan_Full':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showDetailDialog(dynamic item) async {
    final status = item['status'] ?? 'Waiting';
    final baseUrl = ApiService.baseUrl;
    final selfie = item['selfie'];
    final dokumen = item['dokumen'];
    final fotoUrl = selfie != null && selfie.toString().isNotEmpty
        ? '$baseUrl/selfie/$selfie'
        : null;
    final dokumenUrl = dokumen != null && dokumen.toString().isNotEmpty
        ? '$baseUrl/dokumen/$dokumen'
        : null;
    final created = DateTime.parse(
      item['created_at'] ?? DateTime.now().toIso8601String(),
    );
    final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(created);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 700, maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Dialog
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == 'Disetujui'
                          ? Icons.check_circle
                          : status == 'Ditolak'
                          ? Icons.cancel
                          : Icons.pending,
                      color: status == 'Disetujui'
                          ? Colors.green
                          : status == 'Ditolak'
                          ? Colors.red
                          : Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['nama_lengkap'] ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item['jenis'] ?? '-',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Tanggal',
                        formattedDate,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.description,
                        'Keterangan',
                        item['keterangan'] ?? '-',
                      ),
                      if (item['informasi'] != null &&
                          item['informasi'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildInfoRow(
                            Icons.info_outline,
                            'Informasi Penugasan',
                            item['informasi'],
                          ),
                        ),
                      if (fotoUrl != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Foto Presensi:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showFullPhoto(fotoUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              fotoUrl,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              errorBuilder: (_, __, ___) => Container(
                                height: 220,
                                color: Colors.grey[200],
                                child: const Icon(Icons.error, size: 50),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Tidak ada foto presensi',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (dokumenUrl != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Dokumen Penugasan:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showFullDokumen(dokumenUrl),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.attachment_rounded,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Lihat Dokumen (${item['dokumen']})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              (status == 'Disetujui'
                                      ? Colors.green
                                      : status == 'Ditolak'
                                      ? Colors.red
                                      : Colors.orange)
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              status == 'Disetujui'
                                  ? Icons.check_circle
                                  : status == 'Ditolak'
                                  ? Icons.cancel
                                  : Icons.pending,
                              color: status == 'Disetujui'
                                  ? Colors.green
                                  : status == 'Ditolak'
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Status Saat Ini: $status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == 'Disetujui'
                                    ? Colors.green
                                    : status == 'Ditolak'
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Tombol Aksi
              if (status == 'Waiting')
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateStatus(item['id'].toString(), 'Disetujui');
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Setujui'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateStatus(item['id'].toString(), 'Ditolak');
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Tolak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFullPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka dokumen')),
        );
    }
  }

  void _showFullDokumen(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber[600],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dokumen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.open_in_browser,
                            color: Colors.white,
                          ),
                          onPressed: () => _launchInBrowser(url),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.insert_drive_file,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Dokumen tidak dapat ditampilkan di sini.',
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('Buka di Browser'),
                            onPressed: () => _launchInBrowser(url),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      final res = await ApiService.updatePresensiStatus(
        id: id,
        status: newStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message'] ??
                (res['status'] == true
                    ? 'Status berhasil diupdate'
                    : 'Gagal update status'),
          ),
          backgroundColor: res['status'] == true
              ? Colors.green.shade600
              : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
      _loadPresensi();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Persetujuan Presensi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Text(
                    _filterStatus,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: cs.surface,
            itemBuilder: (_) => [
              'All',
              'Waiting',
              'Disetujui',
              'Ditolak',
            ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
            onSelected: (v) => setState(() => _filterStatus = v),
          ),
          const SizedBox(width: 12),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.9),
                cs.primary.withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary.withOpacity(0.05), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.history, size: 28, color: Colors.blue),
                        Text(
                          'Total: ${_filteredItems.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.people, size: 28, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 4),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPresensi,
                        child: _filteredItems.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.pending_actions_rounded,
                                      size: 100,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Tidak ada presensi ${_filterStatus == 'All' ? '' : _filterStatus.toLowerCase()}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tarik ke bawah untuk refresh',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _filteredItems.length,
                                itemBuilder: (_, i) {
                                  final item = _filteredItems[i];
                                  final status = item['status'] ?? 'Waiting';
                                  final statusColor = status == 'Disetujui'
                                      ? Colors.green
                                      : status == 'Ditolak'
                                      ? Colors.red
                                      : Colors.orange;
                                  final jenisColor = _getJenisColor(
                                    item['jenis'] ?? '',
                                  );
                                  final created = DateTime.parse(
                                    item['created_at'] ??
                                        DateTime.now().toIso8601String(),
                                  );
                                  final formattedDate = DateFormat(
                                    'dd MMM',
                                  ).format(created);
                                  final fotoUrl =
                                      item['selfie'] != null &&
                                          item['selfie'].toString().isNotEmpty
                                      ? '${ApiService.baseUrl}/selfie/${item['selfie']}'
                                      : null;
                                  final informasi =
                                      item['informasi']?.toString() ?? '';

                                  return Card(
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _showDetailDialog(item),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 28,
                                              backgroundColor: jenisColor
                                                  .withOpacity(0.15),
                                              child: Icon(
                                                _getJenisIconData(
                                                  item['jenis'] ?? '',
                                                ),
                                                color: jenisColor,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${item['nama_lengkap'] ?? '-'} - ${item['jenis'] ?? '-'}',
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Tgl: $formattedDate',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Ket: ${_shortenText(item['keterangan'] ?? '-')}',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  if (informasi.isNotEmpty)
                                                    Text(
                                                      'Info: ${_shortenText(informasi)}',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color: statusColor
                                                          .withOpacity(0.4),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                if (fotoUrl != null) ...[
                                                  const SizedBox(height: 8),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _showFullPhoto(fotoUrl),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: Image.network(
                                                        fotoUrl,
                                                        width: 50,
                                                        height: 50,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder:
                                                            (
                                                              _,
                                                              child,
                                                              progress,
                                                            ) => progress == null
                                                            ? child
                                                            : Container(
                                                                width: 50,
                                                                height: 50,
                                                                color: Colors
                                                                    .grey[300],
                                                                child: const Center(
                                                                  child: CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                                ),
                                                              ),
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => Container(
                                                              width: 50,
                                                              height: 50,
                                                              color: Colors
                                                                  .grey[300],
                                                              child: const Icon(
                                                                Icons
                                                                    .broken_image,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 8),
                                                Icon(
                                                  status == 'Waiting'
                                                      ? Icons
                                                            .arrow_forward_ios_rounded
                                                      : (status == 'Disetujui'
                                                            ? Icons.check_circle
                                                            : Icons.cancel),
                                                  color: status == 'Waiting'
                                                      ? Colors.orange
                                                      : statusColor,
                                                  size: 28,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

```
```dart
class UserModel {
  final String id;
  final String username;
  final String namaLengkap;
  final String nipNisn;
  final String role;

  UserModel({
    required this.id,
    required this.username,
    required this.namaLengkap,
    required this.nipNisn,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? '',
      nipNisn: json['nip_nisn'] ?? '',
      role: json['role'] ?? 'user',
    );
  }
}

```
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform, SocketException;
import '../utils/encryption.dart'; // Sesuaikan path jika berbeda

class ApiService {
  // Ganti dengan URL ngrok atau production kamu
  static const String baseUrl =
      // "http://192.168.0.108/backendapk/";
      // "https://nonlitigious-alene-uninfinitely.ngrok-free.dev/";
      "https://103.210.35.189:3001/";
  // static const String baseUrl = "https://103.210.35.189:3001/";

  // API Key harus sama persis dengan yang di config.php / proteksi.php
  static const String _apiKey = 'Skaduta2025!@#SecureAPIKey1234567890';

  /// Get device ID untuk binding (skip untuk Windows/desktop)
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isWindows) {
        return '';
      }
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? '';
      }
      return '';
    } catch (e) {
      print('Error getting device ID: $e');
      return '';
    }
  }

  /// Header umum untuk semua request
  static Future<Map<String, String>> _getHeaders({
    bool withToken = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    return {
      'Content-Type': 'application/json',
      'X-App-Key': _apiKey,
      'ngrok-skip-browser-warning': 'true',
      if (withToken && token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Dekripsi response kalau pakai enkripsi
  static Map<String, dynamic> _safeDecrypt(http.Response response) {
    try {
      print("=== RESPONSE DEBUG ===");
      print("STATUS CODE: ${response.statusCode}");
      print("RAW BODY: '${response.body}'");
      print("======================");

      if (response.body.isEmpty) {
        return {"status": false, "message": "Server mengirim response kosong"};
      }

      final body = jsonDecode(response.body);
      if (body['encrypted_data'] != null) {
        final decryptedJson = ApiEncryption.decrypt(body['encrypted_data']);
        return jsonDecode(decryptedJson);
      }
      return body as Map<String, dynamic>;
    } catch (e) {
      print("GAGAL PARSE JSON: $e");
      return {"status": false, "message": "Gagal membaca respons dari server"};
    }
  }

  /// Wrapper aman untuk semua request HTTP
  static Future<Map<String, dynamic>> _safeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final res = await request().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw SocketException('Connection timed out');
        },
      );

      if (res.statusCode == 401) {
        return {
          "status": false,
          "message": "Username atau password salah / API Key invalid",
        };
      } else if (res.statusCode == 403) {
        return {
          "status": false,
          "message": "Akun terikat ke perangkat lain. Hubungi admin.",
        };
      } else if (res.statusCode == 404) {
        return {
          "status": false,
          "message": "Endpoint tidak ditemukan (404). Periksa URL server.",
        };
      } else if (res.statusCode != 200) {
        return {
          "status": false,
          "message": "Server error (${res.statusCode}). Coba lagi nanti.",
        };
      }
      return _safeDecrypt(res);
    } on SocketException catch (_) {
      return {
        "status": false,
        "message": "Kamu sedang offline. Periksa koneksi internetmu.",
      };
    } on http.ClientException catch (_) {
      return {"status": false, "message": "Tidak dapat terhubung ke server."};
    } catch (e) {
      print("UNEXPECTED API ERROR: $e");
      return {"status": false, "message": "Terjadi kesalahan: $e"};
    }
  }

  // ================== GET DATA ==================
  static Future<List<dynamic>> getUsers() async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.get(Uri.parse("$baseUrl/get_users.php"), headers: headers),
    );
    if (result['status'] == false) return [];
    return List<dynamic>.from(result['data'] ?? []);
  }

  static Future<List<dynamic>> getUserHistory(String userId) async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.get(
        Uri.parse("$baseUrl/absen_history.php?user_id=$userId"),
        headers: headers,
      ),
    );
    if (result['status'] == false) return [];
    return List<dynamic>.from(result['data'] ?? []);
  }

  static Future<List<dynamic>> getAllPresensi() async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.get(
        Uri.parse("$baseUrl/absen_admin_list.php"),
        headers: headers,
      ),
    );
    if (result['status'] == false) return [];
    return List<dynamic>.from(result['data'] ?? []);
  }

  static Future<List<dynamic>> getRekap({String? month, String? year}) async {
    final headers = await _getHeaders();
    var url = "$baseUrl/presensi_rekap.php";
    if (month != null && year != null) url += "?month=$month&year=$year";
    final result = await _safeRequest(
      () => http.get(Uri.parse(url), headers: headers),
    );
    if (result['status'] == false) return [];
    return List<dynamic>.from(result['data'] ?? []);
  }

  // ================== LOGIN ==================
  static Future<Map<String, dynamic>> login({
    required String input,
    required String password,
  }) async {
    final deviceId = await getDeviceId();

    final headers = await _getHeaders(withToken: false);
    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/login.php"),
        headers: headers,
        body: jsonEncode({
          "username": input,
          "password": password,
          "device_id": deviceId,
        }),
      ),
    );

    if (result['status'] == true && result['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', result['token']);
      await prefs.setString('user_id', result['user']['id'].toString());
      await prefs.setString('user_name', result['user']['nama_lengkap']);
      await prefs.setString('user_role', result['user']['role']);
      await prefs.setString('device_id', deviceId);
    }
    return result;
  }

  // ================== TAMBAH USER BARU (pakai update_user.php tanpa id) ==================
  static Future<Map<String, dynamic>> addUser({
    required String username,
    required String namaLengkap,
    required String password,
    String? nipNisn,
    String role = 'user',
    String status = 'Karyawan',
  }) async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/update_user.php"),
        headers: headers,
        body: jsonEncode({
          "username": username,
          "nama_lengkap": namaLengkap,
          "password": password,
          "nip_nisn": nipNisn ?? '',
          "role": role,
          "status": status,
          // id sengaja tidak dikirim → server mode tambah user
        }),
      ),
    );
    return result;
  }

  // ================== RESET DEVICE ID ==================
  static Future<Map<String, dynamic>> resetDeviceId(String userId) async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/update_user.php"),
        headers: headers,
        body: jsonEncode({"id": userId, "reset_device": true}),
      ),
    );
    return result;
  }

  // ================== LOGOUT ==================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ================== CEK LOGIN STATUS ==================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  // ================== GET USER SAAT INI ==================
  static Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;
    return {
      'id': prefs.getString('user_id') ?? '',
      'nama_lengkap': prefs.getString('user_name') ?? '',
      'role': prefs.getString('user_role') ?? 'user',
    };
  }

  // ================== SUBMIT PRESENSI ==================
  static Future<Map<String, dynamic>> submitPresensi({
    required String userId,
    required String jenis,
    required String keterangan,
    required String informasi,
    required String dokumenBase64,
    required String latitude,
    required String longitude,
    required String base64Image,
  }) async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/absen.php"),
        headers: headers,
        body: jsonEncode({
          "userId": userId,
          "jenis": jenis,
          "keterangan": keterangan,
          "informasi": informasi,
          "dokumenBase64": dokumenBase64,
          "latitude": latitude,
          "longitude": longitude,
          "base64Image": base64Image,
        }),
      ),
    );
    return result;
  }

  // ================== APPROVE PRESENSI ==================
  static Future<Map<String, dynamic>> updatePresensiStatus({
    required String id,
    required String status,
  }) async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/presensi_approve.php"),
        headers: headers,
        body: jsonEncode({"id": id.trim(), "status": status}),
      ),
    );
    return result;
  }

  // ================== DELETE USER ==================
  static Future<Map<String, dynamic>> deleteUser(String id) async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/delete_user.php"),
        headers: headers,
        body: jsonEncode({"id": id}),
      ),
    );
    return result;
  }

  // ================== UPDATE USER (edit biasa) ==================
  static Future<Map<String, dynamic>> updateUser({
    required String id,
    required String username,
    required String namaLengkap,
    String? nipNisn,
    String? role,
    String? password,
  }) async {
    final headers = await _getHeaders();
    final body = {
      "id": id,
      "username": username,
      "nama_lengkap": namaLengkap,
      if (nipNisn != null && nipNisn.isNotEmpty) "nip_nisn": nipNisn,
      if (role != null) "role": role,
      if (password != null && password.isNotEmpty) "password": password,
    };

    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/update_user.php"),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    return result;
  }
}

```
Nah ini code untuk Aplikasi mobile 