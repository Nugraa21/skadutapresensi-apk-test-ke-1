import 'dart:convert'; // Import untuk jsonEncode
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class AdminUserDetailPage extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminUserDetailPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  List<dynamic> _history = [];
  List<dynamic> _pendingPresensi = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final historyData = await ApiService.getUserHistory(widget.userId);
      setState(() => _history = historyData);

      final allPresensi = await ApiService.getAllPresensi();
      final pending = allPresensi
          .where(
            (p) =>
                p['user_id'] == widget.userId &&
                (p['status'] ?? '') == 'Pending',
          )
          .toList();
      setState(() => _pendingPresensi = pending);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      print('DEBUG UPDATE: Starting approve for ID=$id, status=$status');
      final res = await ApiService.updatePresensiStatus(id: id, status: status);
      print('DEBUG UPDATE: Full response received: $res'); // Print Map langsung

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Status diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Reload tab
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal update status')),
        );
      }
    } catch (e) {
      print('DEBUG UPDATE: Exception caught: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approve: $e')));
    }
  }

  void _showFullPhoto(String? url) {
    if (url == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(
              top: 8,
              right: 8,
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

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada riwayat presensi',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _history.length,
      itemBuilder: (ctx, i) {
        final item = _history[i];
        final status = item['status'] ?? 'Pending';
        Color statusColor = Colors.orange;
        if (status == 'Disetujui') statusColor = Colors.green;
        if (status == 'Ditolak') statusColor = Colors.red;

        final baseUrl = ApiService.baseUrl;
        final fotoUrl = item['selfie'] != null && item['selfie'].isNotEmpty
            ? '$baseUrl/selfie/${item['selfie']}'
            : null;

        return Card(
          child: ListTile(
            title: Text(
              item['jenis'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tgl: ${item['created_at']}'),
                Text('Ket: ${item['keterangan'] ?? '-'}'),
                Text('Status: $status', style: TextStyle(color: statusColor)),
                if (fotoUrl != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showFullPhoto(fotoUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
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
                            borderRadius: BorderRadius.circular(4),
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
    );
  }

  Widget _buildPendingTab() {
    if (_pendingPresensi.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada presensi pending',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _pendingPresensi.length,
      itemBuilder: (ctx, i) {
        final item = _pendingPresensi[i];
        final baseUrl = ApiService.baseUrl;
        final fotoUrl = item['selfie'] != null && item['selfie'].isNotEmpty
            ? '$baseUrl/selfie/${item['selfie']}'
            : null;

        return Card(
          child: ListTile(
            title: Text(
              item['jenis'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tgl: ${item['created_at']}'),
                Text('Ket: ${item['keterangan'] ?? '-'}'),
                const Text('Status: Pending'),
                if (fotoUrl != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showFullPhoto(fotoUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
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
                            borderRadius: BorderRadius.circular(4),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () =>
                      _updateStatus(item['id'].toString(), 'Disetujui'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () =>
                      _updateStatus(item['id'].toString(), 'Ditolak'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Riwayat Presensi'),
            Tab(text: 'Konfirmasi Pending'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildHistoryTab(), _buildPendingTab()],
            ),
    );
  }
}
