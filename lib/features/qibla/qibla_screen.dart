import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';

/// Full Qibla compass screen using device sensors.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  // Permission / sensor readiness state
  bool _loading = true;
  bool _permissionDenied = false;
  bool _sensorUnavailable = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _init();
    } else {
      _loading = false;
    }
  }

  Future<void> _init() async {
    try {
      // Check device sensor support (Android-specific; iOS always returns true).
      final sensorAvailable = await FlutterQiblah.androidDeviceSensorSupport();
      if (sensorAvailable != null && !sensorAvailable) {
        setState(() {
          _sensorUnavailable = true;
          _loading = false;
        });
        return;
      }

      // Check & request location permission via geolocator.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _permissionDenied = true;
          _loading = false;
        });
        return;
      }

      // Check if location service is enabled.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Konum servisleri kapalı.\nLütfen cihaz ayarlarından açın.';
          _loading = false;
        });
        return;
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Konum bilgisi alınamadı.\nLütfen tekrar deneyin.';
        _loading = false;
      });
    }
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: Color(0xFF7A746F),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Kıble',
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Web platform: calm "not supported" message.
    if (kIsWeb) {
      return _buildMessage('Bu özellik web\'de desteklenmiyor.');
    }

    // Still loading permissions / sensor check.
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFB5AEA8),
          ),
        ),
      );
    }

    // Permission denied.
    if (_permissionDenied) {
      return _buildMessage(
        'Kıble yönünü belirlemek için\nkonum iznine ihtiyacımız var.',
        action: 'Ayarları Aç',
        onAction: () => Geolocator.openAppSettings(),
      );
    }

    // Sensor unavailable.
    if (_sensorUnavailable) {
      return _buildMessage(
        'Bu cihazda pusula sensörü\ntespit edilemedi.',
      );
    }

    // Generic error.
    if (_errorMessage.isNotEmpty) {
      return _buildMessage(_errorMessage);
    }

    // Compass stream.
    return _QiblaCompass();
  }

  /// Renders a calm centered message with optional action button.
  Widget _buildMessage(String text, {String? action, VoidCallback? onAction}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF7A746F),
                height: 1.6,
              ),
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onAction,
                child: Text(
                  action,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB57A5A),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Compass widget (extracted to keep build clean) ────────────────────────

class _QiblaCompass extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFB5AEA8),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Pusula verisi alınamıyor.\nCihazınızı 8 şeklinde hareket ettirerek\nkalibre etmeyi deneyin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A746F),
                  height: 1.6,
                ),
              ),
            ),
          );
        }

        final qiblah = snapshot.data!;
        // qiblah.qiblah  = bearing from north to Qibla (absolute)
        // qiblah.direction = device heading from north
        // offset = how many degrees the device must turn to face Qibla
        final needleAngle = qiblah.qiblah * (math.pi / 180) * -1;
        final compassAngle = qiblah.direction * (math.pi / 180) * -1;
        final qiblaDegrees = qiblah.qiblah.toInt() % 360;

        return Column(
          children: [
            const Spacer(flex: 2),
            // Compass
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring (rotates with compass heading)
                  Transform.rotate(
                    angle: compassAngle,
                    child: CustomPaint(
                      size: const Size(280, 280),
                      painter: _CompassRingPainter(),
                    ),
                  ),
                  // Qibla needle (points to Qibla)
                  Transform.rotate(
                    angle: needleAngle,
                    child: CustomPaint(
                      size: const Size(280, 280),
                      painter: _NeedlePainter(),
                    ),
                  ),
                  // Center dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB57A5A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Degree readout
            Text(
              'Kıble: $qiblaDegrees°',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2B2725),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            // Calibration hint (always shown subtly)
            const Text(
              'Kalibrasyon için cihazınızı 8 şeklinde hareket ettirin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFFB5AEA8),
              ),
            ),
            const Spacer(flex: 3),
          ],
        );
      },
    );
  }
}

// ── Custom painters ───────────────────────────────────────────────────────

/// Draws the circular compass ring with N/S/E/W labels and tick marks.
class _CompassRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Outer ring
    final ringPaint = Paint()
      ..color = const Color(0xFFEDE6E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, ringPaint);

    // Tick marks + cardinal labels
    final tickPaint = Paint()
      ..color = const Color(0xFFB5AEA8)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final cardinalLabels = {0: 'K', 90: 'D', 180: 'G', 270: 'B'};

    for (int i = 0; i < 360; i += 10) {
      final angle = (i - 90) * math.pi / 180;
      final isCardinal = i % 90 == 0;
      final isMajor = i % 30 == 0;

      final outerR = radius;
      final innerR = isCardinal
          ? radius - 14
          : isMajor
              ? radius - 10
              : radius - 6;

      final outer = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );
      final inner = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );

      canvas.drawLine(
        outer,
        inner,
        tickPaint
          ..strokeWidth = isCardinal ? 2.0 : 1.0
          ..color = isCardinal
              ? const Color(0xFF7A746F)
              : const Color(0xFFB5AEA8),
      );

      // Cardinal labels
      if (cardinalLabels.containsKey(i)) {
        final labelR = radius - 26;
        final labelPos = Offset(
          center.dx + labelR * math.cos(angle),
          center.dy + labelR * math.sin(angle),
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: cardinalLabels[i],
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: i == 0
                  ? const Color(0xFFB57A5A)
                  : const Color(0xFF7A746F),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        canvas.save();
        canvas.translate(labelPos.dx, labelPos.dy);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws the Qibla needle – a simple elongated triangle pointing up (north).
class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Needle pointing upward (toward Qibla)
    final needlePaint = Paint()
      ..color = const Color(0xFFB57A5A)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy - radius + 30) // tip
      ..lineTo(center.dx - 6, center.dy - 20) // left base
      ..lineTo(center.dx + 6, center.dy - 20) // right base
      ..close();
    canvas.drawPath(path, needlePaint);

    // Small tail opposite
    final tailPaint = Paint()
      ..color = const Color(0xFFEDE6E1)
      ..style = PaintingStyle.fill;

    final tailPath = Path()
      ..moveTo(center.dx, center.dy + radius - 50)
      ..lineTo(center.dx - 4, center.dy + 20)
      ..lineTo(center.dx + 4, center.dy + 20)
      ..close();
    canvas.drawPath(tailPath, tailPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
