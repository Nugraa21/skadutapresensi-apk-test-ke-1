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

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getUserHistory(widget.user.id);
      setState(() => _items = data);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Presensi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _items.length,
                itemBuilder: (ctx, i) {
                  final item = _items[i];
                  return Card(
                    child: ListTile(
                      title: Text(
                        item['jenis'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Tgl: ${item['created_at']}\nKet: ${item['keterangan'] ?? '-'}\nStatus: ${item['status']}',
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
