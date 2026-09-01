import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _defaultBaseUrl = "https://mtc-erp-backend.onrender.com"; // User will update this
  
  Future<String> get baseUrl async {
    return "https://mtc-m9in.onrender.com";
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
    ).timeout(const Duration(seconds: 60)); // Long timeout for photo uploads
  }

  Future<http.Response> get(String endpoint) async {
    final url = await baseUrl;
    return await http.get(
      Uri.parse("$url$endpoint"),
      headers: await _headers(),
    );
  }
}
