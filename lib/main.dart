// test aja
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkaduTA Presensi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ===============================================================
// MODEL PHOTO
// ===============================================================

class Photo {
  final int id;
  final String fileName;
  final String filePath;
  final double? latitude;
  final double? longitude;
  final String? capturedAt;
  final String? label;
  final String imageUrl;

  Photo({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.imageUrl,
    this.latitude,
    this.longitude,
    this.capturedAt,
    this.label,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: int.parse(json['id'].toString()),
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
      imageUrl: json['image_url'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      capturedAt: json['captured_at']?.toString(),
      label: json['label']?.toString(),
    );
  }
}

// ===============================================================
// HOME PAGE
// ===============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _cameraIndex = 0;

  LatLng? _currentLatLng;
  bool _isGettingLocation = false;
  bool _isInitCamera = false;
  bool _isUploading = false;
  String? _lastUploadStatus;

  // API base URL (IP laptopmu)
  static const String _baseUrl = "http://10.10.73.67/backendapk";
  static const String _uploadUrl = "$_baseUrl/upload_photo.php";
  static const String _getPhotosUrl = "$_baseUrl/get_photos.php";
  static const String _deletePhotoUrl = "$_baseUrl/delete_photo.php";
  static const String _updatePhotoUrl = "$_baseUrl/update_photo.php";

  List<Photo> _photos = [];
  bool _isLoadingPhotos = false;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _requestPermissions();
    await _initCamera();
    await _getLocation();
    await _fetchPhotos();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.location.request();
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> _initCamera() async {
    try {
      setState(() => _isInitCamera = true);

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _isInitCamera = false);
        return;
      }

