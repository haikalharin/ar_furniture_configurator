import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../geometry/furniture_builder.dart';

/// Gambar kerja sederhana: tampak depan dan tampak samping dengan ukuran.
class WorkDrawing extends StatelessWidget {
  const WorkDrawing({super.key, required this.model});

  final FurnitureModel model;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1.6,
      child: CustomPaint(
        painter: _DrawingPainter(
          model,
          line: scheme.onSurface,
          accent: scheme.primary,
          text: Theme.of(context).textTheme.labelSmall!,
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter(
    this.model, {
    required this.line,
    required this.accent,
    required this.text,
  });

  final FurnitureModel model;
  final Color line;
  final Color accent;
  final TextStyle text;

  @override
  void paint(Canvas canvas, Size size) {
    final parts = model.parts;
    double minOf(double Function(Part) f) => parts.map(f).reduce(math.min);
    double maxOf(double Function(Part) f) => parts.map(f).reduce(math.max);
    final x0 = minOf((p) => p.x0), x1 = maxOf((p) => p.x1);
    final z0 = minOf((p) => p.z0), z1 = maxOf((p) => p.z1);
    final y1 = maxOf((p) => p.y1);
    final w = x1 - x0, d = z1 - z0, h = y1;

    const margin = 28.0;
    const spacing = 36.0;
    final scale = math.min(
      (size.width - 2 * margin - spacing) / (w + d),
      (size.height - 2 * margin) / h,
    );
    final floorY = size.height - margin;
    final frontLeft = margin;
    final sideLeft = margin + w * scale + spacing;

    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final accentStroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Bagian paling depan digambar terakhir agar tidak tertutup.
    final front = [...parts]..sort((a, b) => a.z1.compareTo(b.z1));
    for (final p in front) {
      canvas.drawRect(
        Rect.fromLTRB(
          frontLeft + (p.x0 - x0) * scale,
          floorY - p.y1 * scale,
          frontLeft + (p.x1 - x0) * scale,
          floorY - p.y0 * scale,
        ),
        p.slot == PartSlot.body ? stroke : accentStroke,
      );
    }
    for (final p in parts) {
      canvas.drawRect(
        Rect.fromLTRB(
          sideLeft + (p.z0 - z0) * scale,
          floorY - p.y1 * scale,
          sideLeft + (p.z1 - z0) * scale,
          floorY - p.y0 * scale,
        ),
        p.slot == PartSlot.body ? stroke : accentStroke,
      );
    }

    final top = floorY - h * scale;
    _hDim(canvas, frontLeft, frontLeft + w * scale, top - 12, w);
    _hDim(canvas, sideLeft, sideLeft + d * scale, top - 12, d);
    _vDim(canvas, frontLeft - 12, top, floorY, h);
    _label(canvas, 'Tampak depan', Offset(frontLeft, floorY + 6));
    _label(canvas, 'Tampak samping', Offset(sideLeft, floorY + 6));
  }

  void _hDim(Canvas canvas, double a, double b, double y, double meters) {
    final paint = Paint()..color = line.withValues(alpha: 0.6);
    canvas
      ..drawLine(Offset(a, y), Offset(b, y), paint)
      ..drawLine(Offset(a, y - 4), Offset(a, y + 4), paint)
      ..drawLine(Offset(b, y - 4), Offset(b, y + 4), paint);
    _label(
      canvas,
      '${(meters * 100).round()}',
      Offset((a + b) / 2, y - 14),
      center: true,
    );
  }

  void _vDim(Canvas canvas, double x, double a, double b, double meters) {
    final paint = Paint()..color = line.withValues(alpha: 0.6);
    canvas
      ..drawLine(Offset(x, a), Offset(x, b), paint)
      ..drawLine(Offset(x - 4, a), Offset(x + 4, a), paint)
      ..drawLine(Offset(x - 4, b), Offset(x + 4, b), paint);
    canvas.save();
    canvas.translate(x - 14, (a + b) / 2);
    canvas.rotate(-math.pi / 2);
    _label(canvas, '${(meters * 100).round()}', Offset.zero, center: true);
    canvas.restore();
  }

  void _label(Canvas canvas, String s, Offset at, {bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: text.copyWith(color: line),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center ? at - Offset(tp.width / 2, 0) : at);
  }

  @override
  bool shouldRepaint(_DrawingPainter old) =>
      old.model != model || old.line != line;
}
