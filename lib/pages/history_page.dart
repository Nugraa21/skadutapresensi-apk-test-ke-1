// pages/history_page.dart (UPDATED: Handle new fields informasi and dokumen; simplified UI)
import 'package:flutter/material.dart';
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
      setState(() => _items = data ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal ambil histori: $e',
              style: const TextStyle(fontSize: 18),
            ),
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
      appBar: AppBar(
        title: const Text('Riwayat Presensi', style: TextStyle(fontSize: 22)),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          DropdownButton<String>(
            value: _filterJenis,
            underline: const SizedBox(),
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
                        child: Text(j, style: const TextStyle(fontSize: 18)),
                      ),
                    )
                    .toList(),
            onChanged: (v) => setState(() => _filterJenis = v ?? 'All'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              // RefreshIndicator butuh child yang scrollable,
              // jadi kita pakai ListView sebagai root.
              child: _buildContentList(),
            ),
    );
  }

  /// List utama di dalam RefreshIndicator
  Widget _buildContentList() {
    if (_filteredItems.isEmpty) {
      // Tetap pakai ListView supaya pull-to-refresh tetap bisa
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length + 1, // +1 buat header "Total"
      itemBuilder: (ctx, index) {
        if (index == 0) {
          // Header total di paling atas
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Total: ${_filteredItems.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          );
        }

        final item = _filteredItems[index - 1];

        final status = (item['status'] ?? 'Pending').toString();
        Color statusColor = Colors.orange;
        if (status == 'Disetujui') statusColor = Colors.green;
        if (status == 'Ditolak') statusColor = Colors.red;

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
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(
              _getIconForJenis(item['jenis']?.toString() ?? ''),
              color: _getColorForJenis(item['jenis']?.toString() ?? ''),
              size: 32,
            ),
            title: Text(
              item['jenis']?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tgl: ${item['created_at'] ?? ''}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Ket: ${item['keterangan'] ?? '-'}',
                  style: const TextStyle(fontSize: 16),
                ),
                if (informasi.isNotEmpty)
                  Text(
                    'Info: $informasi',
                    style: const TextStyle(fontSize: 16),
                  ),
                Text(
                  'Status: $status',
                  style: TextStyle(color: statusColor, fontSize: 16),
                ),
                if (dokumenUrl != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showDokumen(dokumenUrl),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attachment, size: 20, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Dokumen',
                            style: TextStyle(fontSize: 16, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (fotoUrl != null) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fotoUrl,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 60,
                          width: 60,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
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
                ],
              ],
            ),
            trailing: Icon(
              status == 'Disetujui'
                  ? Icons.check_circle
                  : status == 'Ditolak'
                  ? Icons.cancel
                  : Icons.pending,
              color: statusColor,
              size: 32,
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
        children: const [
          Icon(Icons.history, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Belum ada riwayat presensi',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Simple dokumen viewer
  void _showDokumen(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Dokumen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 300,
                height: 300,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text('Tidak dapat menampilkan dokumen'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
        return Icons.login;
      case 'Pulang':
      case 'Penugasan_Pulang':
        return Icons.logout;
      case 'Izin':
        return Icons.block;
      case 'Pulang Cepat':
        return Icons.fast_forward;
      case 'Penugasan_Full':
        return Icons.assignment_turned_in;
      default:
        return Icons.schedule;
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
