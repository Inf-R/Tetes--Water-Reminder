import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Clips the canvas to a bottle body shape (rounded rectangle with narrower neck)
class BottleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Bottle body proportions
    final neckTop = h * 0.0;
    final neckBottom = h * 0.12;
    final neckWidth = w * 0.35;
    final neckLeft = (w - neckWidth) / 2;
    final neckRight = neckLeft + neckWidth;

    final bodyTop = h * 0.15;
    final bodyRadius = w * 0.08;

    // Start at top-left of neck
    path.moveTo(neckLeft, neckTop);
    path.lineTo(neckRight, neckTop);

    // Right side of neck going down, then flare out to body
    path.lineTo(neckRight, neckBottom);
    path.quadraticBezierTo(w - bodyRadius, bodyTop, w - bodyRadius, bodyTop + bodyRadius);

    // Right side of body going down
    path.lineTo(w - bodyRadius, h - bodyRadius);

    // Bottom-right corner
    path.quadraticBezierTo(w - bodyRadius, h, w - bodyRadius * 2, h);

    // Bottom edge
    path.lineTo(bodyRadius * 2, h);

    // Bottom-left corner
    path.quadraticBezierTo(bodyRadius, h, bodyRadius, h - bodyRadius);

    // Left side of body going up
    path.lineTo(bodyRadius, bodyTop + bodyRadius);

    // Left side flare from body to neck
    path.quadraticBezierTo(bodyRadius, bodyTop, neckLeft, neckBottom);

    // Left side of neck going up
    path.lineTo(neckLeft, neckTop);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Paints the water fill with animated waves inside the bottle
class WaterFillPainter extends CustomPainter {
  final double fillPercent; // 0.0 to 1.0
  final double wavePhase; // animated 0..2π

  WaterFillPainter({required this.fillPercent, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercent <= 0) return;

    final clampedFill = fillPercent.clamp(0.0, 1.0);
    final fillHeight = size.height * clampedFill;
    final waterTop = size.height - fillHeight;

    // Create wave path
    final wavePath = Path();
    final waveAmplitude = size.height * 0.015;
    final waveLength = size.width;

    wavePath.moveTo(0, waterTop);

    for (double x = 0; x <= size.width; x += 1) {
      final y = waterTop +
          sin((x / waveLength * 2 * pi) + wavePhase) * waveAmplitude +
          sin((x / waveLength * 4 * pi) + wavePhase * 1.5) *
              (waveAmplitude * 0.5);
      wavePath.lineTo(x, y);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    // Water gradient
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.waterLight.withValues(alpha: 0.7),
          AppTheme.waterMedium.withValues(alpha: 0.85),
          AppTheme.waterDark.withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, waterTop, size.width, fillHeight));

    canvas.drawPath(wavePath, waterPaint);

    // Second wave layer for depth
    final wave2Path = Path();
    wave2Path.moveTo(0, waterTop);

    for (double x = 0; x <= size.width; x += 1) {
      final y = waterTop +
          sin((x / waveLength * 2 * pi) + wavePhase + pi * 0.7) *
              (waveAmplitude * 0.8) +
          cos((x / waveLength * 3 * pi) + wavePhase * 0.8) *
              (waveAmplitude * 0.3);
      wave2Path.lineTo(x, y);
    }

    wave2Path.lineTo(size.width, size.height);
    wave2Path.lineTo(0, size.height);
    wave2Path.close();

    final wave2Paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryLight.withValues(alpha: 0.3),
          AppTheme.primaryBlue.withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromLTWH(0, waterTop, size.width, fillHeight));

    canvas.drawPath(wave2Path, wave2Paint);
  }

  @override
  bool shouldRepaint(covariant WaterFillPainter old) =>
      old.fillPercent != fillPercent || old.wavePhase != wavePhase;
}

/// Paints the bottle outline (drawn on top of everything)
class BottleOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final neckBottom = h * 0.12;
    final neckWidth = w * 0.35;
    final neckLeft = (w - neckWidth) / 2;
    final neckRight = neckLeft + neckWidth;

    final bodyTop = h * 0.15;
    final bodyRadius = w * 0.08;

    // Bottle outline path
    final path = Path();
    path.moveTo(neckLeft, 0);
    path.lineTo(neckRight, 0);
    path.lineTo(neckRight, neckBottom);
    path.quadraticBezierTo(w - bodyRadius, bodyTop, w - bodyRadius, bodyTop + bodyRadius);
    path.lineTo(w - bodyRadius, h - bodyRadius);
    path.quadraticBezierTo(w - bodyRadius, h, w - bodyRadius * 2, h);
    path.lineTo(bodyRadius * 2, h);
    path.quadraticBezierTo(bodyRadius, h, bodyRadius, h - bodyRadius);
    path.lineTo(bodyRadius, bodyTop + bodyRadius);
    path.quadraticBezierTo(bodyRadius, bodyTop, neckLeft, neckBottom);
    path.lineTo(neckLeft, 0);
    path.close();

    // Outline paint
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.5);

    canvas.drawPath(path, outlinePaint);

    // Cap
    final capWidth = neckWidth + w * 0.1;
    final capLeft = (w - capWidth) / 2;
    final capRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(capLeft, -8, capWidth, 12),
      const Radius.circular(4),
    );
    final capPaint = Paint()
      ..color = AppTheme.primaryBlue
      ..style = PaintingStyle.fill;
    canvas.drawRRect(capRect, capPaint);

    // Measurement lines on the right side
    final lineCount = 4;
    final bodyHeight = h - bodyTop - bodyRadius;
    for (int i = 1; i <= lineCount; i++) {
      final y = h - bodyRadius - (bodyHeight * i / (lineCount + 1));
      final lineLength = i == 2 ? w * 0.12 : w * 0.08;
      final lineX = w - bodyRadius - 4;

      final linePaint = Paint()
        ..color = AppTheme.primaryBlue.withValues(alpha: 0.25)
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(lineX - lineLength, y),
        Offset(lineX, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The animated water bottle widget
class AnimatedWaterBottle extends StatefulWidget {
  final double fillPercent; // 0.0 to 1.0
  final double width;
  final double height;

  const AnimatedWaterBottle({
    super.key,
    required this.fillPercent,
    this.width = 140,
    this.height = 260,
  });

  @override
  State<AnimatedWaterBottle> createState() => _AnimatedWaterBottleState();
}

class _AnimatedWaterBottleState extends State<AnimatedWaterBottle>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _fillAnimation;
  double _currentFill = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _currentFill = widget.fillPercent;
  }

  @override
  void didUpdateWidget(AnimatedWaterBottle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillPercent != widget.fillPercent) {
      _animateFill(oldWidget.fillPercent, widget.fillPercent);
    }
  }

  void _animateFill(double from, double to) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fillAnimation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    _fillAnimation.addListener(() {
      setState(() {
        _currentFill = _fillAnimation.value;
      });
    });
    controller.forward().then((_) => controller.dispose());
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Water fill clipped to bottle shape
              ClipPath(
                clipper: BottleClipper(),
                child: CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: WaterFillPainter(
                    fillPercent: _currentFill,
                    wavePhase: _waveController.value * 2 * pi,
                  ),
                ),
              ),
              // Bottle outline on top
              CustomPaint(
                size: Size(widget.width, widget.height),
                painter: BottleOutlinePainter(),
              ),
            ],
          );
        },
      ),
    );
  }
}
