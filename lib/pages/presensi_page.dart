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

class _PresensiPageState extends State<PresensiPage>
    with TickerProviderStateMixin {
  Position? _position;
  String _jenis = 'Masuk';
  final TextEditingController _ketC = TextEditingController();
  File? _selfieFile;
  bool _loading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ImagePicker _picker = ImagePicker();

  // Koordinat SMK N 2 YK (sinkron sama PHP)
  final double sekolahLat = -7.777047019078815;
  final double sekolahLng = 110.3671540164373;
  final double maxRadius = 100; // meter

  @override
  void initState() {
    super.initState();
    _initLocation();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ketC.dispose();
    super.dispose();
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

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
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
        base64Image: base64Image,
      );

      print('DEBUG SUBMIT: Full response: ${jsonEncode(res)}');

      if (res['status'] == true) {
        _showSnack(res['message'] ?? 'Presensi berhasil!');
        _resetForm();
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

  void _resetForm() {
    setState(() {
      _ketC.clear();
      _selfieFile = null;
      _jenis = 'Masuk';
    });
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final jarak = _distanceToSchool();
    final isInRadius = jarak <= maxRadius;
    final progress = (maxRadius - jarak.clamp(0, maxRadius)) / maxRadius;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Sekolah'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _position == null
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                // HEADER GRADIENT MAP
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
                            Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Area Sekolah',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(sekolahLat, sekolahLng),
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
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.school,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                if (_position != null)
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
                                        color: isInRadius
                                            ? Colors.green
                                            : Colors.red,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (isInRadius
                                                        ? Colors.green
                                                        : Colors.red)
                                                    .withOpacity(0.3),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.my_location,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // POLYGON AREA SEKOLAH (BIRU TRANSPARAN)
                            PolygonLayer(
                              polygons: [
                                Polygon(
                                  points: [
                                    LatLng(
                                      sekolahLat - 0.001,
                                      sekolahLng - 0.001,
                                    ),
                                    LatLng(
                                      sekolahLat - 0.001,
                                      sekolahLng + 0.001,
                                    ),
                                    LatLng(
                                      sekolahLat + 0.001,
                                      sekolahLng + 0.001,
                                    ),
                                    LatLng(
                                      sekolahLat + 0.001,
                                      sekolahLng - 0.001,
                                    ),
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
                    ],
                  ),
                ),
                // INDIKATOR JARIK DENGAN PROGRESS BAR ANIMASI
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: isInRadius
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            isInRadius ? Icons.check_circle : Icons.cancel,
                            color: isInRadius ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isInRadius
                                      ? 'Dalam Area Sekolah ✔'
                                      : 'Di Luar Area ❌',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isInRadius
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isInRadius ? Colors.green : Colors.red,
                                  ),
                                ),
                                Text(
                                  'Jarak: ${jarak.toStringAsFixed(1)} m',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // DROPDOWN JENIS PRESENSI
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
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
                                        Icon(Icons.login, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('Absen Masuk'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Pulang',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.logout,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Absen Pulang'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Izin',
                                    child: Row(
                                      children: [
                                        Icon(Icons.block, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Izin / Tidak Hadir'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Pulang Cepat',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.fast_forward,
                                          color: Colors.blue,
                                        ),
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
                                      if (v == 'Masuk' || v == 'Pulang')
                                        _ketC.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // KETERANGAN (KONDISIONAL)
                          if (_jenis == 'Izin' || _jenis == 'Pulang Cepat') ...[
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
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
                            const SizedBox(height: 16),
                          ],

                          // SELFIE PREVIEW (LEBIH BESAR & BAGUS)
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _pickSelfie,
                                    icon: const Icon(Icons.camera_alt_outlined),
                                    label: const Text(
                                      'Ambil Selfie (Opsional)',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(
                                        double.infinity,
                                        48,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  if (_selfieFile != null) ...[
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
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

                          // BUTTON SUBMIT (ANIMASI + RESET)
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _loading ? null : _submitPresensi,
                                  icon: _loading
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
                                      : const Icon(Icons.send),
                                  label: const Text('Kirim Presensi'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: _resetForm,
                                icon: const Icon(Icons.refresh, size: 28),
                                tooltip: 'Reset Form',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
