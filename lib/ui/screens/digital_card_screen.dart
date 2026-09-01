import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class DigitalCardScreen extends StatelessWidget {
  final Settings settings;
  const DigitalCardScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final nameParts = settings.ownerName.trim().split(" ");
    final lastName = nameParts.last;
    final firstName = nameParts.length > 1 ? nameParts.sublist(0, nameParts.length - 1).join(" ") : "";

    final vCard = "BEGIN:VCARD\r\n"
        "VERSION:3.0\r\n"
        "N;CHARSET=UTF-8:$lastName;$firstName;;;\r\n"
        "FN;CHARSET=UTF-8:${settings.ownerName}\r\n"
        "ORG;CHARSET=UTF-8:${settings.companyName}\r\n"
        "TEL;TYPE=CELL,VOICE:${settings.phone}\r\n"
        "EMAIL;TYPE=PREF,INTERNET:${settings.email}\r\n"
        "REV:${DateTime.now().millisecondsSinceEpoch}\r\n"
        "END:VCARD";

    final GlobalKey globalKey = GlobalKey();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΨΗΦΙΑΚΗ ΚΑΡΤΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  RepaintBoundary(
                    key: globalKey,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 15)),
                        ],
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.1), width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (settings.logoUri != null && settings.logoUri!.isNotEmpty)
                             Padding(
                               padding: const EdgeInsets.only(bottom: 24.0),
                               child: Image.file(File(settings.logoUri!), height: 60, fit: BoxFit.contain),
                             ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                            ),
                            child: QrImageView(
                              data: vCard,
                              version: QrVersions.auto,
                              size: 220.0,
                              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1E293B)),
                              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1E293B)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(settings.ownerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E293B), letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(settings.companyName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15)),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          _infoLine(Icons.phone_rounded, settings.phone),
                          const SizedBox(height: 8),
                          _infoLine(Icons.email_rounded, settings.email),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Σκανάρετε το QR code για να αποθηκεύσετε τις επαφές μου απευθείας στο κινητό σας.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton.icon(
              onPressed: () => _shareQr(globalKey),
              icon: const Icon(Icons.share_rounded, size: 20),
              label: const Text("ΚΟΙΝΟΠΟΙΗΣΗ ΚΑΡΤΑΣ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4361EE),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 8,
                shadowColor: const Color(0xFF4361EE).withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ],
    );
  }

  Future<void> _shareQr(GlobalKey key) async {
    try {
      RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/mtc_qr.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'MTC Ψηφιακή Κάρτα');
    } catch (e) {
      debugPrint("Error sharing QR: $e");
    }
  }
}
