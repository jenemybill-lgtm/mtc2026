import 'package:flutter/material.dart';
import 'dart:math' as math;

const double pixelsPerMeter = 100.0;

enum BlockType { 
  door, window, sofa, table, bed, slidingDoor, doubleWindow, foldingDoor, 
  toilet, shower, sink, kitchenSink,
  socket, switchDevice, waterSupply, drain, radiator, ac,
  wallLight, intercom, thermostat, tvSocket, dataSocket, junctionBox, electricalPanel,
  tap, showerHead, waterValve, rollerShutter, skylight
}

class SketchLayer {
  final String id;
  final String name;
  Color color;
  bool isVisible;
  double thickness;

  SketchLayer({required this.id, required this.name, this.color = Colors.white, this.isVisible = true, this.thickness = 20.0});
}

abstract class SketchShape {
  final String id;
  final String layerId;
  Color? color;

  SketchShape({required this.id, required this.layerId, this.color});

  void draw(Canvas canvas, Paint paint, TextPainter textPainter, Color layerColor, double layerThickness, {bool isSelected = false, List<SketchShape> allShapes = const [], double scale = 1.0});
  
  bool isHit(Offset p, double tolerance, double scale);
  void move(Offset delta);
  List<Offset> getSnapPoints();
  Offset getNearestPoint(Offset p);
  
  Offset? getRotationHandle(double scale) => null;
  void rotate(double angle) {}

  Map<String, dynamic> toMap();
}

class SketchLine extends SketchShape {
  Offset start;
  Offset end;

  SketchLine({required super.id, required super.layerId, required this.start, required this.end, super.color});

  @override
  void draw(Canvas canvas, Paint paint, TextPainter textPainter, Color layerColor, double layerThickness, {bool isSelected = false, List<SketchShape> allShapes = const [], double scale = 1.0}) {
    final effectiveColor = isSelected ? Colors.green : (color ?? layerColor);
    paint.color = effectiveColor;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = math.max(1.0, layerThickness / scale);
    paint.strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, paint);

    // Length label
    final length = (start - end).distance / pixelsPerMeter;
    final label = "${length.toStringAsFixed(2)}m";
    textPainter.text = TextSpan(text: label, style: TextStyle(color: Colors.grey, fontSize: 12 / scale, fontWeight: FontWeight.bold));
    textPainter.layout();

    final mid = (start + end) / 2;
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    
    canvas.save();
    canvas.translate(mid.dx, mid.dy);
    canvas.rotate(angle);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height - 4 / scale));
    canvas.restore();
  }

  @override
  Offset getNearestPoint(Offset p) {
    final v = end - start;
    final w = p - start;
    final l2 = v.dx * v.dx + v.dy * v.dy;
    if (l2 == 0) return start;
    double t = (w.dx * v.dx + w.dy * v.dy) / l2;
    t = t.clamp(0.0, 1.0);
    return start + v * t;
  }

  @override
  bool isHit(Offset p, double tolerance, double scale) => (p - getNearestPoint(p)).distance < (tolerance / scale);

  @override
  void move(Offset delta) { start += delta; end += delta; }

  @override
  List<Offset> getSnapPoints() => [start, end, (start + end) / 2];

  @override
  Map<String, dynamic> toMap() => {'type': 'line', 'id': id, 'layerId': layerId, 'x1': start.dx, 'y1': start.dy, 'x2': end.dx, 'y2': end.dy};
}

class SketchBlock extends SketchShape {
  Offset position;
  final BlockType type;
  double rotation;
  double width;
  double height;
  int orientation;
  String? hostWallId;
  double offsetFromStart;

  SketchBlock({
    required super.id,
    required super.layerId,
    required this.position,
    required this.type,
    this.rotation = 0.0,
    this.width = 80.0,
    this.height = 220.0,
    this.orientation = 0,
    this.hostWallId,
    this.offsetFromStart = 0.0,
    super.color,
  });

