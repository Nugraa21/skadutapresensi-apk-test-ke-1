// admin_user_detail_page.dart - Halaman detail user: Histori presensi + konfirmasi absensi per user
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
      // Load histori presensi user
      final historyData = await ApiService.getUserHistory(widget.userId);
      setState(() => _history = historyData);

      // Load pending presensi (filter dari getAllPresensi, atau endpoint baru)
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
      final res = await ApiService.updatePresensiStatus(id: id, status: status);
      if (res['status'] == true) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
              ],
            ),
            trailing: item['selfie'] != null && item['selfie'].isNotEmpty
                ? const Icon(Icons.image, size: 20)
                : null,
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
