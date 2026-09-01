import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:mtc2026/models/sketch_models.dart';

class ElevationDrawingScreen extends StatefulWidget {
  final int projectId;
  const ElevationDrawingScreen({super.key, required this.projectId});

  @override
  State<ElevationDrawingScreen> createState() => _ElevationDrawingScreenState();
}

class _ElevationDrawingScreenState extends State<ElevationDrawingScreen> {
  final List<SketchShape> _shapes = [];
  final List<SketchLayer> _layers = [
    SketchLayer(id: "0", name: "Τοίχοι / Γραμμές", color: Colors.white, thickness: 3.0),
    SketchLayer(id: "1", name: "Αντικείμενα", color: Colors.blue, thickness: 2.0),
    SketchLayer(id: "2", name: "Κείμενο / Σημειώσεις", color: Colors.yellow, thickness: 1.0),
  ];
  String _activeLayerId = "0";
  
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  SketchShape? _selectedShape;
  SketchShape? _previewShape;
  Offset? _startPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("ΟΨΗ ΕΡΓΟΥ (ELEVATION)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        actions: [
          IconButton(icon: const Icon(Icons.layers_rounded), onPressed: _showLayersSheet),
          IconButton(icon: const Icon(Icons.undo), onPressed: _shapes.isEmpty ? null : () => setState(() => _shapes.removeLast())),
        ],
      ),
      body: Column(
        children: [
          _buildToolBar(),
          Expanded(
            child: ClipRect(
              child: GestureDetector(
                onScaleUpdate: _handleScaleUpdate,
                onTapDown: _handleTapDown,
                child: CustomPaint(
                  painter: ElevationPainter(
                    shapes: _shapes,
                    layers: _layers,
                    selectedShape: _selectedShape,
                    previewShape: _previewShape,
                    offset: _offset,
                    scale: _scale,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBar() {
    return Container(
      color: Colors.black,
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolBtn(Icons.edit_road_rounded, "Γραμμή", "0"),
          _toolBtn(Icons.door_front_door_rounded, "Πόρτα", "1"),
          _toolBtn(Icons.window_rounded, "Παράθυρο", "1"),
          _toolBtn(Icons.bolt_rounded, "Πρίζα", "1"),
          _toolBtn(Icons.text_fields_rounded, "Κείμενο", "2"),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, String layerId) {
    final isSel = _activeLayerId == layerId;
    return InkWell(
      onTap: () => setState(() => _activeLayerId = layerId),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSel ? Colors.blue : Colors.white60, size: 20),
          Text(label, style: TextStyle(color: isSel ? Colors.blue : Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount == 2) {
        _scale *= details.scale;
        _offset += details.focalPointDelta;
      } else if (details.pointerCount == 1 && _startPoint != null) {
        final end = _screenToWorld(details.localFocalPoint);
        _previewShape = SketchLine(id: 'prev', layerId: _activeLayerId, start: _startPoint!, end: end);
      }
    });
  }

  void _handleTapDown(TapDownDetails details) {
    final worldPos = _screenToWorld(details.localPosition);
    setState(() {
      if (_activeLayerId == "0") {
        if (_startPoint == null) {
          _startPoint = worldPos;
        } else {
          _shapes.add(SketchLine(id: DateTime.now().toString(), layerId: "0", start: _startPoint!, end: worldPos));
          _startPoint = null;
          _previewShape = null;
        }
      } else if (_activeLayerId == "1") {
        // Add block logic
      }
    });
  }

  void _showLayersSheet() { /* same as plan */ }

  Offset _screenToWorld(Offset p) => (p - _offset) / _scale;
}

class ElevationPainter extends CustomPainter {
  final List<SketchShape> shapes;
  final List<SketchLayer> layers;
  final SketchShape? selectedShape;
  final SketchShape? previewShape;
  final Offset offset;
  final double scale;

  ElevationPainter({required this.shapes, required this.layers, this.selectedShape, this.previewShape, required this.offset, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Ground Line
    final groundPaint = Paint()..color = Colors.white24..strokeWidth = 2.0 / scale;
    canvas.drawLine(const Offset(-10000, 0), const Offset(10000, 0), groundPaint);

    for (var s in shapes) {
      final layer = layers.firstWhere((l) => l.id == s.layerId);
      s.draw(canvas, Paint(), TextPainter(textDirection: TextDirection.ltr), layer.color, layer.thickness, isSelected: s == selectedShape, scale: scale);
    }

    if (previewShape != null) previewShape!.draw(canvas, Paint(), TextPainter(textDirection: TextDirection.ltr), Colors.white54, 2.0, scale: scale);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
