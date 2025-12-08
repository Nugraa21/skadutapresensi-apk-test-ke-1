import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

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
      setState(() {
        _history = data ?? [];
        _history.sort(
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
            content: Text('Gagal load history: $e'),
            backgroundColor: Colors.red.shade600,
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
      filtered = filtered.where((h) {
        final created = DateTime.parse(
          h['created_at'] ?? DateTime.now().toIso8601String(),
        );
        return !created.isBefore(_startDate!);
      }).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((h) {
        final created = DateTime.parse(
          h['created_at'] ?? DateTime.now().toIso8601String(),
        );
        return !created.isAfter(_endDate!);
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Rekap Presensi Semua User",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 28),
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
                child: Row(
                  children: [
                    Icon(Icons.date_range),
                    SizedBox(width: 8),
                    Text('Filter Tanggal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Filter'),
                  ],
                ),
              ),
            ],
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
                onRefresh: _loadAllHistory,
                child: _filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _startDate != null || _endDate != null
                                  ? 'Tidak ada data di periode ini'
                                  : 'Belum ada history presensi',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final h = _filteredHistory[index];
                                final created = DateTime.parse(
                                  h['created_at'] ??
                                      DateTime.now().toIso8601String(),
                                );
                                final formattedDate = DateFormat(
                                  'dd MMM yyyy HH:mm',
                                ).format(created);
                                final status = h['status'] ?? 'Pending';
                                final statusColor = status == 'Disetujui'
                                    ? Colors.green
                                    : status == 'Ditolak'
                                    ? Colors.red
                                    : Colors.orange;
                                final jenisIcon = _getJenisIcon(
                                  h['jenis'] ?? '',
                                );

                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: cs.primary.withOpacity(
                                        0.1,
                                      ),
                                      child:
                                          jenisIcon ??
                                          Text(
                                            (h['nama_lengkap'] ?? '?')[0]
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: cs.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    ),
                                    title: Text(
                                      h['nama_lengkap'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Jenis: ${h['jenis'] ?? ''}",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          "Tanggal: $formattedDate",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          "Ket: ${h['keterangan'] ?? '-'}",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            "Status: $status",
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
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
                              }, childCount: _filteredHistory.length),
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }

  Icon? _getJenisIcon(String jenis) {
    return switch (jenis) {
      'Masuk' => Icon(Icons.login_rounded, color: Colors.green, size: 24),
      'Pulang' => Icon(Icons.logout_rounded, color: Colors.orange, size: 24),
      'Izin' => Icon(Icons.sick_rounded, color: Colors.red, size: 24),
      'Penugasan' => Icon(
        Icons.assignment_rounded,
        color: Colors.purple,
        size: 24,
      ),
      _ => null,
    };
  }

  void _showDateFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.date_range_rounded),
            SizedBox(width: 8),
            Text('Filter Tanggal'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null && mounted) setState(() => _startDate = date);
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.date_range),
              label: Text(
                _startDate == null
                    ? 'Pilih Tanggal Mulai'
                    : DateFormat('dd MMM yyyy').format(_startDate!),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null && mounted) setState(() => _endDate = date);
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.date_range),
              label: Text(
                _endDate == null
                    ? 'Pilih Tanggal Selesai'
                    : DateFormat('dd MMM yyyy').format(_endDate!),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
              ),
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
