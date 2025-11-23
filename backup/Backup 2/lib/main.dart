import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

// =====================================================================
// PAGE HOME
// =====================================================================

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

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _requestPermissions();
    await _initCamera();
    await _getLocation();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.location.request();
  }

  // =====================================================================
  // INIT CAMERA FIX (NO MELAR)
  // =====================================================================

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

  // =====================================================================
  // GET LOCATION
  // =====================================================================

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);

    try {
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

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // =====================================================================
  // CAMERA TAB — FIX LAYAR MELAR
  // =====================================================================

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
                      blurRadius: 20,
                      spreadRadius: 2,
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
                      : _cameraPreviewFixed(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // CARD LOKASI
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
        ],
      ),
    );
  }

  // =====================================================================
  // FIX RATIO CAMERA — REAL INSTAGRAM SCALE (NO DISTORTION)
  // =====================================================================

  Widget _cameraPreviewFixed() {
    final controller = _cameraController!;
    final aspectRatio = controller.value.aspectRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        final screenRatio = maxW / maxH;

        // Scale agar tidak melar: kamera mengikuti sensor
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

  // =====================================================================
  // MAP TAB
  // =====================================================================

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
                  onPressed: _getLocation,
                  icon: const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.orange.withOpacity(0.4)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _currentLatLng == null
                    ? const Center(
                        child: Text(
                          "Lokasi belum ditemukan.",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : FlutterMap(
                        options: MapOptions(
                          initialCenter: _currentLatLng!,
                          initialZoom: 16,
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
        ],
      ),
    );
  }

  // =====================================================================
  // BUILD
  // =====================================================================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            "SkaduTA Presensi",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          centerTitle: true,
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
            tabs: [
              Tab(icon: Icon(Icons.camera_alt), text: "Camera"),
              Tab(icon: Icon(Icons.map), text: "Map"),
            ],
          ),
        ),
        body: TabBarView(children: [_buildCameraTab(), _buildMapTab()]),
      ),
    );
  }
}
