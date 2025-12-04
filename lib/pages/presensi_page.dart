// pages/presensi_page.dart
// VERSI FINAL – WAJIB SELFIE UNTUK MASUK/PULANG/PULANG CEPAT, WAJIB DOKUMEN UNTUK IZIN

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lat_lng;

import '../api/api_service.dart';
import '../models/user_model.dart';

class PresensiPage extends StatefulWidget {
  final UserModel user;
  final String initialJenis;

  const PresensiPage({
    super.key,
    required this.user,
    required this.initialJenis,
  });

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage>
    with TickerProviderStateMixin {
  Position? _position;
  late String _jenis;
  final TextEditingController _ketC = TextEditingController();
  final TextEditingController _infoC = TextEditingController();
  File? _selfieFile;
  File? _dokumenFile;
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  // Koordinat sekolah
  static const double sekolahLat = -7.7771639173358516;
  static const double sekolahLng = 110.36716347232226;
  static const double maxRadius = 200; // meter

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _jenis = widget.initialJenis;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _pulseController.repeat();

    if (_isMapNeeded) _initLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ketC.dispose();
    _infoC.dispose();
    super.dispose();
  }

  bool get _isMapNeeded => _jenis == 'Masuk' || _jenis == 'Pulang';
  bool get _isPenugasan => _jenis.startsWith('Penugasan');
  bool get _isIzin => _jenis == 'Izin';
  bool get _isPulangCepat => _jenis == 'Pulang Cepat';

