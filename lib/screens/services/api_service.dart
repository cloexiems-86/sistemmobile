// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti IP ini dengan IP Laptop kamu (cek di CMD: ipconfig)
  static const String _baseUrl = "https://farel.dwirez.app/catin_api/api"; 

  static Future<List<dynamic>> fetchMateri() async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/materi/list-api"));
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
      final response = await http.get(Uri.parse("$_baseUrl/materi/soal/$materiId"));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}