import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class WatermarkService {
  static Future<String> addWatermark({
    required String imagePath,
    required String watermarkText,
    String companyName = "MTC 2026",
  }) async {
    if (kIsWeb) return imagePath;

    try {
      final file = File(imagePath);
      if (!await file.exists()) return imagePath;

      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return imagePath;

      final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
      final fullText = " $companyName • ${watermarkText.toUpperCase()} • $dateStr ";

      // Choose font size based on image width
      final font = decodedImage.width > 1200 ? img.arial48 : img.arial24;

      // Draw background bar at bottom
      final barHeight = decodedImage.width > 1200 ? 70 : 40;
      img.fillRect(
        decodedImage,
        x1: 0,
        y1: decodedImage.height - barHeight,
        x2: decodedImage.width,
        y2: decodedImage.height,
        color: img.ColorRgba8(15, 23, 42, 200), // Dark Navy
      );

      // Draw Watermark text
      img.drawString(
        decodedImage,
        fullText,
        font: font,
        x: 16,
        y: decodedImage.height - barHeight + (barHeight ~/ 4),
        color: img.ColorRgb8(255, 255, 255),
      );

      final newBytes = img.encodeJpg(decodedImage, quality: 88);
      final newPath = "${file.parent.path}/wm_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final newFile = File(newPath);
      await newFile.writeAsBytes(newBytes);
      return newFile.path;
    } catch (e) {
      debugPrint("Watermark Error: $e");
      return imagePath;
    }
  }
}
