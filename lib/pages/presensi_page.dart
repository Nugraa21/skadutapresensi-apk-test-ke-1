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

  // Koordinat SMK N 2 YK (sinkron sama PHP)
  final double sekolahLat = -7.777047019078815;
  final double sekolahLng = 110.3671540164373;
  final double maxRadius = 100; // meter

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

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
    final XFile? img = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
    );

    if (img != null) {
      setState(() {
        _selfieFile = File(img.path);
      });
      print('DEBUG: Selfie OK, size: ${await File(img.path).length()} bytes');
    }
  }

  Future<void> _submitPresensi() async {
    if (_position == null) {
      _showSnack('Lokasi belum terbaca');
      return;
    }

    // Skip foto buat test
    // if (_selfieFile == null) {
    //   _showSnack('Selfie belum diambil');
    //   return;
    // }

    final jarak = _distanceToSchool();
    if (jarak > maxRadius) {
      _showSnack(
        'Kamu di luar jangkauan sekolah (±${jarak.toStringAsFixed(1)}m)',
      );
      return;
    }

    // Validasi keterangan hanya buat Izin/Pulang Cepat
    if ((_jenis == 'Izin' || _jenis == 'Pulang Cepat') &&
        _ketC.text.trim().isEmpty) {
      _showSnack('Keterangan wajib diisi untuk $_jenis!');
      return;
    }

    setState(() => _loading = true);

    try {
      String base64Image = '';
      if (_selfieFile != null) {
        final bytes = await _selfieFile!.readAsBytes();
        base64Image = base64Encode(bytes);
        print('DEBUG: Base64 length: ${base64Image.length}');
      } else {
        print('DEBUG: No selfie, sending empty');
      }

      final res = await ApiService.submitPresensi(
        userId: widget.user.id,
        jenis: _jenis,
        keterangan: _ketC.text.trim(),
        latitude: _position!.latitude.toString(),
        longitude: _position!.longitude.toString(),
        base64Image: base64Image, // Kosong OK buat test
      );

      print(
        'DEBUG SUBMIT: Full response: ${jsonEncode(res)}',
      ); // Liat error di console

      if (res['status'] == true) {
        _showSnack(res['message'] ?? 'Presensi berhasil!');
        // Reset
        setState(() {
          _ketC.clear();
          _selfieFile = null;
        });
      } else {
        _showSnack(res['message'] ?? 'Gagal presensi');
      }
    } catch (e) {
      print('DEBUG SUBMIT: Error: $e');
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains('berhasil') ? Colors.green : Colors.red,
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
                      initialCenter: LatLng(
                        _position!.latitude,
                        _position!.longitude,
                      ),
                      initialZoom: 17,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(sekolahLat, sekolahLng),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.school,
                              color: Colors.blue,
                              size: 32,
                            ),
                          ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jarak ke sekolah: ${_distanceToSchool().toStringAsFixed(1)} m',
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
                                label: const Text(
                                  'Ambil Selfie (Opsional test)',
                                ),
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
