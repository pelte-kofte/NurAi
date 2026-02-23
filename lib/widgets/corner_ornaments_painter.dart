import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CornerOrnamentPlacement { top, bottom }

class CornerOrnamentsPaint extends StatelessWidget {
  const CornerOrnamentsPaint({
    super.key,
    this.opacity = 0.14,
    this.strokeWidth = 1.2,
    this.placement = CornerOrnamentPlacement.top,
  });

  final double opacity;
  final double strokeWidth;
  final CornerOrnamentPlacement placement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(context).brightness == Brightness.dark
        ? scheme.onSurface
        : AppColors.indigoAccent;
    final color = base.withValues(alpha: opacity.clamp(0.10, 0.18));

    return CustomPaint(
      painter: CornerOrnamentsPainter(
        color: color,
        strokeWidth: strokeWidth,
        placement: placement,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class CornerOrnamentsPainter extends CustomPainter {
  const CornerOrnamentsPainter({
    required this.color,
    required this.strokeWidth,
    required this.placement,
  });

  final Color color;
  final double strokeWidth;
  final CornerOrnamentPlacement placement;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final corner = (size.shortestSide * 0.22).clamp(56.0, 92.0);
    final y = placement == CornerOrnamentPlacement.top ? 0.0 : size.height;

    _drawCorner(
      canvas: canvas,
      paint: paint,
      origin: Offset(0, y),
      cornerSize: corner,
      isRight: false,
      isBottom: placement == CornerOrnamentPlacement.bottom,
    );
    _drawCorner(
      canvas: canvas,
      paint: paint,
      origin: Offset(size.width, y),
      cornerSize: corner,
      isRight: true,
      isBottom: placement == CornerOrnamentPlacement.bottom,
    );
  }

  void _drawCorner({
    required Canvas canvas,
    required Paint paint,
    required Offset origin,
    required double cornerSize,
    required bool isRight,
    required bool isBottom,
  }) {
    final sx = isRight ? -1.0 : 1.0;
    final sy = isBottom ? -1.0 : 1.0;

    Offset p(double x, double y) =>
        Offset(origin.dx + (x * sx), origin.dy + (y * sy));

    final frame = Path()
      ..moveTo(p(8, 0).dx, p(8, 0).dy)
      ..lineTo(p(cornerSize * 0.72, 0).dx, p(cornerSize * 0.72, 0).dy)
      ..lineTo(
        p(cornerSize * 0.72, cornerSize * 0.72).dx,
        p(cornerSize * 0.72, cornerSize * 0.72).dy,
      )
      ..lineTo(p(0, cornerSize * 0.72).dx, p(0, cornerSize * 0.72).dy);
    canvas.drawPath(frame, paint);

    final innerFrame = Path()
      ..moveTo(p(18, 0).dx, p(18, 0).dy)
      ..lineTo(p(cornerSize * 0.58, 0).dx, p(cornerSize * 0.58, 0).dy)
      ..lineTo(
        p(cornerSize * 0.58, cornerSize * 0.58).dx,
        p(cornerSize * 0.58, cornerSize * 0.58).dy,
      )
      ..lineTo(p(0, cornerSize * 0.58).dx, p(0, cornerSize * 0.58).dy);
    canvas.drawPath(innerFrame, paint);

    final lattice = Path()
      ..moveTo(p(cornerSize * 0.18, cornerSize * 0.18).dx,
          p(cornerSize * 0.18, cornerSize * 0.18).dy)
      ..lineTo(p(cornerSize * 0.44, cornerSize * 0.10).dx,
          p(cornerSize * 0.44, cornerSize * 0.10).dy)
      ..lineTo(p(cornerSize * 0.66, cornerSize * 0.24).dx,
          p(cornerSize * 0.66, cornerSize * 0.24).dy)
      ..lineTo(p(cornerSize * 0.56, cornerSize * 0.48).dx,
          p(cornerSize * 0.56, cornerSize * 0.48).dy)
      ..lineTo(p(cornerSize * 0.32, cornerSize * 0.58).dx,
          p(cornerSize * 0.32, cornerSize * 0.58).dy)
      ..lineTo(p(cornerSize * 0.14, cornerSize * 0.42).dx,
          p(cornerSize * 0.14, cornerSize * 0.42).dy)
      ..close();
    canvas.drawPath(lattice, paint);

    canvas.drawLine(
      p(cornerSize * 0.18, cornerSize * 0.18),
      p(cornerSize * 0.56, cornerSize * 0.48),
      paint,
    );
    canvas.drawLine(
      p(cornerSize * 0.44, cornerSize * 0.10),
      p(cornerSize * 0.32, cornerSize * 0.58),
      paint,
    );
    canvas.drawLine(
      p(cornerSize * 0.14, cornerSize * 0.42),
      p(cornerSize * 0.66, cornerSize * 0.24),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CornerOrnamentsPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.placement != placement;
  }
}
