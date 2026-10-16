import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ScannedInvoiceData {
  final String merchant;
  final double totalAmount;
  final double vatAmount;
  final String description;
  final DateTime date;

  ScannedInvoiceData({
    required this.merchant,
    required this.totalAmount,
    required this.vatAmount,
    required this.description,
    required this.date,
  });
}

class AiInvoiceScannerService {
  static Future<ScannedInvoiceData?> scanInvoiceImage({
    required String imagePath,
    required String apiKey,
  }) async {
    final cleanKey = apiKey.trim().replaceAll('\n', '').replaceAll('\r', '');
    if (cleanKey.isEmpty) return null;

    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    const promptText = """
Είσαι ένας εξειδικευμένος αναγνώστης τιμολογίων και αποδείξεων.
Ανάλυσε την εικόνα του τιμολογίου/απόδειξης και επίστρεψε ΑΠΟΚΛΕΙΣΤΙΚΑ ΚΑΙ ΜΟΝΟ ένα έγκυρο JSON αντικείμενο στη μορφή:
{
  "merchant": "Όνομα Καταστήματος/Προμηθευτή",
  "totalAmount": 0.00,
  "vatAmount": 0.00,
  "description": "Σύντομη περιγραφή των υλικών/αγορών",
  "date": "YYYY-MM-DD"
}
Μην προσθέσεις κανένα άλλο κείμενο εκτός από το JSON.
""";

    try {
      if (cleanKey.startsWith("sk-ant-")) {
        // Claude 3.5 Sonnet Vision
        final url = "https://api.anthropic.com/v1/messages";
        final response = await http.post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
            "x-api-key": cleanKey,
            "anthropic-version": "2023-06-01"
          },
          body: jsonEncode({
            "model": "claude-3-5-sonnet-20240620",
            "max_tokens": 512,
            "messages": [
              {
                "role": "user",
                "content": [
                  {
                    "type": "image",
                    "source": {
                      "type": "base64",
                      "media_type": "image/jpeg",
                      "data": base64Image
                    }
                  },
                  {"type": "text", "text": promptText}
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final text = data['content'][0]['text'];
          return _parseJsonText(text);
        }
      } else if (cleanKey.startsWith("sk-")) {
        // OpenAI GPT-4o
        final url = "https://api.openai.com/v1/chat/completions";
        final response = await http.post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer $cleanKey",
          },
          body: jsonEncode({
            "model": "gpt-4o-mini",
            "messages": [
              {
                "role": "user",
                "content": [
                  {"type": "text", "text": promptText},
                  {
                    "type": "image_url",
                    "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
                  }
                ]
              }
            ],
            "max_tokens": 512,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final text = data['choices'][0]['message']['content'];
          return _parseJsonText(text);
        }
      } else {
        // Gemini 1.5 Flash Vision
        final url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$cleanKey";
        final payload = jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": promptText},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        });

        final response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: payload,
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data['candidates'] != null && data['candidates'].isNotEmpty) {
            final text = data['candidates'][0]['content']['parts'][0]['text'];
            return _parseJsonText(text);
          }
        } else {
           debugPrint("Gemini Error: ${response.statusCode} - ${response.body}");
        }
      }
    } catch (e) {
      debugPrint("AI Vision Scan Exception: $e");
    }
    return null;
  }

  static ScannedInvoiceData? _parseJsonText(String rawText) {
    try {
      // Find JSON block if wrapped in markdown ```json ... ```
      String cleanText = rawText.replaceAll("```json", "").replaceAll("```", "").trim();
      final startIndex = cleanText.indexOf('{');
      final endIndex = cleanText.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1) {
        cleanText = cleanText.substring(startIndex, endIndex + 1);
      }

      final map = jsonDecode(cleanText);
      final merchant = map['merchant']?.toString() ?? "Άγνωστος Προμηθευτής";
      final totalAmount = (map['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final vatAmount = (map['vatAmount'] as num?)?.toDouble() ?? 0.0;
      final description = map['description']?.toString() ?? "Αγορά Υλικών";
      
      DateTime parsedDate = DateTime.now();
      if (map['date'] != null) {
        try {
          parsedDate = DateTime.parse(map['date'].toString());
        } catch (_) {}
      }

      return ScannedInvoiceData(
        merchant: merchant,
        totalAmount: totalAmount,
        vatAmount: vatAmount,
        description: description,
        date: parsedDate,
      );
    } catch (e) {
      debugPrint("JSON Parse Error on scanned invoice: $e");
      return null;
    }
  }
}
