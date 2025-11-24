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

  final ImagePicker _picker = ImagePicker();

  // ===============================
  // AREA PRESENSI (BOUNDING BOX)
  // ===============================

  // Latitude
  final double latMax =
      -7.7754343932798085; // pojok kiri atas  -7.7754343932798085, 110.36537551797107
  final double latMin =
      -7.77829886563817; // pojok kanan bawah  -7.77829886563817, 110.36823971201933

  // Longitude
  final double lngMin =
      110.36438675304636; // pojok kiri bawah   -7.778027327276084, 110.36438675304636
  final double lngMax =
      110.36841167113668; // pojok kanan atas  -7.775445041912144, 110.36841167113668

  // Posisi "tengah" untuk map
  final double centerLat = -7.7770775;
  final double centerLng = 110.3670864;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // =====================================
  // BACA LOKASI USER
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

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _position = pos;
    });
  }

  // =====================================
  // CEK APAKAH USER DI DALAM AREA
  // =====================================
  bool _isInsideArea() {
    if (_position == null) return false;

    final lat = _position!.latitude;
    final lng = _position!.longitude;

    return lat >= latMin && lat <= latMax && lng >= lngMin && lng <= lngMax;
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
  // SUBMIT PRESENSI
  // =====================================
  Future<void> _submitPresensi() async {
    if (_position == null) {
      _showSnack('Lokasi belum terbaca');
      return;
    }

    if (!_isInsideArea()) {
      _showSnack('Kamu berada di luar area sekolah!');
      return;
    }

    if (_selfieFile == null) {
      _showSnack('Selfie belum diambil');
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

      _showSnack(res['message'] ?? 'Presensi terkirim');
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      appBar: AppBar(title: const Text('Presensi')),
      body: _position == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // MAP
                SizedBox(
                  height: 260,
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

                      // MARKER POSISI USER
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              _position!.latitude,
                              _position!.longitude,
                            ),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.red,
                              size: 32,
                            ),
                          ),
                        ],
                      ),

                      // AREA BATAS (POLYGON)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: [
                              LatLng(latMax, lngMin), // kiri atas
                              LatLng(latMax, lngMax), // kanan atas
                              LatLng(latMin, lngMax), // kanan bawah
                              LatLng(latMin, lngMin), // kiri bawah
                            ],
                            color: Colors.blue.withOpacity(0.2),
                            borderColor: Colors.blue,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  _isInsideArea()
                      ? 'Status: Dalam Area Sekolah ✔'
                      : 'Status: Di Luar Area ❌',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _jenis,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Presensi',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Masuk',
                              child: Text('Absen Masuk'),
                            ),
                            DropdownMenuItem(
                              value: 'Pulang',
                              child: Text('Absen Pulang'),
                            ),
                            DropdownMenuItem(
                              value: 'Izin',
                              child: Text('Izin / Tidak Hadir'),
                            ),
                            DropdownMenuItem(
                              value: 'Pulang Cepat',
                              child: Text('Pulang Cepat'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _jenis = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _ketC,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Keterangan (alasan)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickSelfie,
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Ambil Selfie'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (_selfieFile != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selfieFile!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _submitPresensi,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Kirim Presensi'),
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
