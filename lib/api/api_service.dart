import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
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

  // UPDATE PASSWORD TERPISAH (Untuk ganti password saja)
  static Future<Map<String, dynamic>> updateUserPassword({
    required String id,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/update_password.php"),
      body: {"id": id, "password": newPassword},
    );
    return jsonDecode(res.body);
  }

  // PRESENSI SUBMIT
  static Future<Map<String, dynamic>> submitPresensi({
    required String userId,
    required String jenis,
    required String keterangan,
    required String latitude,
    required String longitude,
    required String base64Image,
  }) async {
    final body = {
      "userId": userId,
      "jenis": jenis,
      "keterangan": keterangan,
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

  // GET ALL PRESENSI (ADMIN)
  static Future<List<dynamic>> getAllPresensi() async {
    final res = await http.get(Uri.parse("$baseUrl/presensi_rekap.php"));
    return jsonDecode(res.body); // Return array langsung
  }

  // UPDATE PRESENSI STATUS
  static Future<Map<String, dynamic>> updatePresensiStatus({
    required String id,
    required String status,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/presensi_approve.php"),
      body: {"id": id, "status": status},
    );
    return jsonDecode(res.body);
  }
}
