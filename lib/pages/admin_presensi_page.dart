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

  @override
  void initState() {
    super.initState();
    _loadPresensi();
  }

  Future<void> _loadPresensi() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAllPresensi();
      setState(() => _items = data);
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

  Future<void> _updateStatus(String id, String status) async {
    final res = await ApiService.updatePresensiStatus(id: id, status: status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? 'Status diperbarui')),
    );
    _loadPresensi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Persetujuan Presensi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPresensi,
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _items.length,
                itemBuilder: (ctx, i) {
                  final item = _items[i];
                  final status = item['status'] ?? 'Pending';
                  Color statusColor;
                  if (status == 'Disetujui') {
                    statusColor = Colors.green;
                  } else if (status == 'Ditolak') {
                    statusColor = Colors.red;
                  } else {
                    statusColor = Colors.orange;
                  }

                  return Card(
                    child: ListTile(
                      title: Text(
                        '${item['nama_lengkap']} - ${item['jenis']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Tgl: ${item['created_at']}\nKet: ${item['keterangan'] ?? '-'}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (status == 'Pending')
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, size: 20),
                                  color: Colors.green,
                                  onPressed: () => _updateStatus(
                                    item['id'].toString(),
                                    'Disetujui',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  color: Colors.red,
                                  onPressed: () => _updateStatus(
                                    item['id'].toString(),
                                    'Ditolak',
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
