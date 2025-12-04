// pages/rekap_page.dart
// REKAP + EXPORT EXCEL (SUDAH FIX ERROR ExcelColor + TAMPILAN KEREN BANGET)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class RekapPage extends StatefulWidget {
  const RekapPage({super.key});
  @override
  State<RekapPage> createState() => _RekapPageState();
}

class _RekapPageState extends State<RekapPage> with TickerProviderStateMixin {
  bool _loading = false;
  List<dynamic> _data = [];
  String _month = DateTime.now().month.toString().padLeft(2, '0');
  String _year = DateTime.now().year.toString();

  Map<String, List<Map<String, dynamic>>> _perUser = {};
  Map<String, Map<String, String>> _pivot = {};
  List<String> _dates = [];

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadRekap();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadRekap() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getRekap(month: _month, year: _year);
      setState(() => _data = data);
      _processData();
      _animController.forward(from: 0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal load data: $e'),
          backgroundColor: Colors.red.shade600,
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
      final nama = item['nama_lengkap'] ?? 'Tanpa Nama';
      final rawDate = item['created_at'] ?? '';
      final tgl = rawDate.length >= 10 ? rawDate.substring(0, 10) : '';
      final jenis = item['jenis'] ?? '-';
      final status = item['status'] ?? 'Pending';
      final ket = item['keterangan'] ?? '-';

      _perUser.putIfAbsent(nama, () => []);
      _perUser[nama]!.add({
        'tgl': tgl,
        'jenis': jenis,
        'status': status,
        'ket': ket,
      });

      _pivot.putIfAbsent(nama, () => {});
      _pivot[nama]![tgl] = jenis;

      if (tgl.isNotEmpty && !_dates.contains(tgl)) _dates.add(tgl);
    }
    _dates.sort();
  }

  // EXPORT TO EXCEL – SUDAH SESUAI excel ^4.0.6+
  Future<void> _exportToExcel() async {
    if (_data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data kosong!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Izin penyimpanan
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin penyimpanan ditolak!')),
        );
        return;
      }
    }

    var excel = Excel.createExcel();
    Sheet sheet = excel['Rekap Absensi'];

    // Header
    sheet.appendRow([
      TextCellValue("No"),
      TextCellValue("Nama"),
      TextCellValue("Tanggal"),
      TextCellValue("Jenis"),
      TextCellValue("Status"),
      TextCellValue("Keterangan"),
    ]);

    // Styling Header – FIX: Pakai ExcelColor.fromHex()
    CellStyle headerStyle = CellStyle(
      bold: true,
      // backgroundColor: ExcelColor.fromHex("#1565C0"),
      // fontColor: ExcelColor.fromHex("#FFFFFF"),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    for (var i = 0; i < 6; i++) {
      var cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = cell.value;
      cell.cellStyle = headerStyle;
    }

    // Isi data
    int no = 1;
    for (var item in _data) {
      final nama = item['nama_lengkap'] ?? 'Unknown';
      final tgl = item['created_at']?.toString().substring(0, 10) ?? '-';
      final jenis = item['jenis'] ?? '-';
      final status = item['status'] ?? 'Pending';
      final ket = item['keterangan'] ?? '-';

      sheet.appendRow([
        TextCellValue(no.toString()),
        TextCellValue(nama),
        TextCellValue(tgl),
        TextCellValue(jenis),
        TextCellValue(status),
        TextCellValue(ket),
      ]);
      no++;
    }

    // Simpan ke folder Downloads
    final directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) await directory.create(recursive: true);

    final fileName = "Rekap_Absensi_$_month-$_year.xlsx";
    final path = "${directory.path}/$fileName";

    final fileBytes = excel.encode()!;
    await File(path).writeAsBytes(fileBytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Berhasil disimpan di folder Downloads!"),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: "BUKA",
          textColor: Colors.yellow,
          onPressed: () => OpenFile.open(path),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Rekap Absensi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 30),
            onPressed: _loadRekap,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 30),
            onPressed: _exportToExcel,
            tooltip: "Export ke Excel",
          ),
          const SizedBox(width: 10),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.95),
                cs.primary.withOpacity(0.7),
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
            colors: [cs.primary.withOpacity(0.08), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 5))
            : _data.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Belum ada data absensi",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
                child: Column(
                  children: [
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.cyan.shade500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _infoCard(
                              "Total Absen",
                              _data.length.toString(),
                              Icons.bar_chart,
                            ),
                            _infoCard(
                              "Periode",
                              DateFormat('MMMM yyyy').format(
                                DateTime(int.parse(_year), int.parse(_month)),
                              ),
                              Icons.calendar_today,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Detail Per Siswa",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPerUserTable(),
                    const SizedBox(height: 30),
                    const Text(
                      "Tabel Harian (Pivot)",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPivotTable(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 36, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPerUserTable() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _perUser.length,
          itemBuilder: (ctx, i) {
            final nama = _perUser.keys.elementAt(i);
            final items = _perUser[nama]!;
            return Opacity(
              opacity: _animController.value,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - _animController.value)),
                child: Card(
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade700,
                      child: Text(
                        nama[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      "${items.length} transaksi",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    children: items
                        .map(
                          (e) => ListTile(
                            leading: _jenisIcon(e['jenis']),
                            title: Text("${e['tgl']} → ${e['jenis']}"),
                            subtitle: Text(
                              "Status: ${e['status']} | ${e['ket']}",
                            ),
                            trailing: _statusBadge(e['status']),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _jenisIcon(String jenis) {
    if (jenis == 'Masuk') return const Icon(Icons.login, color: Colors.green);
    if (jenis == 'Pulang')
      return const Icon(Icons.logout, color: Colors.orange);
    if (jenis.contains('Izin'))
      return const Icon(Icons.sick, color: Colors.red);
    if (jenis.contains('Penugasan'))
      return const Icon(Icons.assignment_turned_in, color: Colors.purple);
    return const Icon(Icons.help_outline, color: Colors.grey);
  }

  Widget _statusBadge(String status) {
    Color color = status == 'Disetujui'
        ? Colors.green
        : status == 'Pending'
        ? Colors.orange
        : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPivotTable() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.blue.shade700),
          columns: [
            const DataColumn(
              label: Text(
                'Nama',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ..._dates.map(
              (d) => DataColumn(
                label: Text(
                  d.substring(8, 10),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          rows: _pivot.keys.map((nama) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ..._dates.map((d) {
                  final val = _pivot[nama]![d] ?? '';
                  return DataCell(
                    Center(
                      child: val.isEmpty
                          ? const Text(
                              '-',
                              style: TextStyle(color: Colors.grey),
                            )
                          : Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: val == 'Masuk'
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                val[0],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: val == 'Masuk'
                                      ? Colors.green.shade900
                                      : Colors.orange.shade900,
                                ),
                              ),
                            ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
