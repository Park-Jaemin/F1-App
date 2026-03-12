import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/car_location.dart';
import '../../../providers/replay_provider.dart';

class CircuitMap extends StatelessWidget {
  /// Track outline points (from one driver's full lap)
  final List<CarLocation> trackPoints;

  /// Current interpolated car positions
  final List<ReplayCarState> cars;

  const CircuitMap({
    super.key,
    required this.trackPoints,
    required this.cars,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: F1Colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: _CircuitPainter(
              trackPoints: trackPoints,
              cars: cars,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  final List<CarLocation> trackPoints;
  final List<ReplayCarState> cars;

  _CircuitPainter({required this.trackPoints, required this.cars});

  @override
  void paint(Canvas canvas, Size size) {
    if (trackPoints.isEmpty) return;

    // Compute bounding box of track
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final p in trackPoints) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    if (rangeX == 0 || rangeY == 0) return;

    const padding = 24.0;
    final drawW = size.width - padding * 2;
    final drawH = size.height - padding * 2;

    final scale = math.min(drawW / rangeX, drawH / rangeY);
    final offsetX = padding + (drawW - rangeX * scale) / 2;
    final offsetY = padding + (drawH - rangeY * scale) / 2;

    Offset toCanvas(double x, double y) {
      return Offset(
        offsetX + (x - minX) * scale,
        offsetY + (maxY - y) * scale, // flip Y axis
      );
    }

    // Draw track outline
    final trackPaint = Paint()
      ..color = F1Colors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Sample every Nth point to keep it smooth
    final step = math.max(1, trackPoints.length ~/ 600);
    bool first = true;
    for (int i = 0; i < trackPoints.length; i += step) {
      final p = toCanvas(trackPoints[i].x, trackPoints[i].y);
      if (first) {
        path.moveTo(p.dx, p.dy);
        first = false;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    // Close the track loop
    if (trackPoints.length > 1) {
      final last = toCanvas(trackPoints.last.x, trackPoints.last.y);
      path.lineTo(last.dx, last.dy);
    }
    canvas.drawPath(path, trackPaint);

    // Draw cars
    for (final car in cars) {
      final pos = toCanvas(car.x, car.y);

      Color teamColor;
      if (car.driver?.teamColour != null) {
        try {
          teamColor = Color(int.parse('FF${car.driver!.teamColour}', radix: 16));
        } catch (_) {
          teamColor = F1Colors.getTeamColor(car.driver?.teamName);
        }
      } else {
        teamColor = F1Colors.getTeamColor(car.driver?.teamName);
      }

      // Car dot
      final carPaint = Paint()
        ..color = teamColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 5, carPaint);

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: car.driver?.nameAcronym ?? '${car.driverNumber}',
          style: TextStyle(
            color: teamColor,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, pos + const Offset(6, -6));
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter oldDelegate) {
    return oldDelegate.cars != cars;
  }
}
