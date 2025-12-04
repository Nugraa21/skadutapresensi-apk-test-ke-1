// pages/presensi_page.dart
// VERSI FINAL – UI/UX PREMIUM 2025, MAP CANTIK, RESPONSIF 100%

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

  static const double sekolahLat = -7.7771639173358516;
  static const double sekolahLng = 110.36716347232226;
  static const double maxRadius = 150;

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

    if (!_isNoLocationNeeded) _initLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ketC.dispose();
    _infoC.dispose();
    super.dispose();
  }

  bool get _isPenugasan => _jenis.startsWith('Penugasan');
  bool get _isNoLocationNeeded => _jenis == 'Izin' || _isPenugasan;
  bool get _isMapNeeded => _jenis == 'Masuk' || _jenis == 'Pulang';

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

  Future<void> _pickSelfie() async {
    final img = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 75,
    );
    if (img != null) setState(() => _selfieFile = File(img.path));
  }

  Future<void> _pickDokumen() async {
    final doc = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (doc != null) setState(() => _dokumenFile = File(doc.path));
  }

  Future<void> _submitPresensi() async {
    if (!_isNoLocationNeeded && _position == null)
      return _showSnack('Lokasi belum terbaca');
    final jarak = _distanceToSchool();
    if (!_isNoLocationNeeded && jarak > maxRadius) {
      return _showSnack(
        'Kamu di luar radius sekolah (${jarak.toStringAsFixed(1)}m)',
      );
    }

    if ((_jenis == 'Izin' || _jenis == 'Pulang Cepat') &&
        _ketC.text.trim().isEmpty) {
      return _showSnack('Keterangan wajib diisi!');
    }
    if (_isPenugasan && (_infoC.text.trim().isEmpty || _dokumenFile == null)) {
      return _showSnack('Informasi & dokumen penugasan wajib diisi!');
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
        _showSnack(res['message'] ?? 'Presensi berhasil!');
        _resetForm();
      } else {
        _showSnack(res['message'] ?? 'Gagal presensi');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _ketC.clear();
      _infoC.clear();
      _selfieFile = null;
      _dokumenFile = null;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: msg.contains('berhasil')
            ? Colors.green.shade600
            : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ==================== MAP CANTIK + PULSE ANIMATION ====================
  Widget _buildMap() {
    final jarak = _distanceToSchool();
    final inRadius = jarak <= maxRadius;

    return Container(
      height: 380,
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
                maxZoom: 19,
                crs: const Epsg3857(),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                // Pulse Circle
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => CircleLayer(
                    circles: [
                      CircleMarker(
                        point: lat_lng.LatLng(sekolahLat, sekolahLng),
                        radius: maxRadius + (_pulseAnimation.value * 30),
                        useRadiusInMeter: true,
                        color: Colors.transparent,
                        borderColor: inRadius
                            ? Colors.green.withOpacity(
                                0.4 - _pulseAnimation.value * 0.3,
                              )
                            : Colors.red.withOpacity(
                                0.4 - _pulseAnimation.value * 0.3,
                              ),
                        borderStrokeWidth: 8,
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
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderColor: inRadius ? Colors.green : Colors.redAccent,
                      borderStrokeWidth: 5,
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
                              size: 38,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const Text(
                            "Sekolah",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 6),
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
                                size: 34,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const Text(
                              "Kamu",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 6),
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

            // Status Card di Atas Map
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                borderRadius: BorderRadius.circular(24),
                elevation: 10,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: inRadius
                          ? [Colors.green.shade500, Colors.green.shade400]
                          : [Colors.red.shade500, Colors.red.shade400],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        inRadius
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 36,
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
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${jarak.toStringAsFixed(1)} m dari sekolah",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
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
                            fontSize: 16,
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
            colors: [cs.primary.withOpacity(0.05), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 4))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 110, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Judul Selamat Datang
                      Text(
                        _jenis == 'Masuk'
                            ? 'Selamat Pagi! 👋'
                            : _jenis == 'Pulang'
                            ? 'Selamat Pulang! 🏠'
                            : 'Presensi $_jenis',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pastikan kamu berada di area yang benar',
                        style: TextStyle(color: Colors.grey[700], fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Map (hanya untuk Masuk/Pulang, tapi tetap muncul cantik di Izin jika lokasi diambil)
                      if (_isMapNeeded || !_isNoLocationNeeded) ...[
                        _buildMap(),
                        const SizedBox(height: 30),
                      ],

                      // Form Izin / Penugasan
                      if (_jenis == 'Izin' || _jenis == 'Pulang Cepat') ...[
                        _buildTextField(
                          _ketC,
                          'Keterangan / Alasan',
                          'Wajib diisi',
                          Icons.note_alt_rounded,
                          cs,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_isPenugasan) ...[
                        _buildTextField(
                          _infoC,
                          'Informasi Penugasan',
                          'Wajib diisi',
                          Icons.assignment_rounded,
                          cs,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Selfie
                      _buildImagePicker(
                        'Ambil Selfie (Opsional)',
                        _selfieFile,
                        _pickSelfie,
                        Icons.camera_alt_rounded,
                        cs,
                      ),
                      const SizedBox(height: 20),

                      // Dokumen Penugasan
                      if (_isPenugasan)
                        _buildImagePicker(
                          'Unggah Surat/Dokumen (Wajib)',
                          _dokumenFile,
                          _pickDokumen,
                          Icons.file_present_rounded,
                          cs,
                          required: true,
                        ),

                      const SizedBox(height: 30),

                      // Tombol Kirim
                      SizedBox(
                        height: 62,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _submitPresensi,
                          icon: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 28),
                          label: Text(
                            _loading ? 'Mengirim...' : 'Kirim Presensi',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 10,
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
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
          prefixIcon: Icon(icon, color: cs.primary),
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
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
                color: required ? Colors.red.shade600 : null,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
          if (file != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  file,
                  height: 200,
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
