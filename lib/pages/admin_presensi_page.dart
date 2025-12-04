import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';

class AdminPresensiPage extends StatefulWidget {
  const AdminPresensiPage({super.key});

  @override
  State<AdminPresensiPage> createState() => _AdminPresensiPageState();
}

class _AdminPresensiPageState extends State<AdminPresensiPage> {
  bool _loading = false;
  List<dynamic> _items = [];
  String _filterStatus = 'All';

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

  // 🟢 FIXED: Tidak akan error meskipun text lebih pendek dari maxLength
  String _shortenText(String text, {int maxLength = 50}) {
    if (text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength.clamp(0, text.length)) + '...';
  }

  Future<void> _showDetailDialog(dynamic item) async {
    final status = item['status'] ?? 'Pending';
    final baseUrl = ApiService.baseUrl;

    final selfie = item['selfie'];
    final dokumen = item['dokumen'];

    final String? fotoUrl = selfie != null && selfie.toString().isNotEmpty
        ? '$baseUrl/selfie/$selfie'
        : null;

    final String? dokumenUrl = dokumen != null && dokumen.toString().isNotEmpty
        ? '$baseUrl/dokumen/$dokumen'
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
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item['nama_lengkap']} - ${item['jenis']}',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanggal: ${item['created_at'] ?? ''}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keterangan: ${item['keterangan'] ?? '-'}',
                  style: const TextStyle(fontSize: 18),
                ),
                if (item['informasi'] != null &&
                    item['informasi'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Informasi Penugasan: ${item['informasi']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (fotoUrl != null) ...[
                  const Text(
                    'Foto Presensi:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                        Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 32,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tidak ada foto',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                if (dokumenUrl != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Dokumen Penugasan:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showFullDokumen(dokumenUrl),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attachment,
                            color: Colors.blue,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lihat Dokumen (${item['dokumen']})',
                              style: const TextStyle(fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                    fontSize: 18,
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
                  style: TextStyle(color: Colors.green, fontSize: 18),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(item['id'].toString(), 'Ditolak');
                },
                child: const Text(
                  'Tolak',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              ),
            ] else
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup', style: TextStyle(fontSize: 18)),
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
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
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

  Future<void> _launchInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka dokumen')),
      );
    }
  }

  void _showFullDokumen(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Theme.of(context).colorScheme.primary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dokumen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.open_in_browser,
                            color: Colors.white,
                          ),
                          onPressed: () => _launchInBrowser(url),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.insert_drive_file, size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              'Dokumen tidak dapat ditampilkan di sini.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _launchInBrowser(url),
                              icon: const Icon(Icons.open_in_browser),
                              label: const Text('Buka di Browser'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            underline: const SizedBox(),
            items: ['All', 'Pending', 'Disetujui', 'Ditolak']
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, style: const TextStyle(fontSize: 18)),
                  ),
                )
                .toList(),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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

                        Color statusColor = status == 'Disetujui'
                            ? Colors.green
                            : status == 'Ditolak'
                            ? Colors.red
                            : Colors.orange;

                        final baseUrl = ApiService.baseUrl;
                        final selfie = item['selfie'];
                        final String? fotoUrl =
                            selfie != null && selfie.toString().isNotEmpty
                            ? '$baseUrl/selfie/$selfie'
                            : null;

                        final informasi = item['informasi']?.toString() ?? '';

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
                                fontSize: 18,
                              ),
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
                                    'Info: ${_shortenText(informasi)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    fontSize: 16,
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
                                    size: 20,
                                    color: Colors.orange,
                                  )
                                : Icon(
                                    status == 'Disetujui'
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: statusColor,
                                    size: 32,
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
