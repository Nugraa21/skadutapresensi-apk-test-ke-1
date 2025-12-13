// lib/api/api_service.dart — VERSI FINAL & TIDAK ADA ERROR!
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/encryption.dart';

class ApiService {
  static const String baseUrl =
      "https://nonlitigious-alene-uninfinitely.ngrok-free.dev/backendapk/";

  // === DEKRIPSI AMAN & RETURN MAP (TIDAK ERROR LAGI!) ===
  static Map<String, dynamic> _safeDecrypt(http.Response response) {
    try {
      print("RAW RESPONSE: ${response.body}");

      final body = jsonDecode(response.body);

      if (body['encrypted_data'] != null) {
        final decryptedJson = ApiEncryption.decrypt(body['encrypted_data']);
        return jsonDecode(decryptedJson); // String → Map
      }

      // Kalau bukan encrypted (login, submit, dll)
      return body as Map<String, dynamic>;
    } catch (e) {
      print("GAGAL DEKRIPSI: $e");
      return {
        "status": false,
        "message": "Gagal membaca data dari server",
        "data": [],
      };
    }
  }

  // ================== API YANG PAKAI ENKRIPSI ==================
  static Future<List<dynamic>> getUsers() async {
    final res = await http.get(Uri.parse("$baseUrl/get_users.php"));
    final data = _safeDecrypt(res);
    return List<dynamic>.from(data['data'] ?? []);
  }

  static Future<List<dynamic>> getUserHistory(String userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/absen_history.php?user_id=$userId"),
    );
    final data = _safeDecrypt(res);
    return List<dynamic>.from(data['data'] ?? []);
  }

  static Future<List<dynamic>> getAllPresensi() async {
    final res = await http.get(Uri.parse("$baseUrl/absen_admin_list.php"));
    final data = _safeDecrypt(res);
    return List<dynamic>.from(data['data'] ?? []);
  }

  static Future<List<dynamic>> getRekap({String? month, String? year}) async {
    var url = "$baseUrl/presensi_rekap.php";
    if (month != null && year != null) url += "?month=$month&year=$year";
    final res = await http.get(Uri.parse(url));
    final data = _safeDecrypt(res);
    return List<dynamic>.from(data['data'] ?? []);
  }

  // ================== LOGIN & REGISTER ==================
  static Future<Map<String, dynamic>> login({
    required String input,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login.php"),
      body: {"input": input, "password": password},
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String namaLengkap,
    required String nipNisn,
    required String password,
    required String role,
    required bool isKaryawan,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register.php"),
      body: {
        "username": username,
        "nama_lengkap": namaLengkap,
        "nip_nisn": nipNisn,
        "password": password,
        "role": role,
        "is_karyawan": isKaryawan ? '1' : '0',
      },
    );
    return jsonDecode(res.body);
  }

  // ================== SUBMIT PRESENSI ==================
  static Future<Map<String, dynamic>> submitPresensi({
    required String userId,
    required String jenis,
    required String keterangan,
    required String informasi,
    required String dokumenBase64,
    required String latitude,
    required String longitude,
    required String base64Image,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/absen.php"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        "userId": userId,
        "jenis": jenis,
        "keterangan": keterangan,
        "informasi": informasi,
        "dokumenBase64": dokumenBase64,
        "latitude": latitude,
        "longitude": longitude,
        "base64Image": base64Image,
      },
    );
    return jsonDecode(res.body);
  }

  // ================== LAINNYA ==================
  static Future<Map<String, dynamic>> updatePresensiStatus({
    required String id,
    required String status,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/presensi_approve.php"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {"id": id, "status": status},
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteUser(String id) async {
    final res = await http.post(
      Uri.parse("$baseUrl/delete_user.php"),
      body: {"id": id},
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateUser({
    required String id,
    required String username,
    required String namaLengkap,
    String? password,
  }) async {
    final body = {"id": id, "username": username, "nama_lengkap": namaLengkap};
    if (password != null && password.isNotEmpty) body["password"] = password;
    final res = await http.post(
      Uri.parse("$baseUrl/update_user.php"),
      body: body,
    );
    return jsonDecode(res.body);
  }
}
