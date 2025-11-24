import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final String nama;
  final String role; // user / admin / superadmin

  const DashboardPage({super.key, required this.nama, required this.role});

  String get _roleLabel {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'superadmin':
        return 'Super Admin';
      default:
        return 'User (Guru/Karyawan)';
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (role == 'admin') {
      content = _adminContent();
    } else if (role == 'superadmin') {
      content = _superAdminContent();
    } else {
      content = _userContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(_roleLabel),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang, $nama',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _userContent() {
    return ListView(
      children: const [
        ListTile(
          leading: Icon(Icons.book),
          title: Text('Menu Absen / Presensi'),
          subtitle: Text('Contoh menu untuk User (Guru/Karyawan)'),
        ),
        ListTile(
          leading: Icon(Icons.assignment),
          title: Text('Lihat Jadwal'),
          subtitle: Text('Contoh fitur lain untuk user'),
        ),
      ],
    );
  }

  Widget _adminContent() {
    return ListView(
      children: const [
        ListTile(
          leading: Icon(Icons.group),
          title: Text('Kelola User'),
          subtitle: Text('Admin dapat mengatur data pengguna'),
        ),
        ListTile(
          leading: Icon(Icons.analytics),
          title: Text('Laporan Harian'),
          subtitle: Text('Lihat ringkasan aktivitas'),
        ),
      ],
    );
  }

  Widget _superAdminContent() {
    return ListView(
      children: const [
        ListTile(
          leading: Icon(Icons.security),
          title: Text('Pengaturan Sistem'),
          subtitle: Text('Super Admin dapat mengatur konfigurasi utama'),
        ),
        ListTile(
          leading: Icon(Icons.admin_panel_settings),
          title: Text('Kelola Admin'),
          subtitle: Text('Atur hak akses admin'),
        ),
      ],
    );
  }
}
