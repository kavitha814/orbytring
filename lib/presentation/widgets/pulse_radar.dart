import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PulseRadar extends StatefulWidget {
  final bool isScanning;

  const PulseRadar({super.key, required this.isScanning});

  @override
  State<PulseRadar> createState() => _PulseRadarState();
}

class _PulseRadarState extends State<PulseRadar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isScanning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PulseRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isScanning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: RadarPainter(
              animationValue: _controller.value,
              isScanning: widget.isScanning,
            ),
          );
        },
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double animationValue;
  final bool isScanning;

  RadarPainter({required this.animationValue, required this.isScanning});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width / 2, size.height / 2);

    // Paints
    final circlePaint = Paint()
      ..color = AppTheme.borderSteelSilver
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final glowPaint = Paint()
      ..color = AppTheme.accentAuricGold.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    // Draw background grid circles
    canvas.drawCircle(center, maxRadius, circlePaint);
    canvas.drawCircle(center, maxRadius * 0.7, circlePaint);
    canvas.drawCircle(center, maxRadius * 0.4, circlePaint);
    
    // Draw crosshair lines
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      circlePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      circlePaint,
    );

    if (isScanning) {
      // Draw pulsing ring waves
      for (int i = 0; i < 3; i++) {
        final t = (animationValue + (i / 3.0)) % 1.0;
        final radius = maxRadius * t;
        final opacity = (1.0 - t) * 0.5;

        final wavePaint = Paint()
          ..color = AppTheme.accentAuricGold.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(center, radius, wavePaint);
      }

      // Draw rotating radar sweep line
      final angle = animationValue * 2 * math.pi;
      final sweepEnd = Offset(
        center.dx + maxRadius * math.cos(angle),
        center.dy + maxRadius * math.sin(angle),
      );

      final sweepPaint = Paint()
        ..color = AppTheme.accentAuricGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawLine(center, sweepEnd, sweepPaint);

      // Draw faint gradient sweep arc behind the line
      final rect = Rect.fromCircle(center: center, radius: maxRadius);
      final sweepGradient = SweepGradient(
        center: Alignment.center,
        startAngle: angle - (math.pi / 2),
        endAngle: angle,
        colors: [
          AppTheme.accentAuricGold.withOpacity(0.0),
          AppTheme.accentAuricGold.withOpacity(0.15),
        ],
        stops: const [0.0, 1.0],
      );

      final arcPaint = Paint()
        ..shader = sweepGradient.createShader(rect)
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, angle - (math.pi / 2), math.pi / 2, true, arcPaint);
    } else {
      // Draw idle glow in the center
      canvas.drawCircle(center, maxRadius * 0.2, glowPaint..color = AppTheme.textGunmetal.withOpacity(0.1));
    }

    // Draw central node pulse
    final pulseRadius = isScanning 
        ? 6.0 + 2.0 * math.sin(animationValue * 4 * math.pi)
        : 6.0;
        
    final nodePaint = Paint()
      ..color = isScanning ? AppTheme.accentAuricGold : AppTheme.textGunmetal
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, pulseRadius, nodePaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.isScanning != isScanning;
  }
}
