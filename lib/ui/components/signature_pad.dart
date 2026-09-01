import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SignaturePad extends StatefulWidget {
  final String title;
  final Function(Uint8List) onSignatureCaptured;
  final VoidCallback onDismiss;

  const SignaturePad({super.key, this.title = "ΥΠΟΓΡΑΦΗ", required this.onSignatureCaptured, required this.onDismiss});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.maxFinite,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Colors.white,
            ),
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  RenderBox renderBox = context.findRenderObject() as RenderBox;
                  _points.add(renderBox.globalToLocal(details.localPosition));
                });
              },
              onPanEnd: (details) => _points.add(null),
              child: CustomPaint(
                painter: _SignaturePainter(points: _points),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text("Υπογράψτε μέσα στο πλαίσιο", style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => setState(() => _points.clear()), child: const Text("ΚΑΘΑΡΙΣΜΟΣ")),
        TextButton(onPressed: widget.onDismiss, child: const Text("ΑΚΥΡΟ")),
        ElevatedButton(
          onPressed: () async {
            if (_points.isNotEmpty) {
              final signature = await _captureSignature();
              widget.onSignatureCaptured(signature);
            }
          },
          child: const Text("ΕΠΙΒΕΒΑΙΩΣΗ"),
        ),
      ],
    );
  }

  Future<Uint8List> _captureSignature() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTRB(0, 0, 300, 200));
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    canvas.drawColor(Colors.white, BlendMode.src);
    for (int i = 0; i < _points.length - 1; i++) {
      if (_points[i] != null && _points[i + 1] != null) {
        canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
      }
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(300, 200);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