  // ========== LOKASI ==========
  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled)
      return _showSnack('Location service mati, nyalakan dulu ya');

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied)
        return _showSnack('Izin lokasi ditolak');
    }
    if (perm == LocationPermission.deniedForever) {
      return _showSnack('Izin lokasi ditolak permanen');
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _position = pos);
    } catch (e) {
      _showSnack('Gagal ambil lokasi');
    }
  }

  double _distanceToSchool() {
    if (_position == null) return 999999;
    return Geolocator.distanceBetween(
      _position!.latitude,
      _position!.longitude,
      sekolahLat,
      sekolahLng,
    );
  }

  // ========== IMAGE PICKER ==========
  Future<void> _pickSelfie() async {
    final img = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );
    if (img != null) setState(() => _selfieFile = File(img.path));
  }

  Future<void> _pickDokumen() async {
    final doc = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (doc != null) setState(() => _dokumenFile = File(doc.path));
  }

  // ========== SUBMIT ==========
  Future<void> _submitPresensi() async {
    // Validasi lokasi untuk Masuk & Pulang
    if (_isMapNeeded) {
      if (_position == null) return _showSnack('Lokasi belum terdeteksi');
      final jarak = _distanceToSchool();
      if (jarak > maxRadius) {
        return _showSnack(
          'Di luar radius sekolah (±${jarak.toStringAsFixed(1)}m)',
        );
      }
    }

    // WAJIB SELFIE untuk Masuk, Pulang, Pulang Cepat
    if (_jenis == 'Masuk' || _jenis == 'Pulang' || _jenis == 'Pulang Cepat') {
      if (_selfieFile == null) return _showSnack('Selfie wajib diambil!');
    }

    // WAJIB DOKUMEN untuk Izin
    if (_isIzin) {
      if (_dokumenFile == null) return _showSnack('Bukti izin wajib diunggah!');
      if (_ketC.text.trim().isEmpty)
        return _showSnack('Keterangan wajib diisi!');
    }

    // WAJIB DOKUMEN + INFO untuk Penugasan
    if (_isPenugasan) {
      if (_infoC.text.trim().isEmpty)
        return _showSnack('Informasi penugasan wajib diisi!');
      if (_dokumenFile == null)
        return _showSnack('Dokumen penugasan wajib diunggah!');
    }

    setState(() => _loading = true);

    try {
      final res = await ApiService.submitPresensi(
        userId: widget.user.id,
        jenis: _jenis,
        keterangan: _ketC.text.trim(),
        informasi: _infoC.text.trim(),
        dokumenBase64: _dokumenFile != null
            ? base64Encode(await _dokumenFile!.readAsBytes())
            : '',
        latitude: _position?.latitude.toString() ?? '0',
        longitude: _position?.longitude.toString() ?? '0',
        base64Image: _selfieFile != null
            ? base64Encode(await _selfieFile!.readAsBytes())
            : '',
      );

      if (res['status'] == true) {
        _showSuccessDialog();
      } else {
        _showSnack(res['message'] ?? 'Gagal mengirim presensi');
      }
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.all(30),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 70, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                "SUKSES!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Presensi $_jenis berhasil dikirim",
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Terima kasih!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context)
          ..pop()
          ..pop();
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: msg.contains('berhasil')
            ? Colors.green.shade600
            : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ========== MAP ==========
  Widget _buildMap() {
    final jarak = _distanceToSchool();
    final inRadius = jarak <= maxRadius;

    return Container(
      height: 380,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _position != null
                    ? lat_lng.LatLng(_position!.latitude, _position!.longitude)
                    : lat_lng.LatLng(sekolahLat, sekolahLng),
                initialZoom: 17.8,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => CircleLayer(
                    circles: [
                      CircleMarker(
                        point: lat_lng.LatLng(sekolahLat, sekolahLng),
                        radius: maxRadius + (_pulseAnimation.value * 35),
                        useRadiusInMeter: true,
                        color: Colors.transparent,
                        borderColor: inRadius
                            ? Colors.green.withOpacity(0.5)
                            : Colors.red.withOpacity(0.5),
                        borderStrokeWidth: 10,
                      ),
                    ],
                  ),
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: lat_lng.LatLng(sekolahLat, sekolahLng),
                      radius: maxRadius,
                      useRadiusInMeter: true,
                      color: inRadius
                          ? Colors.green.withOpacity(0.22)
                          : Colors.red.withOpacity(0.22),
                      borderColor: inRadius ? Colors.green : Colors.redAccent,
                      borderStrokeWidth: 6,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: lat_lng.LatLng(sekolahLat, sekolahLng),
                      width: 100,
                      height: 100,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              size: 40,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const Text(
                            "Sekolah",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_position != null)
                      Marker(
                        point: lat_lng.LatLng(
                          _position!.latitude,
                          _position!.longitude,
                        ),
                        width: 90,
                        height: 90,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.my_location,
                                size: 36,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const Text(
                              "Kamu",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: inRadius
                        ? [Colors.green.shade600, Colors.green.shade500]
                        : [Colors.red.shade600, Colors.red.shade500],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      inRadius
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inRadius ? "Di Dalam Area!" : "Di Luar Area",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${jarak.toStringAsFixed(1)} m dari sekolah",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (inRadius)
                      const Text(
                        "SIAP!",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _jenis.replaceAll('_', ' '),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.95),
                cs.primary.withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary.withOpacity(0.06), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 5))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 110, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _jenis == 'Masuk'
                            ? 'Selamat Datang!'
                            : _jenis == 'Pulang'
                            ? 'Selamat Pulang!'
                            : _jenis == 'Izin'
                            ? 'Ajukan Izin'
                            : 'Presensi $_jenis',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isMapNeeded
                            ? 'Pastikan kamu berada di area sekolah'
                            : 'Lengkapi data di bawah ini',
                        style: TextStyle(color: Colors.grey[700], fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      if (_isMapNeeded) ...[
                        _buildMap(),
                        const SizedBox(height: 30),
                      ],

                      // KETERANGAN (Izin & Pulang Cepat)
                      if (_isIzin || _isPulangCepat)
                        _buildTextField(
                          _ketC,
                          'Keterangan / Alasan',
                          'Contoh: Sakit, ada keperluan keluarga, dll',
                          Icons.note_alt_rounded,
                          cs,
                        ),
                      if (_isIzin || _isPulangCepat) const SizedBox(height: 20),

                      // INFORMASI PENUGASAN
                      if (_isPenugasan)
                        _buildTextField(
                          _infoC,
                          'Informasi Penugasan',
                          'Jelaskan tugas yang diberikan',
                          Icons.assignment_rounded,
                          cs,
                          maxLines: 5,
                        ),
                      if (_isPenugasan) const SizedBox(height: 20),

                      // SELFIE (WAJIB untuk Masuk/Pulang/Pulang Cepat)
                      if (_jenis == 'Masuk' ||
                          _jenis == 'Pulang' ||
                          _jenis == 'Pulang Cepat')
                        _buildImagePicker(
                          'Ambil Selfie (Wajib)',
                          _selfieFile,
                          _pickSelfie,
                          Icons.camera_alt_rounded,
                          cs,
                          required: true,
                        ),
                      if (_jenis == 'Masuk' ||
                          _jenis == 'Pulang' ||
                          _jenis == 'Pulang Cepat')
                        const SizedBox(height: 20),

                      // DOKUMEN BUKTI IZIN (WAJIB untuk Izin)
                      if (_isIzin)
                        _buildImagePicker(
                          'Unggah Bukti Izin (Wajib)',
                          _dokumenFile,
                          _pickDokumen,
                          Icons.file_present_rounded,
                          cs,
                          required: true,
                        ),
                      if (_isIzin) const SizedBox(height: 20),

                      // DOKUMEN PENUGASAN
                      if (_isPenugasan)
                        _buildImagePicker(
                          'Unggah Surat Tugas / Dokumen (Wajib)',
                          _dokumenFile,
                          _pickDokumen,
                          Icons.file_present_rounded,
                          cs,
                          required: true,
                        ),

                      const SizedBox(height: 30),

                      // TOMBOL KIRIM
                      SizedBox(
                        height: 64,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _submitPresensi,
                          icon: _loading
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 30),
                          label: Text(
                            _loading ? 'Mengirim...' : 'Kirim Presensi',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            elevation: 12,
                            shadowColor: cs.primary.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController c,
    String label,
    String hint,
    IconData icon,
    ColorScheme cs, {
    int maxLines = 3,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: cs.primary, size: 28),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(
    String title,
    File? file,
    VoidCallback onTap,
    IconData icon,
    ColorScheme cs, {
    bool required = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              icon,
              color: required ? Colors.red.shade600 : cs.primary,
              size: 32,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: required ? Colors.red.shade600 : Colors.black87,
                fontSize: 16,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: onTap,
          ),
          if (file != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  file,
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
