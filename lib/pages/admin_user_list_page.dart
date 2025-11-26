// admin_user_list_page.dart - Halaman list user untuk admin (list user biasa, klik buat histori & konfirmasi)
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/user_model.dart';
import 'admin_user_detail_page.dart'; // Tambah import ini untuk navigasi ke AdminUserDetailPage

class AdminUserListPage extends StatefulWidget {
  const AdminUserListPage({super.key});

  @override
  State<AdminUserListPage> createState() => _AdminUserListPageState();
}

class _AdminUserListPageState extends State<AdminUserListPage> {
  bool _loading = false;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final data =
          await ApiService.getUsers(); // Asumsi return list user (filter role 'user' di PHP kalau perlu)
      // Filter hanya user biasa (bukan admin/superadmin)
      final filteredUsers = data
          .where((u) => (u['role'] ?? '') == 'user')
          .toList();
      setState(() => _users = filteredUsers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat list user: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola User Presensi'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: _users.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada user terdaftar',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _users.length,
                      itemBuilder: (ctx, i) {
                        final u = _users[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.withOpacity(0.2),
                              child: Text(
                                (u['username'] ?? '?')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                            title: Text(u['nama_lengkap'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Username: ${u['username'] ?? ''}'),
                                if ((u['nip_nisn'] ?? '').isNotEmpty)
                                  Text('NIP/NISN: ${u['nip_nisn']}'),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              // Navigasi ke detail user (histori + konfirmasi)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminUserDetailPage(
                                    userId: u['id'].toString(),
                                    userName: u['nama_lengkap'] ?? '',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
