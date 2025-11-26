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

  // For sheet drag effects
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  double _darkenValue = 0.0;
  static const double _initialSheetSize = 0.45;
  static const double _maxDarken = 0.15; // Subtle dark overlay

  @override
  void initState() {
    super.initState();
    _initLocation();
    _sheetController.addListener(() {
      final extent = _sheetController.size;
      final normalized =
          (extent - _initialSheetSize) / (1.0 - _initialSheetSize);
      setState(() {
        _darkenValue = (_maxDarken * normalized).clamp(0.0, _maxDarken);
      });
    });
  }

  @override
  void dispose() {
    _ketC.dispose();
    _sheetController.dispose();
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: _position == null
          ? Container(
              color: Colors.grey[50],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: cs.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Mendapatkan lokasi...',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                // 🌍 MAP FULL BACKGROUND (Interactive - ensure it's on top for gestures)
                Positioned.fill(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        -7.777047019078815,
                        110.3671540164373,
                      ),
                      initialZoom: 17.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: const LatLng(
                              -7.777047019078815,
                              110.3671540164373,
                            ),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.school,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
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
                                color: isInRadius ? Colors.green : Colors.red,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isInRadius ? Colors.green : Colors.red)
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
                      // Polygon for school area
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: [
                              LatLng(sekolahLat - 0.001, sekolahLng - 0.001),
                              LatLng(sekolahLat - 0.001, sekolahLng + 0.001),
                              LatLng(sekolahLat + 0.001, sekolahLng + 0.001),
                              LatLng(sekolahLat + 0.001, sekolahLng - 0.001),
                            ],
                            color: cs.primary.withOpacity(0.2),
                            borderColor: cs.primary,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ✨ DARK OVERLAY saat sheet dragged up (Ignore pointers to allow map interaction)
                IgnorePointer(
                  ignoring: true,
                  child: Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      opacity: _darkenValue > 0 ? 1.0 : 0.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        color: Colors.black.withOpacity(_darkenValue),
                      ),
                    ),
                  ),
                ),
                // 📱 DRAGGABLE SHEET FOR FORM (Bottom popup) - with smoother physics
                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: _initialSheetSize,
                  minChildSize: 0.4,
                  maxChildSize: 0.95,
                  snap: true,
                  snapSizes: const [0.45, 0.95],
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 25,
                            offset: const Offset(0, -8),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Handle bar for drag - cooler design
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              height: 5,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            _buildRadiusCard(jarak, isInRadius, progress, cs),
                            const SizedBox(height: 20),
                            _buildJenisDropdown(cs),
                            const SizedBox(height: 20),
                            if (_jenis == 'Izin' ||
                                _jenis == 'Pulang Cepat') ...[
                              _buildKeterangan(cs),
                              const SizedBox(height: 20),
                            ],
                            _buildSelfie(cs),
                            const SizedBox(height: 28),
                            _buildSubmitButtons(cs),
                            const SizedBox(height: 30), // Extra space
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  // ================== WIDGETS WITH LIGHT GLASSMORPHISM ==================
  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey[200]!),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildRadiusCard(
    double jarak,
    bool isInRadius,
    double progress,
    ColorScheme cs,
  ) {
    return Container(
      width: double.infinity,
      decoration: _glassDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isInRadius ? Colors.green : Colors.red).withOpacity(
                    0.1,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isInRadius ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isInRadius ? Icons.check_circle : Icons.cancel,
                  color: isInRadius ? Colors.green : Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isInRadius ? 'Dalam Area Sekolah' : 'Di Luar Area',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Jarak: ${jarak.toStringAsFixed(1)} m',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),

          //  progress bar

          // const SizedBox(height: 16),
          // SizedBox(
          //   height: 6,
          //   child: ClipRRect(
          //     borderRadius: BorderRadius.circular(4),
          //     child: LinearProgressIndicator(
          //       value: progress,
          //       backgroundColor: Colors.grey[200],
          //       valueColor: AlwaysStoppedAnimation<Color>(
          //         isInRadius ? Colors.green : Colors.red,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildJenisDropdown(ColorScheme cs) {
    return Container(
      decoration: _glassDecoration(),
      padding: const EdgeInsets.all(8),
      child: DropdownButtonFormField<String>(
        value: _jenis,
        decoration: InputDecoration(
          labelText: 'Jenis Presensi',
          labelStyle: const TextStyle(color: Colors.black54),
          prefixIcon: Icon(Icons.category, color: cs.primary),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
        ),
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black87),
        iconEnabledColor: cs.primary,
        items: [
          DropdownMenuItem(
            value: 'Masuk',
            child: Row(
              children: [
                Icon(Icons.login, color: Colors.green),
                const SizedBox(width: 12),
                const Text('Absen Masuk'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'Pulang',
            child: Row(
              children: [
                Icon(Icons.logout, color: Colors.orange),
                const SizedBox(width: 12),
                const Text('Absen Pulang'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'Izin',
            child: Row(
              children: [
                Icon(Icons.block, color: Colors.red),
                const SizedBox(width: 12),
                const Text('Izin / Tidak Hadir'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'Pulang Cepat',
            child: Row(
              children: [
                Icon(Icons.fast_forward, color: Colors.blue),
                const SizedBox(width: 12),
                const Text('Pulang Cepat'),
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
    );
  }

  Widget _buildKeterangan(ColorScheme cs) {
    return Container(
      decoration: _glassDecoration(),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _ketC,
        maxLines: 3,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: 'Keterangan (alasan)',
          labelStyle: const TextStyle(color: Colors.black54),
          helperText: 'Wajib diisi untuk jenis ini',
          helperStyle: const TextStyle(color: Colors.black54),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.note, color: cs.primary),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildSelfie(ColorScheme cs) {
    return Container(
      decoration: _glassDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: _pickSelfie,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.primary, width: 2),
              foregroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.camera_alt_outlined, color: cs.primary),
            label: Text(
              'Ambil Selfie (Opsional)',
              style: TextStyle(color: cs.primary),
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
    );
  }

  Widget _buildSubmitButtons(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: AnimatedScale(
            scale: _loading ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: FilledButton.icon(
              onPressed: _loading ? null : _submitPresensi,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.send, color: Colors.white),
              label: Text(
                _loading ? 'Mengirim...' : 'Kirim Presensi',
                style: const TextStyle(color: Colors.white),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _resetForm,
            icon: Icon(Icons.refresh, color: cs.primary),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(12),
            ),
            tooltip: 'Reset Form',
          ),
        ),
      ],
    );
  }
}
