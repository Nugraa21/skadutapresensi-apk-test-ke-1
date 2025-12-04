// lib/pages/admin_user_list_page.dart
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'admin_user_detail_page.dart';

class AdminUserListPage extends StatefulWidget {
  const AdminUserListPage({super.key});

  @override
  State<AdminUserListPage> createState() => _AdminUserListPageState();
}

class _AdminUserListPageState extends State<AdminUserListPage> {
  bool _loading = true;
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  final TextEditingController _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchC.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchC.removeListener(_filterUsers);
    _searchC.dispose();
    super.dispose();
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
        _filteredUsers = filtered;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat user: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterUsers() {
    final query = _searchC.text.toLowerCase().trim();
    setState(() {
      _filteredUsers = query.isEmpty
          ? _users
          : _users.where((u) {
              final nama = (u['nama_lengkap'] ?? u['nama'] ?? '')
                  .toString()
                  .toLowerCase();
              final username = (u['username'] ?? '').toString().toLowerCase();
              return nama.contains(query) || username.contains(query);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola User Presensi'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchC,
              decoration: InputDecoration(
                hintText: 'Cari nama atau username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchC.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchC.clear,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchC.text.isNotEmpty
                                      ? 'Tidak ditemukan'
                                      : 'Belum ada user',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (ctx, i) {
                              final u = _filteredUsers[i];
                              final nama =
                                  u['nama_lengkap'] ?? u['nama'] ?? 'Unknown';
                              final username = u['username'] ?? '';
                              final nip = u['nip_nisn']?.toString() ?? '';
                              final userId = u['id'].toString();

                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminUserDetailPage(
                                        userId: userId,
                                        userName: nama,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 32,
                                          backgroundColor: cs.primary
                                              .withOpacity(0.1),
                                          child: Text(
                                            username.isNotEmpty
                                                ? username[0].toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: cs.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nama,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Username: $username',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              if (nip.isNotEmpty)
                                                Text(
                                                  'NIP/NISN: $nip',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.grey,
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
    );
  }
}
