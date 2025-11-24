import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // GANTI IP INI DENGAN IP LAPTOP KAMU
  static const String baseUrl = "http://192.168.0.105/backendapk/";

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

  static Future<List<dynamic>> getUsers() async {
    final res = await http.get(Uri.parse("$baseUrl/get_users.php"));
    final data = jsonDecode(res.body);
    if (data["status"] == "success") {
      return data["data"] as List<dynamic>;
    }
    return [];
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
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/update_user.php"),
      body: {"id": id, "username": username, "nama_lengkap": namaLengkap},
    );
    return jsonDecode(res.body);
  }
}
