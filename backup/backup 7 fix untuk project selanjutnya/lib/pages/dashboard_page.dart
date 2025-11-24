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
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(
                  user.role.toUpperCase(),
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: cs.primary.withOpacity(0.15),
                side: BorderSide(color: cs.primary),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              'Halo, ${user.namaLengkap}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Selamat datang di sistem presensi Skaduta',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            if (user.role == 'user') _buildUserSection(context),
            if (user.role == 'admin') _buildAdminSection(context),
            if (user.role == 'superadmin') _buildSuperAdminSection(context),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
      children: [
        _card(
          icon: Icons.verified_outlined,
          title: 'Persetujuan Presensi',
          subtitle: 'Setujui / tolak presensi user',
          onTap: () {
            Navigator.pushNamed(context, '/admin-presensi');
          },
        ),
      ],
    );
  }

  Widget _buildSuperAdminSection(BuildContext context) {
    return Column(
      children: [
        _card(
          icon: Icons.supervisor_account_outlined,
          title: 'Kelola User & Admin',
          subtitle:
              'CRUD akun user dan admin, bantu jika ada yang lupa password',
          onTap: () {
            Navigator.pushNamed(context, '/user-management');
          },
        ),
        _card(
          icon: Icons.verified_outlined,
          title: 'Persetujuan Presensi',
          subtitle: 'Setujui / tolak presensi user',
          onTap: () {
            Navigator.pushNamed(context, '/admin-presensi');
          },
        ),
      ],
    );
  }
}
