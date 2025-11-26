import 'package:flutter/material.dart';
import '../api/api_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  bool _isLoading = false;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getUsers();
      setState(() => _users = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat user: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String id, String role) async {
    if (role == 'superadmin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak boleh menghapus superadmin')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus User'),
        content: const Text('Yakin ingin menghapus user ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ApiService.deleteUser(id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'User dihapus')));
    _loadUsers();
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final usernameC = TextEditingController(text: user['username']);
    final namaC = TextEditingController(text: user['nama_lengkap']);
    final passwordC = TextEditingController(); // Baru untuk password

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit User',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameC,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: namaC,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordC,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru (kosongkan jika tidak ganti)',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final res = await ApiService.updateUser(
                      id: user['id'].toString(),
                      username: usernameC.text.trim(),
                      namaLengkap: namaC.text.trim(),
                      password: passwordC.text.trim(), // Tambah password
                    );
                    final ok = res['status'] == 'success';
                    if (ctx.mounted) {
                      Navigator.pop(ctx, ok);
                    }
                  },
                  child: const Text('Simpan Perubahan'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      _loadUsers();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User diperbarui')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola User & Admin'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _users.length,
                itemBuilder: (ctx, index) {
                  final u = _users[index];
                  final role = (u['role'] ?? '').toString();

                  Color badgeColor;
                  String roleLabel;
                  switch (role) {
                    case 'admin':
                      badgeColor = Colors.blue;
                      roleLabel = 'ADMIN';
                      break;
                    case 'superadmin':
                      badgeColor = Colors.red;
                      roleLabel = 'SUPERADMIN';
                      break;
                    default:
                      badgeColor = Colors.green;
                      roleLabel = 'USER';
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: badgeColor.withOpacity(0.2),
                        child: Text(
                          (u['username'] ?? '?')
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(color: badgeColor),
                        ),
                      ),
                      title: Text(u['nama_lengkap'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['username'] ?? ''),
                          if ((u['nip_nisn'] ?? '').toString().isNotEmpty)
                            Text(
                              'NIP/NISN: ${u['nip_nisn']}',
                              style: const TextStyle(fontSize: 11),
                            ),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editUser(u),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                _deleteUser(u['id'].toString(), role),
                            color: cs.error,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
