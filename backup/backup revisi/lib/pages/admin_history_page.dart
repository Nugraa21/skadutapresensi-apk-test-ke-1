import 'package:flutter/material.dart';
import '../api/api_service.dart';
// import '../api/api_html_adapter.dart';

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  List<dynamic> _history = [];
  bool _loading = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadAllHistory();
  }

  Future<void> _loadAllHistory() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAllPresensi();
      setState(() => _history = data ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal load history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredHistory {
    var filtered = _history;
    if (_startDate != null) {
      filtered = filtered
          .where(
            (h) => DateTime.parse(h['created_at'] ?? '').isAfter(_startDate!),
          )
          .toList();
    }
    if (_endDate != null) {
      filtered = filtered
          .where(
            (h) => DateTime.parse(h['created_at'] ?? '').isBefore(_endDate!),
          )
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rekap Presensi Semua User"),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllHistory,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'filter') {
                _showDateFilter();
              } else if (value == 'clear') {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Text('Filter Tanggal'),
              ),
              const PopupMenuItem(value: 'clear', child: Text('Clear Filter')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllHistory,
              child: _filteredHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada history presensi',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredHistory.length,
                      itemBuilder: (context, index) {
                        final h = _filteredHistory[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primary.withOpacity(0.2),
                              child: Text(
                                (h['nama_lengkap'] ?? '?')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(color: cs.primary),
                              ),
                            ),
                            title: Text(h['nama_lengkap'] ?? 'Unknown'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Jenis: ${h['jenis'] ?? ''}"),
                                Text("Tanggal: ${h['created_at'] ?? ''}"),
                                Text("Ket: ${h['keterangan'] ?? '-'}"),
                                Text("Status: ${h['status'] ?? 'Pending'}"),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  void _showDateFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Tanggal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _startDate = date);
                Navigator.pop(context);
              },
              child: const Text('Pilih Tanggal Mulai'),
            ),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _endDate = date);
                Navigator.pop(context);
              },
              child: const Text('Pilih Tanggal Selesai'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
