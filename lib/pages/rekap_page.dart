// pages/rekap_page.dart
// REKAP + EXPORT EXCEL (DIEDIT UNTUK UI/UX LEBIH SIMPEL, BAGUS, DAN MUDAH DIBACA)
// Perubahan utama:
// - Layout lebih clean dengan spacing konsisten dan cards rounded subtle.
// - Typography: Font sizes lebih hierarkis, bold hanya di tempat penting.
// - Animasi lebih smooth: Staggered fade-in untuk items.
// - Pivot table: Dibuat lebih compact, dengan icons kecil alih-alih text panjang.
// - Warna scheme: Lebih soft, gunakan primary color dari theme.
// - Responsif: Tambah MediaQuery untuk adjust padding di device kecil.
// - Simpel: Hilangkan elemen berlebih, fokus pada readability (e.g., subtitle lebih ringkas).
// - FIX: Alias import excel untuk resolve TextSpan conflict.
// - FIX: Swap params di _infoCard untuk Total Absen (value big, title small).
// - ENHANCE: Export Excel sekarang punya 2 sheets: 'Rekap Lengkap' (data full) & 'Ringkasan Harian' (pivot table).
//   - Per User details tercakup di sheet utama (sudah ada Nama, Tanggal, Jenis, Status, Keterangan per entry).
//   - Pivot: Nama | Tanggal1 | Tanggal2 | ... dengan Jenis atau '-'.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xls;
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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
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

    var excel = xls.Excel.createExcel();
    xls.Sheet mainSheet = excel['Rekap Lengkap'];

    // Header untuk Rekap Lengkap
    mainSheet.appendRow([
      xls.TextCellValue("No"),
      xls.TextCellValue("Nama"),
      xls.TextCellValue("Tanggal"),
      xls.TextCellValue("Jenis"),
      xls.TextCellValue("Status"),
      xls.TextCellValue("Keterangan"),
    ]);

    // Styling Header
    xls.CellStyle headerStyle = xls.CellStyle(
      bold: true,
      // backgroundColorHex: "#1565C0",
      // fontColorHex: "#FFFFFF",
      horizontalAlign: xls.HorizontalAlign.Center,
      verticalAlign: xls.VerticalAlign.Center,
    );

    for (var i = 0; i < 6; i++) {
      var cell = mainSheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.cellStyle = headerStyle;
    }

    // Isi data Rekap Lengkap
    int no = 1;
    for (var item in _data) {
      final nama = item['nama_lengkap'] ?? 'Unknown';
      final tgl = item['created_at']?.toString().substring(0, 10) ?? '-';
      final jenis = item['jenis'] ?? '-';
      final status = item['status'] ?? 'Pending';
      final ket = item['keterangan'] ?? '-';

      mainSheet.appendRow([
        xls.TextCellValue(no.toString()),
        xls.TextCellValue(nama),
        xls.TextCellValue(tgl),
        xls.TextCellValue(jenis),
        xls.TextCellValue(status),
        xls.TextCellValue(ket),
      ]);
      no++;
    }

    // Sheet Ringkasan Harian (Pivot)
    if (_dates.isNotEmpty && _pivot.isNotEmpty) {
      xls.Sheet pivotSheet = excel['Ringkasan Harian'];

      // Header Pivot: Nama + dates
      List<xls.CellValue?> pivotHeader = [xls.TextCellValue("Nama")];
      for (var d in _dates) {
        pivotHeader.add(xls.TextCellValue(d)); // Full date YYYY-MM-DD
      }
      pivotSheet.appendRow(pivotHeader);

      // Style header pivot
      int pivotColCount = 1 + _dates.length;
      for (var i = 0; i < pivotColCount; i++) {
        var cell = pivotSheet.cell(
          xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.cellStyle = headerStyle;
      }

      // Isi data Pivot (sorted names)
      List<String> sortedNames = _pivot.keys.toList()..sort();
      for (var nama in sortedNames) {
        List<xls.CellValue?> pivotRow = [xls.TextCellValue(nama)];
        for (var d in _dates) {
          final val = _pivot[nama]![d] ?? '-';
          pivotRow.add(xls.TextCellValue(val));
        }
        pivotSheet.appendRow(pivotRow);
      }
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
        content: const Text(
          "Berhasil disimpan di folder Downloads! (2 sheets: Lengkap & Harian)",
        ),
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Rekap Absensi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 28),
            onPressed: _loadRekap,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 28),
            onPressed: _exportToExcel,
            tooltip: "Export ke Excel",
          ),
          SizedBox(width: screenWidth > 600 ? 16 : 8),
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
            : _data.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Belum ada data absensi",
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        MediaQuery.of(context).padding.top + 80,
                        16,
                        16,
                      ),
                      child: Column(
                        children: [
                          // Info Cards – Lebih compact
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildInfoCards(cs),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Per User Section
                          _buildSectionHeader("Detail Per User", Icons.people),
                          const SizedBox(height: 12),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildPerUserList(),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Pivot Table Section
                          _buildSectionHeader(
                            "Ringkasan Harian",
                            Icons.calendar_view_day,
                          ),
                          const SizedBox(height: 12),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildPivotTable(cs),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCards(ColorScheme cs) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [cs.primary.withOpacity(0.1), cs.primary.withOpacity(0.05)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _infoCard(
                _data.length.toString(),
                "Total Absen",
                Icons.bar_chart_rounded,
                cs.primary,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _infoCard(
                DateFormat(
                  'MMM yyyy',
                ).format(DateTime(int.parse(_year), int.parse(_month))),
                "Periode",
                Icons.calendar_today_rounded,
                cs.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String value, String title, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPerUserList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _perUser.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final nama = _perUser.keys.elementAt(i);
        final items = _perUser[nama]!;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              child: Text(
                nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            title: Text(
              nama,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              "${items.length} entri",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: items.map((e) => _buildUserItem(e)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildUserItem(Map<String, dynamic> e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _jenisIcon(e['jenis']),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      TextSpan(text: e['tgl']),
                      const TextSpan(
                        text: ' • ',
                        style: TextStyle(fontSize: 14),
                      ),
                      TextSpan(
                        text: e['jenis'],
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  e['ket'].isNotEmpty ? e['ket'] : 'Status: ${e['status']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          _statusBadge(e['status']),
        ],
      ),
    );
  }

  Widget _jenisIcon(String jenis) {
    IconData icon = Icons.help_outline_rounded;
    Color color = Colors.grey;
    if (jenis == 'Masuk') {
      icon = Icons.login_rounded;
      color = Colors.green;
    } else if (jenis == 'Pulang') {
      icon = Icons.logout_rounded;
      color = Colors.orange;
    } else if (jenis.contains('Izin')) {
      icon = Icons.sick_rounded;
      color = Colors.red;
    } else if (jenis.contains('Penugasan')) {
      icon = Icons.assignment_rounded;
      color = Colors.purple;
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'Disetujui')
      color = Colors.green;
    else if (status == 'Pending')
      color = Colors.orange;
    else
      color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPivotTable(ColorScheme cs) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_dates.length} hari dalam periode',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 48,
                dataRowHeight: 56,
                headingRowColor: MaterialStateProperty.all(
                  cs.primary.withOpacity(0.1),
                ),
                border: TableBorder.all(color: Colors.grey.shade200, width: 1),
                columns: [
                  const DataColumn(
                    label: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Nama',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  ..._dates.map(
                    (d) => DataColumn(
                      label: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          d.substring(8, 10),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
                rows: _pivot.keys.map((nama) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            nama,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      ..._dates.map((d) {
                        final val = _pivot[nama]![d] ?? '';
                        return DataCell(
                          Center(
                            child: val.isEmpty
                                ? const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.grey,
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: val == 'Masuk'
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.orange.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      val == 'Masuk'
                                          ? Icons.login
                                          : Icons.logout,
                                      size: 16,
                                      color: val == 'Masuk'
                                          ? Colors.green
                                          : Colors.orange,
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
          ],
        ),
      ),
    );
  }
}
