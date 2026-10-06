import 'dart:math';
import 'package:flutter/material.dart';

/// Animated water bottle widget that fills based on progress percentage
class WaterBottleWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int currentMl;
  final int targetMl;

  const WaterBottleWidget({
    super.key,
    required this.progress,
    required this.currentMl,
    required this.targetMl,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: 160,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bottle shape with water fill
          CustomPaint(
            size: const Size(160, 280),
            painter: _BottlePainter(progress: clampedProgress),
          ),
          // Bottle cap
          Positioned(
            top: 0,
            child: Container(
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5C9CE5), Color(0xFF3B7DD8)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                border: Border.all(
                  color: const Color(0xFF3B7DD8),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottlePainter extends CustomPainter {
  final double progress;

  _BottlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bottle neck starts below the cap
    final neckTop = 24.0;
    final neckBottom = 60.0;
    final neckWidth = 28.0;
    final bodyTop = neckBottom + 10;
    final bodyBottom = h - 12;
    final bodyWidth = w * 0.65;
    final cornerRadius = 16.0;

    // Build bottle outline path
    final bottlePath = Path();

    // Left side of neck
    bottlePath.moveTo((w - neckWidth) / 2, neckTop);
    bottlePath.lineTo((w - neckWidth) / 2, neckBottom);

    // Left curve from neck to body
    bottlePath.quadraticBezierTo(
      (w - bodyWidth) / 2 - 5,
      neckBottom + 5,
      (w - bodyWidth) / 2,
      bodyTop,
    );

    // Left side of body
    bottlePath.lineTo((w - bodyWidth) / 2, bodyBottom - cornerRadius);

    // Bottom left corner
    bottlePath.quadraticBezierTo(
      (w - bodyWidth) / 2,
      bodyBottom,
      (w - bodyWidth) / 2 + cornerRadius,
      bodyBottom,
    );

    // Bottom side
    bottlePath.lineTo((w + bodyWidth) / 2 - cornerRadius, bodyBottom);

    // Bottom right corner
    bottlePath.quadraticBezierTo(
      (w + bodyWidth) / 2,
      bodyBottom,
      (w + bodyWidth) / 2,
      bodyBottom - cornerRadius,
    );

    // Right side of body
    bottlePath.lineTo((w + bodyWidth) / 2, bodyTop);

    // Right curve from body to neck
    bottlePath.quadraticBezierTo(
      (w + neckWidth) / 2 + 5,
      neckBottom + 5,
      (w + neckWidth) / 2,
      neckBottom,
    );

    // Right side of neck
    bottlePath.lineTo((w + neckWidth) / 2, neckTop);

    bottlePath.close();

    // Draw bottle outline (light blue)
    final outlinePaint = Paint()
      ..color = const Color(0xFFB3D9F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(bottlePath, outlinePaint);

    // Draw bottle interior fill (very light)
    final interiorPaint = Paint()
      ..color = const Color(0xFFE8F4FD)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bottlePath, interiorPaint);

    // Calculate water fill area
    if (progress > 0) {
      // Water fills from bottom to the calculated height
      final fillableTop = bodyTop + 4;
      final fillableBottom = bodyBottom - 4;
      final fillableHeight = fillableBottom - fillableTop;
      final waterTop = fillableBottom - (fillableHeight * progress);

      // Create a clipped water rect within the bottle shape
      canvas.save();
      canvas.clipPath(bottlePath);

      // Water gradient
      final waterPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF64B5F6).withValues(alpha: 0.7),
            const Color(0xFF2196F3).withValues(alpha: 0.85),
            const Color(0xFF1976D2),
          ],
        ).createShader(Rect.fromLTRB(0, waterTop, w, fillableBottom));

      // Draw water body
      canvas.drawRect(
        Rect.fromLTRB(0, waterTop, w, fillableBottom + 10),
        waterPaint,
      );

      // Draw wave on top of water
      final wavePath = Path();
      final waveHeight = 6.0;
      wavePath.moveTo(0, waterTop);
      for (double x = 0; x <= w; x += 1) {
        final y =
            waterTop + sin(x * 0.04 * pi) * waveHeight;
        wavePath.lineTo(x, y);
      }
      wavePath.lineTo(w, fillableBottom + 10);
      wavePath.lineTo(0, fillableBottom + 10);
      wavePath.close();

      final wavePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF42A5F5).withValues(alpha: 0.8),
            const Color(0xFF1E88E5),
          ],
        ).createShader(Rect.fromLTRB(0, waterTop, w, fillableBottom));
      canvas.drawPath(wavePath, wavePaint);

      // Draw some bubble highlights
      if (progress > 0.1) {
        final bubblePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;

        final bubbleY1 = waterTop + fillableHeight * 0.3;
        final bubbleY2 = waterTop + fillableHeight * 0.6;
        if (bubbleY1 < fillableBottom) {
          canvas.drawCircle(Offset(w * 0.35, bubbleY1), 4, bubblePaint);
        }
        if (bubbleY2 < fillableBottom) {
          canvas.drawCircle(Offset(w * 0.6, bubbleY2), 3, bubblePaint);
        }
        if (progress > 0.4) {
          canvas.drawCircle(
              Offset(w * 0.45, waterTop + fillableHeight * 0.45), 2.5, bubblePaint);
        }
      }

      canvas.restore();
    }

    // Draw measurement marks on the bottle
    final markPaint = Paint()
      ..color = const Color(0xFFB3D9F7)
      ..strokeWidth = 1;

    final fillableTop = bodyTop + 4;
    final fillableBottom = bodyBottom - 4;
    final fillableHeight = fillableBottom - fillableTop;

    for (int i = 1; i <= 3; i++) {
      final y = fillableBottom - (fillableHeight * i / 4);
      final leftX = (w - bodyWidth) / 2 + 8;
      canvas.drawLine(Offset(leftX, y), Offset(leftX + 12, y), markPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BottlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
