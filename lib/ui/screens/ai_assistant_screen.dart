import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/utils/responsive.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'content': 'Γεια σας! Είμαι ο AI βοηθός της MTC. Πώς μπορώ να σας βοηθήσω σήμερα με τα έργα ή τα οικονομικά σας;'}
  ];
  bool _isTyping = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI ΒΟΗΘΟΣ MTC", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: Responsive.maxWidth(context)),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';
                    return Column(
                      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        _ChatBubble(message: msg['content']!, isUser: isUser),
                        if (_isTyping && index == _messages.length - 1)
                          const Padding(
                            padding: EdgeInsets.only(top: 8, bottom: 16),
                            child: Text("Ο βοηθός σκέφτεται...", style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                          ),
                      ],
                    );
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Πληκτρολογήστε μια ερώτηση (π.χ. Ποιο έργο έχει το μεγαλύτερο ROI;)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: _sendMessage,
            mini: true,
            elevation: 0,
            child: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    // Καθαρισμός του κλειδιού από κενά ή αλλαγές γραμμής
    final apiKey = provider.settings.aiApiUrl.trim().replaceAll('\n', '').replaceAll('\r', '');

    if (apiKey.isEmpty) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': "⚠️ Δεν έχει οριστεί AI API Key. Παρακαλώ πηγαίνετε στις Ρυθμίσεις και προσθέστε το κλειδί σας."});
      });
      return;
    }

    final userMsg = _messageController.text;
    setState(() {
      _messages.add({'role': 'user', 'content': userMsg});
      _isTyping = true;
    });

    _messageController.clear();

    try {
      final stats = provider.dashboardStats;
      final analytical = await provider.getCompanyAnalyticalFinancials();
      final projectCount = provider.projects.length;
      final activeProjects = provider.projects.where((p) => !p.isCompleted).map((p) => p.name).take(10).join(", ");
      final pendingTasks = provider.tasks.where((t) => !t.isCompleted).length;
      final alertCount = provider.alerts.length;
      final clientCount = provider.clients.length;
      final partnerCount = provider.partners.length;
      
      final systemPrompt = """
Είσαι ο βοηθός διαχείρισης της τεχνικής εταιρείας MTC (Μόσχος Βασίλειος). 
Δεδομένα εφαρμογής:
- Έργα: $projectCount συνολικά, Ενεργά: $activeProjects
- Οικονομικά (Προσφορές): ${analytical['totalQuotes']?.toStringAsFixed(2)}€
- Οικονομικά (Εισπράξεις): ${analytical['actualIncome']?.toStringAsFixed(2)}€
- Έξοδα: Εργατικά ${analytical['labor']?.toStringAsFixed(2)}€, Υλικά ${analytical['materials']?.toStringAsFixed(2)}€, Πάγια ${analytical['fixed']?.toStringAsFixed(2)}€
- ΦΠΑ: Εισπραχθέν ${analytical['vatCollected']?.toStringAsFixed(2)}€, Πληρωθέν ${analytical['vatPaid']?.toStringAsFixed(2)}€
- Υπόλοιπο (Ταμείο): ${(stats['income']! - stats['expense']!).toStringAsFixed(2)}€
- Επιχειρησιακά: $pendingTasks εκκρεμείς εργασίες, $alertCount ειδοποιήσεις συστήματος
- Σχέσεις: $clientCount πελάτες, $partnerCount συνεργάτες

Απάντησε σύντομα στα ελληνικά.
""";

      if (apiKey.startsWith("sk-ant-")) {
        // --- CLAUDE 3.5 SONNET (Anthropic) ---
        final url = "https://api.anthropic.com/v1/messages";
        final response = await http.post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01"
          },
          body: jsonEncode({
            "model": "claude-3-5-sonnet-20240620",
            "system": systemPrompt,
            "messages": _messages.where((m) => !m['content']!.startsWith('❌')).map((m) => {
              "role": m['role'] == 'assistant' ? 'assistant' : 'user',
              "content": m['content']
            }).toList(),
            "max_tokens": 1024,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final aiContent = data['content'][0]['text'];
          setState(() {
            _messages.add({'role': 'assistant', 'content': aiContent});
            _isTyping = false;
          });
        } else {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          setState(() {
            _messages.add({'role': 'assistant', 'content': "❌ Claude Error: ${errorData['error']?['message'] ?? 'Unknown'}"});
            _isTyping = false;
          });
        }
      } else if (apiKey.startsWith("sk-")) {
        // --- CHATGPT (OpenAI) ---
        final url = "https://api.openai.com/v1/chat/completions";
        final response = await http.post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer $apiKey",
          },
          body: jsonEncode({
            "model": "gpt-4o-mini",
            "messages": [
              {"role": "system", "content": systemPrompt},
              ..._messages.where((m) => !m['content']!.startsWith('❌')).map((m) => {
                "role": m['role'] == 'assistant' ? 'assistant' : 'user',
                "content": m['content']
              }).toList(),
            ],
            "temperature": 0.7,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final aiContent = data['choices'][0]['message']['content'];
          setState(() {
            _messages.add({'role': 'assistant', 'content': aiContent});
            _isTyping = false;
          });
        } else {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          setState(() {
            _messages.add({'role': 'assistant', 'content': "❌ OpenAI Error: ${errorData['error']?['message'] ?? 'Unknown'}"});
            _isTyping = false;
          });
        }
      } else {
        // --- GEMINI (Google) - Primary: Gemini 3 Flash / Fallback: Gemini 3.1 Pro ---
        final url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey";
        final fallbackUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-pro-preview:generateContent?key=$apiKey";
        
        List<Map<String, dynamic>> contents = [];
        for (var m in _messages) {
          if (m['content']!.startsWith('❌')) continue;
          contents.add({
            "role": m['role'] == 'assistant' ? 'model' : 'user',
            "parts": [{"text": m['content']}]
          });
        }

        final payload = jsonEncode({
          "system_instruction": {
            "parts": [{"text": systemPrompt}]
          },
          "contents": contents,
          "generationConfig": {"temperature": 0.7, "maxOutputTokens": 2048}
        });

        http.Response response;
        try {
          response = await http.post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: payload,
          ).timeout(const Duration(seconds: 20));
          
          if (response.statusCode != 200) {
            // Δοκιμή Fallback (3.0 Pro)
            response = await http.post(
              Uri.parse(fallbackUrl),
              headers: {"Content-Type": "application/json"},
              body: payload,
            ).timeout(const Duration(seconds: 20));
          }
        } catch (e) {
          // Αν αποτύχει το πρώτο με timeout/network, δοκιμή Fallback
          response = await http.post(
            Uri.parse(fallbackUrl),
            headers: {"Content-Type": "application/json"},
            body: payload,
          ).timeout(const Duration(seconds: 20));
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data['candidates'] != null && data['candidates'].isNotEmpty) {
            final aiContent = data['candidates'][0]['content']['parts'][0]['text'];
            setState(() {
              _messages.add({'role': 'assistant', 'content': aiContent});
              _isTyping = false;
            });
          } else {
            setState(() {
              _messages.add({'role': 'assistant', 'content': "❌ Gemini Error: Empty response (blocked or safety filter)"});
              _isTyping = false;
            });
          }
        } else {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          final errorMsg = errorData['error']?['message'] ?? 'Unknown error';
          setState(() {
            _messages.add({'role': 'assistant', 'content': "❌ Gemini Error (${response.statusCode}): $errorMsg"});
            _isTyping = false;
          });
        }
      }
    } catch (e) {
      debugPrint("AI Exception: $e");
      setState(() {
        _messages.add({'role': 'assistant', 'content': "🔌 Σφάλμα σύνδεσης: $e"});
        _isTyping = false;
      });
    }
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  const _ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.blueGrey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 13, fontWeight: isUser ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}
