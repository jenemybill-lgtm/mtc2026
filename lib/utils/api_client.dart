import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtc2026/database/database_helper.dart';

class ApiClient {
  static const String _defaultBaseUrl = "https://mtc-m9in.onrender.com";
  
  Future<String> get baseUrl async {
    try {
      final settings = await DatabaseHelper().getGlobalSettings();
      if (settings != null && settings['dbApiUrl'] != null) {
        final url = settings['dbApiUrl'] as String;
        if (url.isNotEmpty) return url;
      }
    } catch (_) {}
    return _defaultBaseUrl;
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = await baseUrl;
    return await http.post(
      Uri.parse("$url$endpoint"),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 120)); // Long timeout for wake up
  }

  Future<http.Response> get(String endpoint) async {
    final url = await baseUrl;
    return await http.get(
      Uri.parse("$url$endpoint"),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 120)); // Long timeout for wake up
  }
}