  @override
  void draw(Canvas canvas, Paint paint, TextPainter textPainter, Color layerColor, double layerThickness, {bool isSelected = false, List<SketchShape> allShapes = const [], double scale = 1.0}) {
    if (hostWallId != null) {
      try {
        final wall = allShapes.whereType<SketchLine>().firstWhere((l) => l.id == hostWallId);
        final dir = wall.end - wall.start;
        final len = dir.distance;
        if (len > 0) {
          position = wall.start + dir * (offsetFromStart / len);
          rotation = math.atan2(dir.dy, dir.dx);
        }
      } catch (_) {}
    }

    paint.color = isSelected ? Colors.cyan : (color ?? layerColor);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0 / scale;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    
    final scaleX = (orientation % 2 == 1) ? -1.0 : 1.0;
    final scaleY = (orientation >= 2) ? -1.0 : 1.0;
    canvas.scale(scaleX, scaleY);

    final w = width / 2;
    switch (type) {
      case BlockType.door:
        canvas.drawRect(Rect.fromLTWH(-2 / scale, -width, 4 / scale, width), paint);
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: width), math.pi * 1.5, math.pi / 2, false, paint);
        canvas.drawLine(Offset.zero, Offset(width, 0), paint);
        break;
      case BlockType.window:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: width, height: 10 / scale), paint);
        canvas.drawLine(Offset(-w, 0), Offset(w, 0), paint);
        break;
      case BlockType.socket:
        canvas.drawCircle(Offset.zero, 10 / scale, paint);
        canvas.drawLine(Offset(-10 / scale, 0), Offset(10 / scale, 0), paint);
        break;
      case BlockType.switchDevice:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 16 / scale, height: 16 / scale), paint);
        canvas.drawCircle(Offset.zero, 4 / scale, paint);
        break;
      default:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: width, height: height / 10), paint);
    }

    canvas.restore();

    if (type == BlockType.door || type == BlockType.window) {
       _drawInfoBox(canvas, paint, textPainter, scale, isSelected);
    }
  }

  void _drawInfoBox(Canvas canvas, Paint paint, TextPainter textPainter, double scale, bool isSelected) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    canvas.translate(0, -45 / scale);

    final boxW = 85.0 / scale;
    final boxH = 55.0 / scale;
    final rect = Rect.fromCenter(center: Offset.zero, width: boxW, height: boxH);

    paint.style = PaintingStyle.fill;
    paint.color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(4 / scale)), paint);

    paint.style = PaintingStyle.stroke;
    paint.color = isSelected ? Colors.green : Colors.black;
    paint.strokeWidth = 1.0 / scale;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(4 / scale)), paint);

    canvas.drawLine(Offset(-boxW / 2, 0), Offset(boxW / 2, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, boxH / 2), paint);

    _drawText(canvas, textPainter, width.toStringAsFixed(0), Offset(0, -boxH / 4), 14 / scale, Colors.black);
    _drawText(canvas, textPainter, height.toStringAsFixed(0), Offset(boxW / 4, boxH / 4), 10 / scale, Colors.black);
    _drawText(canvas, textPainter, "0", Offset(-boxW / 4, boxH / 4), 10 / scale, Colors.black);

    canvas.restore();
  }

  void _drawText(Canvas canvas, TextPainter tp, String text, Offset offset, double size, Color color) {
    tp.text = TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold));
    tp.layout();
    tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  Offset getNearestPoint(Offset p) => position;

  @override
  bool isHit(Offset p, double tolerance, double scale) => (p - position).distance < (80.0 / scale);

  @override
  void move(Offset delta) { if (hostWallId == null) position += delta; }

  @override
  List<Offset> getSnapPoints() => [position];

  @override
  Offset? getRotationHandle(double scale) {
    final dist = 100.0 / scale;
    final rad = rotation - math.pi / 2;
    return position + Offset(math.cos(rad) * dist, math.sin(rad) * dist);
  }

  @override
  void rotate(double angle) { rotation = angle; }

  @override
  Map<String, dynamic> toMap() => {'type': 'block', 'id': id, 'layerId': layerId, 'x': position.dx, 'y': position.dy, 'blockType': type.name, 'rot': rotation, 'w': width, 'h': height};
}

class SketchRoom extends SketchShape {
  final List<Offset> points;
  String name;

  SketchRoom({required super.id, required super.layerId, required this.points, required this.name, super.color});

  @override
  void draw(Canvas canvas, Paint paint, TextPainter textPainter, Color layerColor, double layerThickness, {bool isSelected = false, List<SketchShape> allShapes = const [], double scale = 1.0}) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) path.lineTo(points[i].dx, points[i].dy);
    path.close();

    paint.style = PaintingStyle.fill;
    paint.color = isSelected ? Colors.cyan.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1);
    canvas.drawPath(path, paint);

    paint.style = PaintingStyle.stroke;
    paint.color = isSelected ? Colors.cyan : (color ?? layerColor);
    paint.strokeWidth = 2.0 / scale;
    canvas.drawPath(path, paint);

    final centroid = _calculateCentroid();
    final area = _calculateArea() / (pixelsPerMeter * pixelsPerMeter);
    
    textPainter.text = TextSpan(
      text: "$name\n${area.toStringAsFixed(2)} m²",
      style: TextStyle(color: Colors.white, fontSize: 16 / scale, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, centroid - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  double _calculateArea() {
    double area = 0.0;
    for (var i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      area += (p1.dx * p2.dy) - (p2.dx * p1.dy);
    }
    return area.abs() / 2.0;
  }

  Offset _calculateCentroid() {
    double sx = 0, sy = 0;
    for (var p in points) { sx += p.dx; sy += p.dy; }
    return Offset(sx / points.length, sy / points.length);
  }

  @override
  Offset getNearestPoint(Offset p) => points.reduce((a, b) => (a - p).distance < (b - p).distance ? a : b);

  @override
  bool isHit(Offset p, double tolerance, double scale) => (p - _calculateCentroid()).distance < (60.0 / scale);

  @override
  void move(Offset delta) { for (var i = 0; i < points.length; i++) points[i] += delta; }

  @override
  List<Offset> getSnapPoints() => points;

  @override
  Map<String, dynamic> toMap() => {'type': 'room', 'id': id, 'layerId': layerId, 'points': points.map((p) => [p.dx, p.dy]).toList(), 'name': name};
}
