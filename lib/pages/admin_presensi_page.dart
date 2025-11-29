// pages/admin_presensi_page.dart (update handle response dari getAllPresensi yang sekarang return List dari data["data"])
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class AdminPresensiPage extends StatefulWidget {
  const AdminPresensiPage({super.key});
  @override
  State<AdminPresensiPage> createState() => _AdminPresensiPageState();
}

class _AdminPresensiPageState extends State<AdminPresensiPage> {
  bool _loading = false;
  List<dynamic> _items = [];
  String _filterStatus = 'All'; // All, Pending, Disetujui, Ditolak
  @override
  void initState() {
    super.initState();
    _loadPresensi();
  }

  Future<void> _loadPresensi() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAllPresensi();
      setState(() => _items = data ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ambil data presensi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredItems {
    if (_filterStatus == 'All') return _items;
    return _items
        .where((item) => (item['status'] ?? '') == _filterStatus)
        .toList();
  }

  Future<void> _showDetailDialog(dynamic item) async {
    final status = item['status'] ?? 'Pending';
    final baseUrl = ApiService.baseUrl;
    final fotoUrl = item['selfie'] != null && item['selfie'].isNotEmpty
        ? '$baseUrl/selfie/${item['selfie']}'
        : null;
    showDialog(
      context: context,
      builder: (context) => AnimatedPadding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                status == 'Disetujui'
                    ? Icons.check_circle
                    : status == 'Ditolak'
                    ? Icons.cancel
                    : Icons.pending,
                color: status == 'Disetujui'
                    ? Colors.green
                    : status == 'Ditolak'
                    ? Colors.red
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${item['nama_lengkap']} - ${item['jenis']}'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal: ${item['created_at'] ?? ''}'),
                const SizedBox(height: 8),
                Text('Keterangan: ${item['keterangan'] ?? '-'}'),
                const SizedBox(height: 8),
                if (fotoUrl != null) ...[
                  const Text(
                    'Foto Presensi:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showFullPhoto(fotoUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        fotoUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.error,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.image_not_supported, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Tidak ada foto',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Status Saat Ini: $status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: status == 'Disetujui'
                        ? Colors.green
                        : status == 'Ditolak'
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (status == 'Pending') ...[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(item['id'].toString(), 'Disetujui');
                },
                child: const Text(
                  'Setujui',
                  style: TextStyle(color: Colors.green),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(item['id'].toString(), 'Ditolak');
                },
                child: const Text('Tolak', style: TextStyle(color: Colors.red)),
              ),
            ] else
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullPhoto(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
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
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      final res = await ApiService.updatePresensiStatus(id: id, status: status);
      if (res['status'] == true) {
        // Konsisten dengan PHP response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Status diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal update status')),
        );
      }
      _loadPresensi();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan Presensi'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          DropdownButton<String>(
            value: _filterStatus,
            items: [
              'All',
              'Pending',
              'Disetujui',
              'Ditolak',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _filterStatus = v ?? 'All'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Total: ${_filteredItems.length}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadPresensi,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredItems.length,
                      itemBuilder: (ctx, i) {
                        final item = _filteredItems[i];
                        final status = item['status'] ?? 'Pending';
                        Color statusColor;
                        if (status == 'Disetujui') {
                          statusColor = Colors.green;
                        } else if (status == 'Ditolak') {
                          statusColor = Colors.red;
                        } else {
                          statusColor = Colors.orange;
                        }
                        final baseUrl = ApiService.baseUrl;
                        final fotoUrl =
                            item['selfie'] != null && item['selfie'].isNotEmpty
                            ? '$baseUrl/selfie/${item['selfie']}'
                            : null;
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            onTap: () => _showDetailDialog(item),
                            title: Text(
                              '${item['nama_lengkap'] ?? ''} - ${item['jenis'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tgl: ${item['created_at'] ?? ''}'),
                                Text('Ket: ${item['keterangan'] ?? '-'}'),
                                Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                if (fotoUrl != null) ...[
                                  const SizedBox(height: 4),
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
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                height: 60,
                                                width: 60,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  height: 60,
                                                  width: 60,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
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
                              ],
                            ),
                            trailing: status == 'Pending'
                                ? const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.orange,
                                  )
                                : Icon(
                                    status == 'Disetujui'
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: statusColor,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
