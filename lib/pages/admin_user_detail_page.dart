// lib/pages/admin_user_detail_page.dart
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class AdminUserDetailPage extends StatefulWidget {
  const AdminUserDetailPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _loading = true;
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
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // 1. Riwayat user
      final historyData = await ApiService.getUserHistory(widget.userId);
      if (mounted) setState(() => _history = historyData ?? []);

      // 2. Cari presensi yang masih pending
      final allPresensi = await ApiService.getAllPresensi();
      final pending = allPresensi
          .where(
            (p) =>
                p['user_id'].toString() == widget.userId &&
                (p['status'] ?? '').toString() == 'Pending',
          )
          .toList();

      if (mounted) setState(() => _pendingPresensi = pending);
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

      if (!mounted) return;

      final message = res['message'] ?? 'Status diperbarui';
      final isSuccess = res['status'] == true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );

      if (isSuccess) _loadData(); // Refresh hanya jika sukses
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Foto fullscreen
  void _showFullPhoto(String? url) {
    if (url == null || url.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain, // ← ERROR DI SINI SUDAH DIPERBAIKI
                ),
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

  // Dokumen fullscreen
  void _showFullDokumen(String? url) {
    if (url == null || url.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: Colors.red, size: 60),
                SizedBox(height: 16),
                Text(
                  'Gagal memuat dokumen',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Belum ada riwayat presensi',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (_, i) {
          final item = _history[i];
          final status = item['status'] ?? 'Pending';
          final Color statusColor = status == 'Disetujui'
              ? Colors.green
              : status == 'Ditolak'
              ? Colors.red
              : Colors.orange;

          final baseUrl = ApiService.baseUrl;
          final fotoUrl = item['selfie']?.toString().isNotEmpty == true
              ? '$baseUrl/selfie/${item['selfie']}'
              : null;
          final dokumenUrl = item['dokumen']?.toString().isNotEmpty == true
              ? '$baseUrl/dokumen/${item['dokumen']}'
              : null;

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                item['jenis'] ?? 'Tidak ada jenis',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text('Tanggal: ${item['created_at'] ?? '-'}'),
                  Text('Keterangan: ${item['keterangan'] ?? '-'}'),
                  if (item['informasi']?.toString().isNotEmpty == true)
                    Text('Info: ${item['informasi']}'),
                  const SizedBox(height: 4),
                  Text(
                    'Status: $status',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (fotoUrl != null)
                        GestureDetector(
                          onTap: () => _showFullPhoto(fotoUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              fotoUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (dokumenUrl != null) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showFullDokumen(dokumenUrl),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attachment,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Dokumen',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
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
                size: 36,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_pendingPresensi.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending_actions, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tidak ada presensi pending',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingPresensi.length,
        itemBuilder: (_, i) {
          final item = _pendingPresensi[i];
          final baseUrl = ApiService.baseUrl;
          final fotoUrl = item['selfie']?.toString().isNotEmpty == true
              ? '$baseUrl/selfie/${item['selfie']}'
              : null;
          final dokumenUrl = item['dokumen']?.toString().isNotEmpty == true
              ? '$baseUrl/dokumen/${item['dokumen']}'
              : null;

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                item['jenis'] ?? 'Tidak ada jenis',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text('Tanggal: ${item['created_at'] ?? '-'}'),
                  Text('Keterangan: ${item['keterangan'] ?? '-'}'),
                  if (item['informasi']?.toString().isNotEmpty == true)
                    Text('Info: ${item['informasi']}'),
                  const SizedBox(height: 4),
                  const Text(
                    'Status: Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (fotoUrl != null)
                        GestureDetector(
                          onTap: () => _showFullPhoto(fotoUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              fotoUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      if (dokumenUrl != null) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showFullDokumen(dokumenUrl),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.attachment, color: Colors.blue),
                                SizedBox(width: 6),
                                Text(
                                  'Dokumen',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 36,
                    ),
                    onPressed: () =>
                        _updateStatus(item['id'].toString(), 'Disetujui'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 36),
                    onPressed: () =>
                        _updateStatus(item['id'].toString(), 'Ditolak'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Riwayat Presensi'),
            Tab(text: 'Konfirmasi Pending'),
          ],
        ),
      ),
      body: _loading && _history.isEmpty && _pendingPresensi.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildHistoryTab(), _buildPendingTab()],
            ),
    );
  }
}
