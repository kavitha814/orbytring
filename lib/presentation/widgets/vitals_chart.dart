import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/vital_record.dart';

class VitalsChart extends StatelessWidget {
  final List<VitalRecord> history;

  const VitalsChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderSteelSilver,
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: ChartPainter(history: history),
        ),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<VitalRecord> history;

  ChartPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background Clinical ECG Grid
    final gridPaint = Paint()
      ..color = AppTheme.borderSteelSilver.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final double stepX = 25.0;
    for (double x = 0; x < size.width; x += stepX) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    final double stepY = 20.0;
    for (double y = 0; y < size.height; y += stepY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (history.length < 2) {
      // Draw standard flatline baseline in center if no history
      final baselinePaint = Paint()
        ..color = AppTheme.textGunmetal.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        baselinePaint,
      );
      return;
    }

    // 2. Compute dynamic Y scaling to prevent cramping
    double minVal = history.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    double maxVal = history.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    // Add comfortable padding to limits
    minVal = (minVal - 5.0).clamp(30.0, 200.0);
    maxVal = (maxVal + 5.0).clamp(40.0, 220.0);
    final range = (maxVal - minVal) == 0 ? 10.0 : (maxVal - minVal);

    // 3. Map records to physical canvas points
    final List<Offset> points = [];
    final double segmentWidth = size.width / 35.0; // Fixed capacity size

    for (int i = 0; i < history.length; i++) {
      final x = i * segmentWidth;
      // Invert Y because canvas origin (0,0) is top-left
      final y = size.height - ((history[i].value - minVal) / range * size.height);
      points.add(Offset(x, y.clamp(5.0, size.height - 5.0)));
    }

    // 4. Draw Glow Gradient Fill under path
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.accentRoseGold.withOpacity(0.25),
        AppTheme.accentRoseGold.withOpacity(0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(fillPath, fillPaint);

    // 5. Draw Plotted ECG Wave Line
    final wavePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // Cubic bezier control points for smooth flowing waves
      final p0 = points[i - 1];
      final p1 = points[i];
      final controlX = p0.dx + (p1.dx - p0.dx) / 2;
      wavePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final wavePaint = Paint()
      ..color = AppTheme.accentRoseGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(wavePath, wavePaint);

    // 6. Draw Glowing cursor node at the trailing live point
    final activeNode = points.last;
    final glowPaint = Paint()
      ..color = AppTheme.accentRoseGold.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(activeNode, 8.0, glowPaint);
    canvas.drawCircle(activeNode, 3.5, Paint()..color = AppTheme.accentAuricGold..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    // Repaint on new data point inputs
    return oldDelegate.history.length != history.length || 
           (history.isNotEmpty && oldDelegate.history.isNotEmpty && oldDelegate.history.last.value != history.last.value);
  }
}
