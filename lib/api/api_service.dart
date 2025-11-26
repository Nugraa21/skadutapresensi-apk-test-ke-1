import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // GANTI IP SESUAI LAPTOPMU (pastikan PHP jalan di port 80)
  static const String baseUrl = "http://192.168.0.102/backendapk";

  // LOGIN
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

  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String username,
    required String namaLengkap,
    required String nipNisn,
    required String password,
    required String role,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register.php"),
      body: {
        "username": username,
        "nama_lengkap": namaLengkap,
        "nip_nisn": nipNisn,
        "password": password,
        "role": role,
      },
    );

    return jsonDecode(res.body);
  }

  // GET ALL USERS (SUPERADMIN)
  static Future<List<dynamic>> getUsers() async {
    final res = await http.get(Uri.parse("$baseUrl/get_users.php"));
    final data = jsonDecode(res.body);
    if (data["status"] == "success") {
      return data["data"] as List<dynamic>;
    }
    return [];
  }

  // DELETE USER
  static Future<Map<String, dynamic>> deleteUser(String id) async {
    final res = await http.post(
      Uri.parse("$baseUrl/delete_user.php"),
      body: {"id": id},
    );
    return jsonDecode(res.body);
  }

  // UPDATE USER
  static Future<Map<String, dynamic>> updateUser({
    required String id,
    required String username,
    required String namaLengkap,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/update_user.php"),
      body: {"id": id, "username": username, "nama_lengkap": namaLengkap},
    );
    return jsonDecode(res.body);
  }

  // ==========================
  // PRESENSI (USER)
  // ==========================

  // Kirim presensi (FIX: Key samain sama PHP, tambah debug)
  static Future<Map<String, dynamic>> submitPresensi({
    required String userId,
    required String jenis, // Masuk / Pulang / Izin / Pulang Cepat
    required String keterangan,
    required String latitude,
    required String longitude,
    required String base64Image,
  }) async {
    // DEBUG: Print body sebelum kirim
    final body = {
      "userId": userId,
      "jenis": jenis,
      "keterangan": keterangan,
      "latitude": latitude,
      "longitude": longitude,
      "base64Image": base64Image,
    };
    print('DEBUG API: Request body: ${jsonEncode(body)}'); // Preview body

    final res = await http.post(
      Uri.parse("$baseUrl/absen.php"),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      }, // Form body
      body: body, // Key samain PHP
    );

    print('DEBUG API: Status code: ${res.statusCode}'); // 200 OK?
    print('DEBUG API: Response body: ${res.body}'); // Error message?

    return jsonDecode(res.body);
  }

  // Riwayat presensi user
  static Future<List<dynamic>> getUserHistory(String userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/absen_history.php?user_id=$userId"),
    );

    final data = jsonDecode(res.body);
    if (data["status"] == true) {
      return data["data"] as List<dynamic>;
    }
    return [];
  }

  // ==========================
  // PRESENSI (ADMIN)
  // ==========================

  // Semua presensi (untuk admin)
  static Future<List<dynamic>> getAllPresensi() async {
    final res = await http.get(Uri.parse("$baseUrl/absen_admin_list.php"));
    final data = jsonDecode(res.body);
    if (data["status"] == true) {
      return data["data"] as List<dynamic>;
    }
    return [];
  }

  // Approve / Reject presensi
  static Future<Map<String, dynamic>> updatePresensiStatus({
    required String id,
    required String status, // Disetujui / Ditolak
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/absen_approve.php"),
      body: {"id": id, "status": status},
    );
    return jsonDecode(res.body);
  }
}
