import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  test('Test Cloud', () async {
    final url = "https://mtc-m9in.onrender.com";
    
    final res = await http.post(Uri.parse("$url/api/auth/login"), body: jsonEncode({
      "companyName": "test",
      "password": "test"
    }), headers: {"Content-Type": "application/json"});
    
    print("Login: ${res.statusCode}");
    if (res.statusCode != 200) return;
    
    final token = jsonDecode(res.body)['token'];
    
    final dl = await http.get(Uri.parse("$url/api/sync/download"), headers: {
      "Authorization": "Bearer $token"
    });
    print("Download: ${dl.statusCode}");
    print("Data keys: ${jsonDecode(dl.body).keys}");
  });
}
