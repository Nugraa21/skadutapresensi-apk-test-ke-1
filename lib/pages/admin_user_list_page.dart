import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'admin_user_detail_page.dart'; // Pastiin file ini ada

class AdminUserListPage extends StatefulWidget {
  const AdminUserListPage({super.key});

  @override
  State<AdminUserListPage> createState() => _AdminUserListPageState();
}

class _AdminUserListPageState extends State<AdminUserListPage> {
  bool _loading = false;
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
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getUsers();
      if (data == null || data.isEmpty) {
        setState(() {
          _users = [];
          _filteredUsers = [];
        });
        return;
      }
      // Filter hanya user biasa, dengan null check ketat
      final filteredUsers = data.where((u) {
        final role = u['role']?.toString().toLowerCase() ?? '';
        final id = u['id']?.toString();
        final nama = u['nama_lengkap'] ?? u['nama'] ?? '';
        return role == 'user' && id != null && id.isNotEmpty && nama.isNotEmpty;
      }).toList();
      setState(() {
        _users = filteredUsers;
        _filteredUsers = filteredUsers;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat list user: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterUsers() {
    final query = _searchC.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _filteredUsers = _users);
      return;
    }
    setState(() {
      _filteredUsers = _users.where((u) {
        final nama = (u['nama_lengkap'] ?? u['nama'] ?? '').toLowerCase();
        final username = (u['username'] ?? '').toLowerCase();
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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar - Bagian ini aman
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchC,
              decoration: InputDecoration(
                hintText: 'Cari user berdasarkan nama atau username...',
                prefixIcon: Icon(Icons.search, color: cs.primary),
                suffixIcon: _searchC.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchC.clear();
                          _filterUsers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary.withOpacity(0.5)),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          // Expanded - INI BAGIAN YANG SERING ERROR, UDAH FIX KURUNG & KOMA
          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat users...'),
                      ],
                    ),
                  )
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
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchC.text.isNotEmpty
                                      ? 'Tidak ditemukan user'
                                      : 'Belum ada user terdaftar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_searchC.text.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _loadUsers,
                                    child: const Text('Refresh'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredUsers.length,
                            separatorBuilder: (ctx, i) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final u = _filteredUsers[i];
                              final nama =
                                  u['nama_lengkap'] ?? u['nama'] ?? 'Unknown';
                              final username = u['username'] ?? '';
                              final nip = u['nip_nisn']?.toString() ?? '';
                              final userId = u['id']?.toString() ?? '';

                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: userId.isNotEmpty
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AdminUserDetailPage(
                                                    userId: userId,
                                                    userName: nama,
                                                  ),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      // Row mulai di sini
                                      children: [
                                        // Children list mulai
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: cs.primary
                                              .withOpacity(0.1),
                                          child: Text(
                                            username.isNotEmpty
                                                ? username[0].toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: cs.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          // Expanded mulai - INI LINE 127 APPROX
                                          child: Column(
                                            // Child Expanded: Column
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Column children
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
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              if (nip.isNotEmpty)
                                                Text(
                                                  'NIP/NISN: $nip',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                            ], // Tutup Column children
                                          ), // Tutup child Expanded
                                        ), // Tutup Expanded - KOMA INI PENTING!
                                        Icon(
                                          // Item selanjutnya di Row
                                          Icons.arrow_forward_ios,
                                          color: cs.primary,
                                          size: 20,
                                        ),
                                      ], // Tutup Row children
                                    ), // Tutup Padding child
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ), // Tutup Expanded utama
        ], // Tutup Column children
      ), // Tutup body Scaffold
    ); // Tutup Scaffold
  } // Tutup build method
}  // Tutup State class