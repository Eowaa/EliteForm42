import 'package:flutter/material.dart';

/// Minimaler Verlaufsgraph – bewusst ohne Chart-Paket, damit das Projekt
/// keine zusätzliche Abhängigkeit mitschleppt.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.color});

  final List<double> values;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        values: values,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
      size: const Size.fromHeight(28),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    var min = values.first;
    var max = values.first;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final span = (max - min).abs() < 0.001 ? 1.0 : max - min;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - min) / span) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values.length != values.length ||
      (old.values.isNotEmpty &&
          values.isNotEmpty &&
          old.values.last != values.last);
}
