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
  String _filterJenis = 'All'; // All, Masuk, Pulang, Izin, Pulang Cepat

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal ambil histori: $e')));
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
        title: const Text('Riwayat Presensi'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        actions: [
          DropdownButton<String>(
            value: _filterJenis,
            items: [
              'All',
              'Masuk',
              'Pulang',
              'Izin',
              'Pulang Cepat',
            ].map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
            onChanged: (v) => setState(() => _filterJenis = v ?? 'All'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Total: ${_filteredItems.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada riwayat presensi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: _filteredItems.length,
                            itemBuilder: (ctx, i) {
                              final item = _filteredItems[i];
                              final status = item['status'] ?? 'Pending';
                              Color statusColor = Colors.orange;
                              if (status == 'Disetujui')
                                statusColor = Colors.green;
                              if (status == 'Ditolak') statusColor = Colors.red;

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    _getIconForJenis(item['jenis'] ?? ''),
                                    color: _getColorForJenis(
                                      item['jenis'] ?? '',
                                    ),
                                  ),
                                  title: Text(
                                    item['jenis'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Tgl: ${item['created_at'] ?? ''}'),
                                      Text('Ket: ${item['keterangan'] ?? '-'}'),
                                      Text(
                                        'Status: $status',
                                        style: TextStyle(color: statusColor),
                                      ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    status == 'Disetujui'
                                        ? Icons.check_circle
                                        : status == 'Ditolak'
                                        ? Icons.cancel
                                        : Icons.pending,
                                    color: statusColor,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  IconData _getIconForJenis(String jenis) {
    switch (jenis) {
      case 'Masuk':
        return Icons.login;
      case 'Pulang':
        return Icons.logout;
      case 'Izin':
        return Icons.block;
      case 'Pulang Cepat':
        return Icons.fast_forward;
      default:
        return Icons.schedule;
    }
  }

  Color _getColorForJenis(String jenis) {
    switch (jenis) {
      case 'Masuk':
        return Colors.green;
      case 'Pulang':
        return Colors.orange;
      case 'Izin':
        return Colors.red;
      case 'Pulang Cepat':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
