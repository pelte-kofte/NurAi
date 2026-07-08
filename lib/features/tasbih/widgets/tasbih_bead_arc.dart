import 'dart:math' as math;

import 'package:flutter/material.dart';

class TasbihBeadArc extends StatelessWidget {
  const TasbihBeadArc({
    super.key,
    required this.position,
  });

  final double position;

  static const int totalBeads = 99;
  static const int visibleBeads = 7;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _TasbihBeadArcPainter(position: position),
        size: Size.infinite,
      ),
    );
  }
}

class _TasbihBeadArcPainter extends CustomPainter {
  const _TasbihBeadArcPainter({
    required this.position,
  });

  final double position;

  static const double _anchorSlot = 2.0;
  static const double _startAngle = 3.455751918948773;
  static const double _sweepAngle = 1.8849555921538759;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final wrappedPosition = _wrapPosition(position);
    final baseIndex = wrappedPosition.floor();
    final fractionalShift = wrappedPosition - baseIndex;

    final center = Offset(size.width * 0.34, size.height * 1.08);
    final radius = size.width * 0.80;
    for (var slot = 0; slot < TasbihBeadArc.visibleBeads; slot++) {
      final shiftedSlot = slot - fractionalShift;
      final t = shiftedSlot / (TasbihBeadArc.visibleBeads - 1);
      final angle = _startAngle + (_sweepAngle * t);
      final beadIndex = _positiveModulo(
        baseIndex + slot - _anchorSlot.round(),
        TasbihBeadArc.totalBeads,
      );
      final beadCenter = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final edgeFalloff = (slot - ((TasbihBeadArc.visibleBeads - 1) / 2)).abs();
      final opacity = 1.0 - (edgeFalloff * 0.10);

      if (beadIndex == 0) {
        _paintImame(canvas, beadCenter, angle, opacity);
      } else if (beadIndex == 33 || beadIndex == 66) {
        _paintMarker(canvas, beadCenter, opacity);
      } else {
        _paintStandardBead(canvas, beadCenter, opacity);
      }
    }
  }

  void _paintStandardBead(Canvas canvas, Offset center, double opacity) {
    const radius = 8.2;
    final fill = Paint()
      ..color = const Color(0xFFD8C4A3).withValues(alpha: 0.88 * opacity);
    final stroke = Paint()
      ..color = const Color(0xFFA6885D).withValues(alpha: 0.28 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, stroke);
  }

  void _paintMarker(Canvas canvas, Offset center, double opacity) {
    const radius = 9.2;
    final fill = Paint()
      ..color = const Color(0xFFE8D9BC).withValues(alpha: 0.94 * opacity);
    final stroke = Paint()
      ..color = const Color(0xFF9A7B48).withValues(alpha: 0.38 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, stroke);
  }

  void _paintImame(Canvas canvas, Offset center, double angle, double opacity) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle - (math.pi / 2));

    final beadRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 17, height: 24),
      const Radius.circular(9),
    );
    final fill = Paint()
      ..color = const Color(0xFFF0E6D2).withValues(alpha: 0.96 * opacity);
    final stroke = Paint()
      ..color = const Color(0xFF9A7B48).withValues(alpha: 0.42 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(beadRect, fill);
    canvas.drawRRect(beadRect, stroke);

    final tassel = Paint()
      ..color = const Color(0xFFB59663).withValues(alpha: 0.46 * opacity)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (final dx in const [-2.4, 0.0, 2.4]) {
      canvas.drawLine(
        Offset(dx, 12),
        Offset(dx * 0.7, 24),
        tassel,
      );
    }

    canvas.restore();
  }

  double _wrapPosition(double value) {
    var normalized = value % TasbihBeadArc.totalBeads;
    if (normalized < 0) normalized += TasbihBeadArc.totalBeads;
    return normalized;
  }

  int _positiveModulo(int value, int modulo) {
    final result = value % modulo;
    return result < 0 ? result + modulo : result;
  }

  @override
  bool shouldRepaint(covariant _TasbihBeadArcPainter oldDelegate) {
    return oldDelegate.position != position;
  }
}
