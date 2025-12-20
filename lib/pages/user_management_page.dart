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
                    labelText: 'NIP/NISN (opsional)',
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
                  labelText: 'NIP/NISN (opsional)',
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
                                            Text('NIP/NISN: ${u['nip_nisn']}'),
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
