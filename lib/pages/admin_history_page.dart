// ==========================
// admin_history_page.dart
// ==========================
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminHistoryPage extends StatefulWidget {
  @override
  _AdminHistoryPageState createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  List history = [];
  final baseUrl = "http://192.168.0.105/skaduta_api";

  Future<void> loadAllHistory() async {
    var url = Uri.parse("$baseUrl/get_all_history.php");
    var res = await http.get(url);
    setState(() {
      history = jsonDecode(res.body);
    });
  }

  @override
  void initState() {
    super.initState();
    loadAllHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rekap Presensi Semua User")),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          var h = history[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text(h['nama']),
              subtitle: Text(
                "Jenis: ${h['jenis']} Tanggal: ${h['tanggal']} Ket: ${h['keterangan']}",
              ),
            ),
          );
        },
      ),
    );
  }
}
