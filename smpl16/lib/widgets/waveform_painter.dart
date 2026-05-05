import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WaveformPainter extends CustomPainter {
  final Float32List? data;
  final Color color;
  final bool glow;
  final double amplitude; // 0.0-1.0, live amplitude override

  const WaveformPainter({
    this.data,
    this.color = AppColors.accent,
    this.glow = true,
    this.amplitude = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    if (data == null || data!.isEmpty) {
      _drawEmpty(canvas, size);
      return;
    }

    final pts = data!;
    final step = pts.length / w;

    if (glow) {
      final glowPaint = Paint()
        ..color = color.withAlpha(30)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(_buildPath(pts, step, w, mid, h, margin: 6), glowPaint);
    }

    final mainPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(_buildPath(pts, step, w, mid, h, margin: 4), mainPaint);
  }

  Path _buildPath(
    Float32List pts,
    double step,
    double w,
    double mid,
    double h, {
    double margin = 4,
  }) {
    final path = Path();
    for (int x = 0; x < w.toInt(); x++) {
      final idx = (x * step).floor().clamp(0, pts.length - 1);
      final amp = pts[idx];
      final top = mid - amp * (mid - margin);
      final bot = mid + amp * (mid - margin);
      path.moveTo(x.toDouble() + 0.5, top);
      path.lineTo(x.toDouble() + 0.5, bot);
    }
    return path;
  }

  void _drawEmpty(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textDim
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(WaveformPainter old) =>
      old.data != data ||
      old.color != color ||
      old.amplitude != amplitude;
}

/// Live waveform bar that shows amplitude as a simple bar.
class LiveAmplitudePainter extends CustomPainter {
  final double amplitude;
  final Color color;

  const LiveAmplitudePainter({
    required this.amplitude,
    this.color = AppColors.red,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.surface2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final barPaint = Paint()..color = color;
    final barWidth = size.width * amplitude;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.25, barWidth, size.height * 0.5),
      barPaint,
    );

    // Peak line
    if (amplitude > 0.02) {
      final peakPaint = Paint()
        ..color = color.withAlpha(200)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(barWidth, 0),
        Offset(barWidth, size.height),
        peakPaint,
      );
    }
  }

  @override
  bool shouldRepaint(LiveAmplitudePainter old) => old.amplitude != amplitude;
}
