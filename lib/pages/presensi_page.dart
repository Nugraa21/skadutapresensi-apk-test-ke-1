import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../api/api_service.dart';
import '../models/user_model.dart';

class PresensiPage extends StatefulWidget {
  final UserModel user;

  const PresensiPage({super.key, required this.user});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
  Position? _position;
  String _jenis = 'Masuk';
  final TextEditingController _ketC = TextEditingController();
  File? _selfieFile;
  bool _loading = false;

  // TEST MODE: True = Skip cek area (untuk testing saja)
  bool _testMode = false; // Set ke true kalau mau test tanpa cek area
  // bool _testMode = true; // Set ke true kalau mau test tanpa cek area

  final ImagePicker _picker = ImagePicker();

  // ===============================
  // AREA PRESENSI (BOUNDING BOX)
  // ===============================

  // Latitude
  final double latMax = -7.7754343932798085; // pojok kiri atas
  final double latMin = -7.77829886563817; // pojok kanan bawah

  // Longitude
  final double lngMin = 110.36438675304636; // pojok kiri bawah
  final double lngMax = 110.36841167113668; // pojok kanan atas

  // Posisi "tengah" untuk map
  final double centerLat = -7.7770775;
  final double centerLng = 110.3670864;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // =====================================
  // BACA LOKASI USER (AKURASI TINGGI)
  // =====================================
  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Location service off, aktifkan dulu ya');
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        _showSnack('Izin lokasi ditolak');
        return;
      }
    }

    if (perm == LocationPermission.deniedForever) {
      _showSnack('Izin lokasi permanent ditolak, cek pengaturan hp');
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
    setState(() {
      _position = pos;
    });
  }

  // =====================================
  // CEK APAKAH USER DI DALAM AREA (DENGAN BUFFER)
  // =====================================
  bool _isInsideArea() {
    if (_position == null) return false;

    final lat = _position!.latitude;
    final lng = _position!.longitude;

    // DEBUG: Print koordinat (hapus nanti)
    print('DEBUG - Lokasi HP: Lat=$lat, Lng=$lng');
    print(
      'DEBUG - Bounds: latMin=$latMin, latMax=$latMax, lngMin=$lngMin, lngMax=$lngMax',
    );

    final buffer = 0.0009; // ~100m
    final latMinBuffered = latMin - buffer;
    final latMaxBuffered = latMax + buffer;
    final lngMinBuffered = lngMin - buffer;
    final lngMaxBuffered = lngMax + buffer;

    final isInside =
        lat >= latMinBuffered &&
        lat <= latMaxBuffered &&
        lng >= lngMinBuffered &&
        lng <= lngMaxBuffered;

    print('DEBUG - Inside with buffer? $isInside');

    return isInside;
  }

  // =====================================
  // AMBIL SELFIE
  // =====================================
  Future<void> _pickSelfie() async {
    final XFile? img = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
    );

    if (img != null) {
      setState(() {
        _selfieFile = File(img.path);
      });
    }
  }

  // =====================================
  // SUBMIT PRESENSI (VALIDASI KETERANGAN KONDISIONAL)
  // =====================================
  Future<void> _submitPresensi() async {
    if (_position == null) {
      _showSnack('Lokasi belum terbaca');
      return;
    }

    // TEST MODE: Skip cek area kalau true
    if (!_testMode && !_isInsideArea()) {
      _showSnack('Kamu berada di luar area sekolah!');
      return;
    }

    if (_selfieFile == null) {
      _showSnack('Selfie belum diambil');
      return;
    }

    // VALIDASI: Keterangan wajib hanya untuk Izin & Pulang Cepat
    if ((_jenis == 'Izin' || _jenis == 'Pulang Cepat') &&
        _ketC.text.trim().isEmpty) {
      _showSnack('Keterangan wajib diisi untuk $_jenis!');
      return;
    }

    setState(() => _loading = true);

    try {
      final bytes = await _selfieFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final res = await ApiService.submitPresensi(
        userId: widget.user.id,
        jenis: _jenis,
        keterangan: _ketC.text.trim(),
        latitude: _position!.latitude.toString(),
        longitude: _position!.longitude.toString(),
        base64Image: base64Image,
      );

      // MENARIK: Tampilkan dialog sukses dengan detail dari PHP
      if (res['status'] == true) {
        _showSuccessDialog(res['message'], res['data']);
        // Reset form
        setState(() {
          _jenis = 'Masuk';
          _ketC.clear();
          _selfieFile = null;
        });
      } else {
        _showSnack(res['message'] ?? 'Gagal presensi');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // MENARIK: Dialog sukses dengan animasi
  void _showSuccessDialog(String message, Map<String, dynamic>? data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('Presensi Berhasil!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (data != null) ...[
              const SizedBox(height: 8),
              Text('ID: ${data['id']}'),
              Text('Waktu: ${data['timestamp']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains('berhasil') ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _ketC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Sekolah'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _position == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // MAP DENGAN GRADIENT HEADER
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary.withOpacity(0.1), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Area Sekolah',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(centerLat, centerLng),
                            initialZoom: 17,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            // MARKER USER DENGAN ANIMASI
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    _position!.latitude,
                                    _position!.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.my_location,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // POLYGON AREA DENGAN LABEL
                            PolygonLayer(
                              polygons: [
                                Polygon(
                                  points: [
                                    LatLng(latMax, lngMin),
                                    LatLng(latMax, lngMax),
                                    LatLng(latMin, lngMax),
                                    LatLng(latMin, lngMin),
                                  ],
                                  color: Colors.blue.withOpacity(0.2),
                                  borderColor: Colors.blue,
                                  borderStrokeWidth: 3,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: _isInsideArea()
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            _isInsideArea() ? Icons.check_circle : Icons.cancel,
                            color: _isInsideArea() ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isInsideArea()
                                  ? 'Dalam Area Sekolah ✔'
                                  : 'Di Luar Area ❌',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _isInsideArea()
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // TEST MODE INDICATOR (HANYA KALAU TRUE)
                if (_testMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'TEST MODE: Cek area di-skip',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        // DROPDOWN DENGAN ICON
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: DropdownButtonFormField<String>(
                              value: _jenis,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Presensi',
                                border: InputBorder.none,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Masuk',
                                  child: Row(
                                    children: [
                                      Icon(Icons.login),
                                      SizedBox(width: 8),
                                      Text('Absen Masuk'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Pulang',
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout),
                                      SizedBox(width: 8),
                                      Text('Absen Pulang'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Izin',
                                  child: Row(
                                    children: [
                                      Icon(Icons.block),
                                      SizedBox(width: 8),
                                      Text('Izin / Tidak Hadir'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Pulang Cepat',
                                  child: Row(
                                    children: [
                                      Icon(Icons.fast_forward),
                                      SizedBox(width: 8),
                                      Text('Pulang Cepat'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _jenis = v;
                                    if (v == 'Masuk' || v == 'Pulang') {
                                      _ketC.clear();
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // KETERANGAN KONDITIONAL DENGAN CARD
                        if (_jenis == 'Izin' || _jenis == 'Pulang Cepat') ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: TextField(
                                controller: _ketC,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Keterangan (alasan)',
                                  border: InputBorder.none,
                                  helperText: 'Wajib diisi untuk jenis ini',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // SELFIE DENGAN PREVIEW LEBIH BESAR
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickSelfie,
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Ambil Selfie'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                  ),
                                ),
                                if (_selfieFile != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _selfieFile!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // BUTTON SUBMIT DENGAN ANIMASI
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _loading ? null : _submitPresensi,
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.send, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('Kirim Presensi'),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
