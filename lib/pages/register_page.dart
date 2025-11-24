import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nipNisnController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'user'; // user / admin / superadmin
  bool _isKaryawan = false;
  bool _isLoading = false;
  bool _checkingRole = true;
  bool _adminExist = false;
  bool _superAdminExist = false;

  @override
  void initState() {
    super.initState();
    _checkRoles();
  }

  Future<void> _checkRoles() async {
    setState(() => _checkingRole = true);
    try {
      // cek admin
      final resAdmin = await http.get(Uri.parse('${baseUrl}check_admin.php'));
      final dataAdmin = jsonDecode(resAdmin.body);
      _adminExist = dataAdmin['exists'] == true;

      // cek superadmin
      final resSuper = await http.get(
        Uri.parse('${baseUrl}check_superadmin.php'),
      );
      final dataSuper = jsonDecode(resSuper.body);
      _superAdminExist = dataSuper['exists'] == true;
    } catch (e) {
      // kalau error ya sudah, backend nanti tetap mengamankan
    } finally {
      if (mounted) setState(() => _checkingRole = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${baseUrl}register.php');
      final response = await http.post(
        url,
        body: {
          'nama_lengkap': _namaController.text.trim(),
          'nip_nisn': _nipNisnController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': _selectedRole,
        },
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil, silakan login')),
        );
        Navigator.pop(context); // balik ke halaman login
      } else {
        _showSnackBar(data['message'] ?? 'Gagal register');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nipNisnController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleOptions = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: 'user',
        child: Text('User (Guru / Karyawan)'),
      ),
      if (!_adminExist)
        const DropdownMenuItem(value: 'admin', child: Text('Admin')),
      if (!_superAdminExist)
        const DropdownMenuItem(value: 'superadmin', child: Text('Super Admin')),
    ];

    // kalau role yang dipilih tidak ada lagi di option (misal admin sudah jadi)
    if (!roleOptions.any((e) => e.value == _selectedRole)) {
      _selectedRole = 'user';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Register Akun')),
      body: _checkingRole
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.person_add, size: 70),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Hanya relevan untuk role user
                    if (_selectedRole == 'user') ...[
                      CheckboxListTile(
                        value: _isKaryawan,
                        onChanged: (val) {
                          setState(() => _isKaryawan = val ?? false);
                        },
                        title: const Text('Saya Karyawan'),
                        subtitle: const Text(
                          'Jika karyawan, bisa isi ID sendiri (tidak wajib NIP/NISN resmi)',
                        ),
                      ),
                    ],

                    TextFormField(
                      controller: _nipNisnController,
                      decoration: InputDecoration(
                        labelText: _selectedRole == 'user'
                            ? 'NIP / NISN / ID'
                            : 'NIP / NISN / ID (untuk login)',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        // kalau user dan centang karyawan -> boleh kosong
                        if (_selectedRole == 'user' && _isKaryawan) {
                          return null;
                        }
                        if (v == null || v.isEmpty) {
                          return 'Wajib diisi untuk login';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (v.length < 4) {
                          return 'Minimal 4 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: roleOptions,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedRole = val;
                          if (_selectedRole != 'user') {
                            _isKaryawan = false;
                          }
                        });
                      },
                    ),
                    if (_adminExist || _superAdminExist) ...[
                      const SizedBox(height: 8),
                      if (_adminExist)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '⚠️ Admin sudah terdaftar',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      if (_superAdminExist)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '⚠️ Super Admin sudah terdaftar',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Daftar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
