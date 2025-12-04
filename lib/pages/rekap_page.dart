// pages/rekap_page.dart (NEW: Rekap page with per user table and pivot summary)
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class RekapPage extends StatefulWidget {
  const RekapPage({super.key});
  @override
  State<RekapPage> createState() => _RekapPageState();
}

class _RekapPageState extends State<RekapPage> {
  bool _loading = false;
  List<dynamic> _data = [];
  String _month = DateTime.now().month.toString().padLeft(2, '0');
  String _year = DateTime.now().year.toString();
  Map<String, List<Map<String, dynamic>>> _perUser = {};
  Map<String, Map<String, String>> _pivot = {};
  List<String> _dates = [];
  @override
  void initState() {
    super.initState();
    _loadRekap();
  }

  Future<void> _loadRekap() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getRekap(month: _month, year: _year);
      setState(() => _data = data);
      _processData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal ambil rekap: $e',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _processData() {
    _perUser.clear();
    _pivot.clear();
    _dates.clear();
    for (var item in _data) {
      final nama = item['nama_lengkap'] ?? 'Unknown';
      final tgl = item['created_at'].substring(0, 10);
      final jenis = item['jenis'] ?? '';
      final status = item['status'] ?? 'Pending';
      final ket = item['keterangan'] ?? '-';
      _perUser.putIfAbsent(nama, () => []);
      _perUser[nama]!.add({
        'tgl': tgl,
        'jenis': jenis,
        'status': status,
        'ket': ket,
      });
      // For pivot
      _pivot.putIfAbsent(nama, () => {});
      _pivot[nama]![tgl] = jenis; // Simple: show jenis per date
      if (!_dates.contains(tgl)) _dates.add(tgl);
    }
    _dates.sort(); // Sort dates
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Absensi', style: TextStyle(fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            onPressed: _loadRekap,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Rekap Per User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPerUserTable(),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Summary Pivot',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPivotTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildPerUserTable() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _perUser.length,
      itemBuilder: (ctx, i) {
        final nama = _perUser.keys.elementAt(i);
        final items = _perUser[nama]!;
        return ExpansionTile(
          title: Text(nama, style: const TextStyle(fontSize: 18)),
          children: items
              .map(
                (item) => ListTile(
                  title: Text(
                    'Tgl: ${item['tgl']} - Jenis: ${item['jenis']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  subtitle: Text(
                    'Status: ${item['status']} - Ket: ${item['ket']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildPivotTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Nama', style: TextStyle(fontSize: 18))),
          ..._dates.map(
            (tgl) => DataColumn(
              label: Text(tgl, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
        rows: _pivot.keys.map((nama) {
          return DataRow(
            cells: [
              DataCell(Text(nama, style: const TextStyle(fontSize: 16))),
              ..._dates.map(
                (tgl) => DataCell(
                  Text(
                    _pivot[nama]![tgl] ?? '-',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
