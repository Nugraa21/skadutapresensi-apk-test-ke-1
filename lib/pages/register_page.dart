// pages/register_page.dart
// VERSI FINAL – FIX DROPDOWN BUG + TAMPILAN SUPER PREMIUM & RESPONSIVE

import 'package:flutter/material.dart';
import '../api/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameC = TextEditingController();
  final _namaC = TextEditingController();
  final _nipNisnC = TextEditingController();
  final _passwordC = TextEditingController();

  String _role = 'user';
  bool _isKaryawan = false;
  bool _isLoading = false;
  bool _obscure = true;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.register(
        username: _usernameC.text.trim(),
        namaLengkap: _namaC.text.trim(),
        nipNisn: _isKaryawan ? '' : _nipNisnC.text.trim(),
        password: _passwordC.text.trim(),
        role: _role,
        isKaryawan: _isKaryawan,
      );

      if (!mounted) return;

      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registrasi berhasil! Silakan login',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        _showSnack(res['message'] ?? 'Gagal mendaftar');
      }
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _usernameC.dispose();
    _namaC.dispose();
    _nipNisnC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Daftar Akun Baru',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary.withOpacity(0.1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            child: Column(
              children: [
                // Header
                Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.primary.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.school_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Skaduta Presensi',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Sistem Absensi Digital Sekolah',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Form Card
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Username
                          TextFormField(
                            controller: _usernameC,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              'Username',
                              Icons.person_outline,
                              cs,
                            ),
                            style: const TextStyle(fontSize: 18),
                            validator: (v) => v?.trim().isEmpty == true
                                ? 'Username wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Nama Lengkap
                          TextFormField(
                            controller: _namaC,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              'Nama Lengkap',
                              Icons.badge_outlined,
                              cs,
                            ),
                            style: const TextStyle(fontSize: 18),
                            validator: (v) => v?.trim().isEmpty == true
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Checkbox Karyawan
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cs.primary.withOpacity(0.3),
                              ),
                            ),
                            child: CheckboxListTile(
                              value: _isKaryawan,
                              onChanged: (val) =>
                                  setState(() => _isKaryawan = val ?? false),
                              title: const Text(
                                'Saya Karyawan / Guru',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'NIP/NISN tidak wajib diisi',
                                style: TextStyle(fontSize: 15),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // NIP/NISN (hanya muncul jika bukan karyawan)
                          if (!_isKaryawan)
                            TextFormField(
                              controller: _nipNisnC,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                'NIP / NISN',
                                Icons.credit_card_outlined,
                                cs,
                              ),
                              style: const TextStyle(fontSize: 18),
                              validator: (_) => _isKaryawan
                                  ? null
                                  : (_nipNisnC.text.trim().isEmpty
                                        ? 'NIP/NISN wajib diisi'
                                        : null),
                            ),
                          if (!_isKaryawan) const SizedBox(height: 20),

                          // Password
                          TextFormField(
                            controller: _passwordC,
                            obscureText: _obscure,
                            decoration:
                                _inputDecoration(
                                  'Password',
                                  Icons.lock_outline,
                                  cs,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: cs.primary,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                            style: const TextStyle(fontSize: 18),
                            validator: (v) {
                              if (v?.isEmpty == true)
                                return 'Password wajib diisi';
                              if (v!.length < 4) return 'Minimal 4 karakter';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Role Dropdown – DIPINDAH KE LUAR TextFormField BIAR GA BUG!
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cs.primary.withOpacity(0.4),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _role,
                                isExpanded: true,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: cs.primary,
                                  size: 32,
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'user',
                                    child: Text('User (Siswa / Guru)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'admin',
                                    child: Text('Admin'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'superadmin',
                                    child: Text('Super Admin'),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _role = val!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Tombol Daftar
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                shadowColor: cs.primary.withOpacity(0.5),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'DAFTAR SEKARANG',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper untuk Input Decoration
  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    ColorScheme cs,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: cs.primary, size: 28),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      labelStyle: TextStyle(fontSize: 18, color: cs.primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );
  }
}