      _cameraController = CameraController(
        _cameras![_cameraIndex],
        ResolutionPreset.max,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isInitCamera = false);
    } catch (e) {
      debugPrint("Camera error: $e");
      setState(() => _isInitCamera = false);
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    _cameraIndex = _cameraIndex == 0 ? 1 : 0;

    await _cameraController?.dispose();
    await _initCamera();
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("GPS belum aktif, nyalakan dulu ya 😊"),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Izin lokasi ditolak. Aktifkan di pengaturan."),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentLatLng = LatLng(pos.latitude, pos.longitude);
        _isGettingLocation = false;
      });
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() => _isGettingLocation = false);
    }
  }

  String get _locationText {
    if (_currentLatLng == null) {
      return "Lokasi belum diambil";
    }
    return "Lat: ${_currentLatLng!.latitude.toStringAsFixed(6)}, "
        "Lng: ${_currentLatLng!.longitude.toStringAsFixed(6)}";
  }

  // ============================================================
  // UPLOAD PHOTO (CREATE)
  // ============================================================

  Future<void> _takePhotoAndUpload() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isUploading) {
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _lastUploadStatus = null;
      });

      if (_currentLatLng == null) {
        await _getLocation();
      }

      final picture = await _cameraController!.takePicture();
      final file = File(picture.path);

      final lat = _currentLatLng?.latitude.toString() ?? "";
      final lng = _currentLatLng?.longitude.toString() ?? "";

      final uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest("POST", uri);

      request.files.add(await http.MultipartFile.fromPath("image", file.path));
      request.fields["latitude"] = lat;
      request.fields["longitude"] = lng;
      request.fields["captured_at"] = DateTime.now().toIso8601String();
      request.fields["label"] = "Presensi ${DateTime.now().toLocal()}";

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint("UPLOAD RESPONSE: $responseBody");

      if (response.statusCode == 200) {
        setState(() => _lastUploadStatus = "Upload berhasil!");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Foto berhasil diupload")));
        await _fetchPhotos(); // refresh gallery
      } else {
        setState(
          () => _lastUploadStatus = "Upload gagal (${response.statusCode})",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload gagal (${response.statusCode})")),
        );
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error upload")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ============================================================
  // FETCH PHOTOS (READ)
  // ============================================================

  Future<void> _fetchPhotos() async {
    try {
      setState(() => _isLoadingPhotos = true);
      final uri = Uri.parse(_getPhotosUrl);
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          final List list = data['data'] ?? [];
          _photos = list.map((e) => Photo.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint("Fetch photos error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingPhotos = false);
    }
  }

  // ============================================================
  // DELETE PHOTO (DELETE)
  // ============================================================

  Future<void> _deletePhoto(Photo photo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Foto"),
        content: const Text("Yakin ingin menghapus foto ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.post(
        Uri.parse(_deletePhotoUrl),
        body: {"id": photo.id.toString()},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Foto berhasil dihapus")));
        await _fetchPhotos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal hapus (${res.statusCode})")),
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  // ============================================================
  // UPDATE PHOTO LABEL (UPDATE)
  // ============================================================

  Future<void> _editPhotoLabel(Photo photo) async {
    final controller = TextEditingController(text: photo.label ?? "");

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ubah Label Foto"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Label",
            hintText: "Contoh: Presensi Pagi",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      final res = await http.post(
        Uri.parse(_updatePhotoUrl),
        body: {"id": photo.id.toString(), "label": result},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Label berhasil diupdate")),
        );
        await _fetchPhotos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal update (${res.statusCode})")),
        );
      }
    } catch (e) {
      debugPrint("Update label error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ============================================================
  // CAMERA TAB UI
  // ============================================================

  Widget _buildCameraTab() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Color(0xFF181818)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child:
                      _isInitCamera ||
                          _cameraController == null ||
                          !_cameraController!.value.isInitialized
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orangeAccent,
                          ),
                        )
                      : Stack(
                          children: [
                            _cameraPreviewFixed(),
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: IconButton(
                                  onPressed: _switchCamera,
                                  icon: const Icon(
                                    Icons.cameraswitch,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF202020),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.orange.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.location_on, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _locationText,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                IconButton(
                  onPressed: _isGettingLocation ? null : _getLocation,
                  icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _takePhotoAndUpload,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              label: Text(
                _isUploading ? "Mengupload..." : "Ambil Foto & Upload",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_lastUploadStatus != null) ...[
            const SizedBox(height: 8),
            Text(
              _lastUploadStatus!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cameraPreviewFixed() {
    final controller = _cameraController!;
    final aspectRatio = controller.value.aspectRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final screenRatio = maxW / maxH;
        double scale = aspectRatio / screenRatio;
        if (scale < 1) scale = 1 / scale;

        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: CameraPreview(controller),
        );
      },
    );
  }

  // ============================================================
  // MAP TAB
  // ============================================================

  Widget _buildMapTab() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF101010), Color(0xFF1C1C1C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                const Text(
                  "Live Location Map",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isGettingLocation ? null : _getLocation,
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  tooltip: "Refresh lokasi",
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.orange.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _currentLatLng == null
                    ? Center(
                        child: _isGettingLocation
                            ? const CircularProgressIndicator(
                                color: Colors.orangeAccent,
                              )
                            : const Text(
                                "Lokasi belum ditemukan.\nTap icon lokasi untuk refresh.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                      )
                    : FlutterMap(
                        options: MapOptions(
                          initialCenter: _currentLatLng!,
                          initialZoom: 17,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.skadutapresensi',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentLatLng!,
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.location_pin,
                                  size: 50,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ============================================================
  // GALLERY TAB (CRUD UI)
  // ============================================================

  Widget _buildGalleryTab() {
    if (_isLoadingPhotos) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      );
    }

    if (_photos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchPhotos,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Center(
              child: Text(
                "Belum ada foto tersimpan",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPhotos,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          return Card(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  photo.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white54),
                ),
              ),
              title: Text(
                photo.label ?? "Foto #${photo.id}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photo.latitude != null && photo.longitude != null)
                    Text(
                      "Lat: ${photo.latitude!.toStringAsFixed(6)}, Lng: ${photo.longitude!.toStringAsFixed(6)}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  if (photo.capturedAt != null)
                    Text(
                      "Captured: ${photo.capturedAt}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                    onPressed: () => _editPhotoLabel(photo),
                    tooltip: "Edit label",
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deletePhoto(photo),
                    tooltip: "Hapus",
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "SkaduTA Presensi",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B00), Color(0xFFFFA726)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.camera_alt), text: "Camera"),
              Tab(icon: Icon(Icons.map), text: "Map"),
              Tab(icon: Icon(Icons.photo_library), text: "Gallery"),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildCameraTab(), _buildMapTab(), _buildGalleryTab()],
        ),
      ),
    );
  }
}
