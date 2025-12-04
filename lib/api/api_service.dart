// api/api_service.dart (UPDATED: Added 'informasi' and 'dokumenBase64' to submitPresensi; register now sends 'is_karyawan'; added getRekap with month/year)
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.0.101/backendapk/";
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

  // REGISTER (UPDATED: Add is_karyawan)
  static Future<Map<String, dynamic>> register({
    required String username,
    required String namaLengkap,
    required String nipNisn,
    required String password,
    required String role,
    required bool isKaryawan, // NEW
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register.php"),
      body: {
        "username": username,
        "nama_lengkap": namaLengkap,
        "nip_nisn": nipNisn,
        "password": password,
        "role": role,
        "is_karyawan": isKaryawan ? '1' : '0', // NEW
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

  // UPDATE USER (Tambah password optional)
  static Future<Map<String, dynamic>> updateUser({
    required String id,
    required String username,
    required String namaLengkap,
    String? password, // Optional
  }) async {
    final body = {"id": id, "username": username, "nama_lengkap": namaLengkap};
    if (password != null && password.isNotEmpty) {
      body["password"] = password;
    }
    final res = await http.post(
      Uri.parse("$baseUrl/update_user.php"),
      body: body,
    );
    return jsonDecode(res.body);
  }

  // PRESENSI SUBMIT (UPDATED: Added informasi and dokumenBase64)
  static Future<Map<String, dynamic>> submitPresensi({
    required String userId,
    required String jenis,
    required String keterangan,
    required String informasi, // NEW
    required String dokumenBase64, // NEW
    required String latitude,
    required String longitude,
    required String base64Image,
  }) async {
    final body = {
      "userId": userId,
      "jenis": jenis,
      "keterangan": keterangan,
      "informasi": informasi, // NEW
      "dokumenBase64": dokumenBase64, // NEW
      "latitude": latitude,
      "longitude": longitude,
      "base64Image": base64Image,
    };
    print('DEBUG API: Request body: ${jsonEncode(body)}');
    final res = await http.post(
      Uri.parse("$baseUrl/absen.php"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
    print('DEBUG API: Status code: ${res.statusCode}');
    print('DEBUG API: Response body: ${res.body}');
    return jsonDecode(res.body);
  }

  // GET USER HISTORY
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

  // GET ALL PRESENSI (ADMIN) - Ganti ke absen_admin_list.php untuk konsistensi
  static Future<List<dynamic>> getAllPresensi() async {
    final res = await http.get(Uri.parse("$baseUrl/absen_admin_list.php"));
    print('DEBUG API: Presensi response status: ${res.statusCode}');
    print(
      'DEBUG API: Presensi response body preview: ${res.body.substring(0, 200)}...',
    );
    try {
      final data = jsonDecode(res.body);
      if (data["status"] == true) {
        return data["data"] as List<dynamic>;
      } else if (data['error'] != null) {
        throw Exception('PHP Error: ${data['error']}');
      }
      return [];
    } catch (e) {
      print('DEBUG API: JSON Parse Error: $e');
      throw Exception('Response bukan JSON valid: $e. Cek server log.');
    }
  }

  // NEW: Get Rekap (with optional month/year)
  static Future<List<dynamic>> getRekap({String? month, String? year}) async {
    var url = "$baseUrl/presensi_rekap.php";
    if (month != null && year != null) {
      url += "?month=$month&year=$year";
    }
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);
    if (data["status"] == true) {
      return data["data"] as List<dynamic>;
    }
    return [];
  }

  // UPDATE PRESENSI STATUS (FIX: Debug detail untuk approve, handle 500)
  static Future<Map<String, dynamic>> updatePresensiStatus({
    required String id,
    required String status,
  }) async {
    final body = {"id": id, "status": status};
    print('DEBUG API UPDATE: Request body: ${jsonEncode(body)}');
    final res = await http.post(
      Uri.parse("$baseUrl/presensi_approve.php"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
    print('DEBUG API UPDATE: Status code: ${res.statusCode}');
    print(
      'DEBUG API UPDATE: Response body raw: "${res.body}"',
    ); // Raw body untuk debug
    if (res.statusCode != 200) {
      throw Exception(
        'HTTP Error ${res.statusCode}: ${res.body}',
      ); // Fix: Include body in exception
    }
    try {
      final data = jsonDecode(res.body);
      print('DEBUG API UPDATE: Parsed JSON: ${jsonEncode(data)}');
      return data;
    } catch (e) {
      print('DEBUG API UPDATE: JSON Parse Error: $e');
      throw Exception(
        'Response bukan JSON valid: ${res.body}. Cek PHP approve.',
      );
    }
  }
}
