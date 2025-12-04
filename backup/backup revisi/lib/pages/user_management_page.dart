// lib/pages/user_management_page.dart
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  bool _loading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getUsers();
      setState(() => _users = data);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteUser(String id, String role) async {
    if (role == 'superadmin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak boleh hapus superadmin')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus User'),
        content: const Text('Yakin ingin menghapus?'),
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
    final namaC = TextEditingController(text: user['nama_lengkap'] ?? '');
    final passC = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit User',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameC,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: namaC,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passC,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru (kosongkan jika tidak ganti)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final res = await ApiService.updateUser(
                      id: user['id'].toString(),
                      username: usernameC.text.trim(),
                      namaLengkap: namaC.text.trim(),
                      password: passC.text.isEmpty ? null : passC.text.trim(),
                    );
                    Navigator.pop(ctx, res['status'] == 'success');
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  final u = _users[i];
                  final role = (u['role'] ?? 'user').toString().toLowerCase();
                  final badgeColor = role == 'superadmin'
                      ? Colors.red
                      : role == 'admin'
                      ? Colors.blue
                      : Colors.green;
                  final label = role == 'superadmin'
                      ? 'SUPER'
                      : role == 'admin'
                      ? 'ADMIN'
                      : 'USER';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: badgeColor.withOpacity(0.2),
                        child: Text(
                          (u['username'] ?? '?')[0].toUpperCase(),
                          style: TextStyle(color: badgeColor),
                        ),
                      ),
                      title: Text(
                        u['nama_lengkap'] ?? 'Tanpa Nama',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(u['username'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(label),
                            backgroundColor: badgeColor.withOpacity(0.2),
                            labelStyle: TextStyle(color: badgeColor),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editUser(u),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteUser(u['id'].toString(), role),
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
