import 'dart:convert';
// Digunakan untuk encoding dan decoding Base64 (base64Encode / base64Decode)

import 'package:encrypt/encrypt.dart';
// Library encrypt untuk enkripsi dan dekripsi AES di Dart

class ApiEncryption {
  // Class ApiEncryption berfungsi sebagai helper untuk proses dekripsi data API

  static const String _key = "SkadutaPresensi2025SecureKey1234";
  // Key rahasia untuk AES (32 karakter = AES-256)

  static String decrypt(String encryptedBase64) {
    // Method static untuk mendekripsi data terenkripsi dalam bentuk Base64

    try {
      // Blok try untuk menangkap error jika proses dekripsi gagal

      final key = Key.fromUtf8(_key);
      // Mengubah string key menjadi objek Key yang dibutuhkan AES

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      // Membuat objek encrypter menggunakan algoritma AES
      // Mode CBC (Cipher Block Chaining)

      final data = base64Decode(encryptedBase64);
      // Decode string Base64 menjadi byte array (List<int>)

      final iv = IV(data.sublist(0, 16));
      // Mengambil 16 byte pertama sebagai IV (Initialization Vector)

      final encryptedData = data.sublist(16);
      // Mengambil sisa data setelah IV sebagai data terenkripsi

      final decrypted = encrypter.decrypt(Encrypted(encryptedData), iv: iv);
      // Melakukan proses dekripsi menggunakan AES + IV

      print("DECRYPT BERHASIL!");
      // Log ke console jika proses dekripsi berhasil

      return decrypted;
      // Mengembalikan hasil dekripsi dalam bentuk String
    } catch (e) {
      // Menangkap error jika terjadi kesalahan saat dekripsi

      print("GAGAL DEKRIPSI: $e");
      // Menampilkan pesan error ke console

      rethrow;
      // Melempar ulang error agar bisa ditangani di level atas
    }
  }
}
