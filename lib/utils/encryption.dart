// lib/utils/encryption.dart — VERSI FINAL YANG 100% JALAN!
import 'dart:convert';
import 'package:encrypt/encrypt.dart';

class ApiEncryption {
  // KUNCI HARUS SAMA DENGAN PHP!
  static const String _key = "SkadutaPresensi2025SecureKey1234";

  static String decrypt(String encryptedBase64) {
    try {
      final key = Key.fromUtf8(_key); // 32 karakter = 256 bit
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      final data = base64Decode(encryptedBase64);
      final iv = IV(data.sublist(0, 16));
      final encryptedData = data.sublist(16);

      // Ini yang bener-bener decrypt AES-256-CBC
      final decrypted = encrypter.decrypt(Encrypted(encryptedData), iv: iv);

      print("DECRYPT BERHASIL!");
      return decrypted; // return String (JSON)
    } catch (e) {
      print("GAGAL DEKRIPSI: $e");
      rethrow;
    }
  }
}
