// pages/history_page.dart (ENHANCED: Modern UI with gradients, shadows, icons, date formatting, full-screen image viewer, sorted list, no errors; FIXED: Dropdown visibility with custom menu style)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/user_model.dart';

class HistoryPage extends StatefulWidget {
  final UserModel user;
  const HistoryPage({super.key, required this.user});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = false;
  List<dynamic> _items = [];
  String _filterJenis =
      'All'; // All, Masuk, Pulang, Izin, Pulang Cepat, Penugasan_*

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getUserHistory(widget.user.id);
      setState(() {
        _items = data ?? [];
        _items.sort(
          (a, b) =>
              DateTime.parse(
                b['created_at'] ?? DateTime.now().toIso8601String(),
              ).compareTo(
                DateTime.parse(
                  a['created_at'] ?? DateTime.now().toIso8601String(),
                ),
              ),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal ambil histori: $e',
              style: const TextStyle(fontSize: 18),
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredItems {
    if (_filterJenis == 'All') return _items;
    return _items
        .where((item) => (item['jenis'] ?? '') == _filterJenis)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Riwayat Presensi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButton<String>(
              value: _filterJenis,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              underline: const SizedBox(),
              dropdownColor: cs.primary, // Dark background for dropdown menu
              items:
                  [
                        'All',
                        'Masuk',
                        'Pulang',
                        'Izin',
                        'Pulang Cepat',
                        'Penugasan_Masuk',
                        'Penugasan_Pulang',
                        'Penugasan_Full',
                      ]
                      .map(
                        (j) => DropdownMenuItem(
                          value: j,
                          child: Text(
                            j,
                            style: const TextStyle(
                              color: Colors.white,
                            ), // White text for visibility
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _filterJenis = v ?? 'All'),
            ),
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.9),
                cs.primary.withOpacity(0.6),
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
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: Colors.blue,
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadHistory,
                child: _buildContentList(),
              ),
      ),
    );
  }

  /// List utama di dalam RefreshIndicator
  Widget _buildContentList() {
    if (_filteredItems.isEmpty) {
      // Tetap pakai ListView supaya pull-to-refresh tetap bisa
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 100,
          16,
          20,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Total: 0',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          _buildEmptyView(),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 100,
        16,
        20,
      ),
      itemCount: _filteredItems.length + 1, // +1 buat header "Total"
      itemBuilder: (ctx, index) {
        if (index == 0) {
          // Header total di paling atas
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Total: ${_filteredItems.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          );
        }

        final item = _filteredItems[index - 1];

        final status = (item['status'] ?? 'Pending').toString();
        Color statusColor = Colors.orange;
        if (status == 'Disetujui') statusColor = Colors.green;
        if (status == 'Ditolak') statusColor = Colors.red;

        final created = DateTime.parse(
          item['created_at'] ?? DateTime.now().toIso8601String(),
        );
        final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(created);

        final baseUrl = ApiService.baseUrl;

        final selfie = item['selfie'];
        final String? fotoUrl = (selfie != null && selfie.toString().isNotEmpty)
            ? '$baseUrl/selfie/$selfie'
            : null;

        final dokumen = item['dokumen'];
        final String? dokumenUrl =
            (dokumen != null && dokumen.toString().isNotEmpty)
            ? '$baseUrl/dokumen/$dokumen'
            : null;

        final informasi = item['informasi']?.toString() ?? '';

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getColorForJenis(
                          item['jenis']?.toString() ?? '',
                        ).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForJenis(item['jenis']?.toString() ?? ''),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['jenis']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Tanggal: $formattedDate',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status == 'Disetujui'
                                ? Icons.check_circle
                                : status == 'Ditolak'
                                ? Icons.cancel
                                : Icons.pending,
                            color: statusColor,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Keterangan: ${item['keterangan'] ?? '-'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (informasi.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Info: $informasi',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 12),
                if (dokumenUrl != null || fotoUrl != null)
                  Row(
                    children: [
                      if (dokumenUrl != null) ...[
                        GestureDetector(
                          onTap: () => _showDokumen(dokumenUrl),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attachment_rounded,
                                  size: 20,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Dokumen',
                                  style: TextStyle(color: Colors.blue[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (fotoUrl != null)
                        GestureDetector(
                          onTap: () => _showFullPhoto(fotoUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              fotoUrl,
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 60,
                                      width: 60,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tampilan kalau kosong
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat presensi',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Full screen photo viewer
  void _showFullPhoto(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 36),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simple dokumen viewer
  void _showDokumen(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Dokumen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 300,
                height: 300,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('Tidak dapat menampilkan dokumen'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForJenis(String jenis) {
    switch (jenis) {
      case 'Masuk':
      case 'Penugasan_Masuk':
        return Icons.login_rounded;
      case 'Pulang':
      case 'Penugasan_Pulang':
        return Icons.logout_rounded;
      case 'Izin':
        return Icons.block_rounded;
      case 'Pulang Cepat':
        return Icons.fast_forward_rounded;
      case 'Penugasan_Full':
        return Icons.assignment_turned_in_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _getColorForJenis(String jenis) {
    switch (jenis) {
      case 'Masuk':
      case 'Penugasan_Masuk':
        return Colors.green;
      case 'Pulang':
      case 'Penugasan_Pulang':
        return Colors.orange;
      case 'Izin':
        return Colors.red;
      case 'Pulang Cepat':
        return Colors.blue;
      case 'Penugasan_Full':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
