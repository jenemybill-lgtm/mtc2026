import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:mtc2026/models/sketch_models.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

enum DrawingTool { line, select, move, room, panZoom, rotate, text }

class SketchDrawingScreen extends StatefulWidget {
  final int projectId;
  const SketchDrawingScreen({super.key, required this.projectId});

  @override
  State<SketchDrawingScreen> createState() => _SketchDrawingScreenState();
}

class _SketchDrawingScreenState extends State<SketchDrawingScreen> {
  final List<SketchShape> _shapes = [];
  final List<SketchLayer> _layers = [
    SketchLayer(id: "0", name: "Δομικά", color: Colors.white, thickness: 20.0),
    SketchLayer(id: "1", name: "Έπιπλα", color: Colors.orange, thickness: 5.0),
    SketchLayer(id: "2", name: "Σημειώσεις", color: Colors.purpleAccent, thickness: 2.0),
    SketchLayer(id: "3", name: "Ηλεκτρολογικά", color: Colors.yellow, thickness: 4.0),
    SketchLayer(id: "4", name: "Υδραυλικά", color: Colors.blue, thickness: 4.0),
  ];
  String _activeLayerId = "0";
  DrawingTool _currentTool = DrawingTool.line;
  SketchShape? _selectedShape;
  SketchShape? _previewShape;
  Offset? _startPoint;
  
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  bool _orthoMode = false;
  bool _showGrid = true;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Column(
          children: [
            Text("ΤΕΧΝΙΚΟ ΣΧΕΔΙΟ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text("ΚΑΤΟΨΗ ΕΡΓΟΥ", style: TextStyle(fontSize: 8, color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.grid_on, color: _showGrid ? Colors.blue : Colors.grey), onPressed: () => setState(() => _showGrid = !_showGrid)),
          IconButton(icon: Icon(Icons.straighten, color: _orthoMode ? Colors.blue : Colors.grey), onPressed: () => setState(() => _orthoMode = !_orthoMode)),
          IconButton(icon: const Icon(Icons.layers_rounded), onPressed: _showLayersSheet),
          TextButton(onPressed: _saveSketch, child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRect(
                  child: GestureDetector(
                    onScaleStart: _handleScaleStart,
                    onScaleUpdate: _handleScaleUpdate,
                    onScaleEnd: _handleScaleEnd,
                    onTapDown: _handleTapDown,
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: CustomPaint(
                        painter: CadPainter(
                          shapes: _shapes,
                          layers: _layers,
                          selectedShape: _selectedShape,
                          previewShape: _previewShape,
                          offset: _offset,
                          scale: _scale,
                          showGrid: _showGrid,
                          viewMode: "PLAN",
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16, left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "SCALE: ${_scale.toStringAsFixed(2)}x\nTOOL: ${_currentTool.name.toUpperCase()}",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      color: const Color(0xFF252525),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _toolbarAction(Icons.undo_rounded, () => setState(() { if(_shapes.isNotEmpty) _shapes.removeLast(); })),
              _toolbarTool(DrawingTool.select, Icons.near_me_rounded),
              _toolbarTool(DrawingTool.move, Icons.open_with_rounded),
              _toolbarTool(DrawingTool.line, Icons.edit_road_rounded),
              _toolbarTool(DrawingTool.panZoom, Icons.zoom_out_map_rounded),
              const VerticalDivider(color: Colors.white24),
              _toolbarSymbol("DOOR", Icons.door_front_door_rounded),
              _toolbarSymbol("WINDOW", Icons.window_rounded),
              _toolbarSymbol("SOCKET", Icons.bolt_rounded),
              _toolbarSymbol("FURNITURE", Icons.chair_rounded),
              if (_selectedShape != null) 
                _toolbarAction(Icons.delete_forever_rounded, () => setState(() { _shapes.remove(_selectedShape); _selectedShape = null; }), color: Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarTool(DrawingTool tool, IconData icon) {
    final isSel = _currentTool == tool;
    return IconButton(
      icon: Icon(icon, color: isSel ? Colors.blue : Colors.white70),
      onPressed: () => setState(() { _currentTool = tool; _selectedShape = null; }),
    );
  }

  Widget _toolbarSymbol(String category, IconData icon) {
    return IconButton(
      icon: Icon(icon, color: Colors.white70),
      onPressed: () => _showSymbolPicker(category),
    );
  }

  Widget _toolbarAction(IconData icon, VoidCallback onTap, {Color color = Colors.white70}) {
    return IconButton(icon: Icon(icon, color: color), onPressed: onTap);
  }

  void _showSymbolPicker(String category) {
    final List<Map<String, dynamic>> symbols = category == "DOOR" ? [
      {'type': BlockType.door, 'label': 'Πόρτα'},
      {'type': BlockType.slidingDoor, 'label': 'Συρόμενη'},
    ] : category == "WINDOW" ? [
      {'type': BlockType.window, 'label': 'Παράθυρο'},
      {'type': BlockType.doubleWindow, 'label': 'Δίφυλλο'},
    ] : category == "SOCKET" ? [
      {'type': BlockType.socket, 'label': 'Πρίζα'},
      {'type': BlockType.switchDevice, 'label': 'Διακόπτης'},
    ] : [
      {'type': BlockType.sofa, 'label': 'Καναπές'},
      {'type': BlockType.table, 'label': 'Τραπέζι'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252525),
      builder: (context) => GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 16, crossAxisSpacing: 16),
        itemCount: symbols.length,
        itemBuilder: (context, i) => InkWell(
          onTap: () {
            _addSymbolAtCenter(symbols[i]['type']);
            Navigator.pop(context);
          },
          child: Column(
            children: [
              const Icon(Icons.add_box_rounded, color: Colors.blue),
              const SizedBox(height: 8),
              Text(symbols[i]['label'], style: const TextStyle(color: Colors.white, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  void _addSymbolAtCenter(BlockType type) {
    final center = _screenToWorld(Offset(MediaQuery.of(context).size.width/2, MediaQuery.of(context).size.height/2));
    setState(() {
      _shapes.add(SketchBlock(
        id: DateTime.now().toString(),
        layerId: (type == BlockType.door || type == BlockType.window) ? "0" : "1",
        position: center,
        type: type,
      ));
      _currentTool = DrawingTool.move;
    });
  }

  void _showLayersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252525),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _layers.map((l) => ListTile(
              leading: Container(width: 24, height: 24, decoration: BoxDecoration(color: l.color, borderRadius: BorderRadius.circular(4))),
              title: Text(l.name, style: TextStyle(color: Colors.white, fontWeight: l.id == _activeLayerId ? FontWeight.bold : FontWeight.normal)),
              trailing: IconButton(
                icon: Icon(l.isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                onPressed: () { l.isVisible = !l.isVisible; setSheetState(() {}); setState(() {}); },
              ),
              onTap: () { setState(() => _activeLayerId = l.id); Navigator.pop(context); },
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (details.pointerCount == 1) {
      final worldPos = _screenToWorld(details.localFocalPoint);
      if (_currentTool == DrawingTool.line) _startPoint = _findSnapPoint(worldPos);
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount == 2) {
        _scale *= details.scale;
        _offset += details.focalPointDelta;
      } else if (details.pointerCount == 1) {
        final worldPos = _screenToWorld(details.localFocalPoint);
        if (_currentTool == DrawingTool.line && _startPoint != null) {
          var end = worldPos;
          if (_orthoMode) {
            final dx = (end.dx - _startPoint!.dx).abs();
            final dy = (end.dy - _startPoint!.dy).abs();
            end = dx > dy ? Offset(end.dx, _startPoint!.dy) : Offset(_startPoint!.dx, end.dy);
          }
          _previewShape = SketchLine(id: 'prev', layerId: _activeLayerId, start: _startPoint!, end: end);
        } else if (_currentTool == DrawingTool.move && _selectedShape != null) {
          _selectedShape!.move(details.focalPointDelta / _scale);
        } else if (_currentTool == DrawingTool.panZoom) {
          _offset += details.focalPointDelta;
        }
      }
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    setState(() {
      if (_previewShape != null && _previewShape is SketchLine) {
        final line = _previewShape as SketchLine;
        if ((line.start - line.end).distance > 5) {
          _shapes.add(SketchLine(id: DateTime.now().toString(), layerId: _activeLayerId, start: line.start, end: line.end));
        }
      }
      _previewShape = null;
      _startPoint = null;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    final worldPos = _screenToWorld(details.localPosition);
    setState(() {
      if (_currentTool == DrawingTool.select) {
        _selectedShape = _findHitShape(worldPos);
      }
    });
  }

  SketchShape? _findHitShape(Offset p) {
    for (var s in _shapes.reversed) if (s.isHit(p, 20.0, _scale)) return s;
    return null;
  }

  Offset _findSnapPoint(Offset p) {
    Offset best = p;
    double minDist = 25.0 / _scale;
    for (var s in _shapes) {
      for (var sp in s.getSnapPoints()) {
        final d = (p - sp).distance;
        if (d < minDist) { minDist = d; best = sp; }
      }
    }
    return best;
  }

  Offset _screenToWorld(Offset p) => (p - _offset) / _scale;

  Future<void> _saveSketch() async {
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final appDir = await getApplicationDocumentsDirectory();
      final imagePath = '${appDir.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File(imagePath).create();
      await file.writeAsBytes(pngBytes);

      // Save vector data to database
      final vectorData = jsonEncode(_shapes.map((s) => s.toMap()).toList());
      
      if (mounted) {
        final provider = Provider.of<ProjectProvider>(context, listen: false);
        await provider.addProjectSketch(ProjectSketch(
          projectId: widget.projectId,
          title: "Σχέδιο ${DateFormat('dd/MM HH:mm').format(DateTime.now())}",
          imagePath: imagePath,
          vectorDataJson: vectorData,
        ));
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Το σχέδιο αποθηκεύτηκε επιτυχώς.")));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving sketch: $e");
    }
  }
}

class CadPainter extends CustomPainter {
  final List<SketchShape> shapes;
  final List<SketchLayer> layers;
  final SketchShape? selectedShape;
  final SketchShape? previewShape;
  final Offset offset;
  final double scale;
  final bool showGrid;
  final String viewMode;

  final Paint _paint = Paint()..isAntiAlias = true;
  final TextPainter _textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

  CadPainter({required this.shapes, required this.layers, this.selectedShape, this.previewShape, required this.offset, required this.scale, required this.showGrid, required this.viewMode});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    if (showGrid) _drawGrid(canvas);

    final axisPaint = Paint()..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 1.0 / scale;
    canvas.drawLine(const Offset(-10000, 0), const Offset(10000, 0), axisPaint);
    canvas.drawLine(const Offset(0, -10000), const Offset(0, 10000), axisPaint);

    for (var layer in layers) {
      if (!layer.isVisible) continue;
      final layerShapes = shapes.where((s) => s.layerId == layer.id).toList();
      for (var s in layerShapes) {
        s.draw(canvas, _paint, _textPainter, layer.color, layer.thickness, isSelected: s == selectedShape, allShapes: shapes, scale: scale);
      }
    }

    if (previewShape != null) {
      final layer = layers.firstWhere((l) => l.id == previewShape!.layerId, orElse: () => layers.first);
      previewShape!.draw(canvas, _paint, _textPainter, layer.color.withValues(alpha: 0.5), layer.thickness, scale: scale);
    }

    canvas.restore();
  }

  void _drawGrid(Canvas canvas) {
    final majorPaint = Paint()..color = Colors.white.withValues(alpha: 0.08)..strokeWidth = 1.0 / scale;
    final minorPaint = Paint()..color = Colors.white.withValues(alpha: 0.02)..strokeWidth = 0.5 / scale;
    
    const double majorStep = pixelsPerMeter;
    const double minorStep = pixelsPerMeter / 5;

    for (double i = -5000; i < 5000; i += minorStep) {
      final p = (i % majorStep).abs() < 1.0 ? majorPaint : minorPaint;
      canvas.drawLine(Offset(i, -5000), Offset(i, 5000), p);
      canvas.drawLine(Offset(-5000, i), Offset(5000, i), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
