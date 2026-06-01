// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = "https://farel.dwirez.app/catin_api/api";

  static Future<List<dynamic>> fetchMateri() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/materi/list-api"),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['data'];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> fetchSoal(int materiId) async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/materi/soal/$materiId"),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['data'];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitAbsensi(
    String userId,
    String jadwalId,
    String peserta,
  ) async {
    try {
      const String targetUrl =
          "https://farel.dwirez.app/api/absensi/hadir";

      final response = await http
          .post(
            Uri.parse(targetUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'user_id': userId,
              'jadwal_id': jadwalId,
              'peserta': peserta,
            }),
          )
          .timeout(const Duration(seconds: 15));

      var responseData = json.decode(response.body);

      if (responseData['status'] == 'success') {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Berhasil absen!',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Gagal melakukan absensi.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Sistem Error: $e',
      };
    }
  }
}
