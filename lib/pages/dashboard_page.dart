// pages/dashboard_page.dart (tetap sama)
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class DashboardPage extends StatelessWidget {
  final UserModel user;
  const DashboardPage({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(
                  user.role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: cs.primary.withOpacity(0.15),
                side: BorderSide(color: cs.primary, width: 1.5),
                avatar: Icon(Icons.shield, size: 16, color: cs.primary),
              ),
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary.withOpacity(0.05), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${user.namaLengkap}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Selamat datang di sistem presensi Skaduta',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),
                  const SizedBox(height: 30),
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
                  if (user.role == 'user') _buildUserSection(context),
                  if (user.role == 'admin') _buildAdminSection(context),
                  if (user.role == 'superadmin')
                    _buildSuperAdminSection(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: Colors.blue.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
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
          icon: Icons.fingerprint,
          title: 'Presensi',
          subtitle: 'Absen masuk / pulang dengan lokasi & selfie',
          onTap: () {
            Navigator.pushNamed(context, '/presensi', arguments: user);
          },
        ),
        _card(
          icon: Icons.history,
          title: 'Riwayat Presensi',
          subtitle: 'Lihat riwayat presensi kamu',
          onTap: () {
            Navigator.pushNamed(context, '/history', arguments: user);
          },
        ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          icon: Icons.list_alt,
          title: 'Kelola User Presensi',
          subtitle: 'Lihat list user, histori per user, dan konfirmasi absensi',
          onTap: () {
            Navigator.pushNamed(context, '/admin-user-list');
          },
        ),
        _card(
          icon: Icons.verified_outlined,
          title: 'Konfirmasi Absensi',
          subtitle: 'Setujui / tolak presensi user secara global',
          onTap: () {
            Navigator.pushNamed(context, '/admin-presensi');
          },
        ),
      ],
    );
  }

  Widget _buildSuperAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          icon: Icons.supervisor_account_outlined,
          title: 'Kelola User & Admin',
          subtitle: 'CRUD akun user dan admin, edit info, ganti password',
          onTap: () {
            Navigator.pushNamed(context, '/user-management');
          },
        ),
        _card(
          icon: Icons.list_alt,
          title: 'Kelola User Presensi',
          subtitle: 'Lihat list user, histori per user, dan konfirmasi absensi',
          onTap: () {
            Navigator.pushNamed(context, '/admin-user-list');
          },
        ),
        _card(
          icon: Icons.verified_outlined,
          title: 'Konfirmasi Absensi',
          subtitle: 'Setujui / tolak presensi user secara global',
          onTap: () {
            Navigator.pushNamed(context, '/admin-presensi');
          },
        ),
      ],
    );
  }
}
