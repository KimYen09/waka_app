import 'package:flutter/material.dart';

class AcornIcon extends StatelessWidget {
  const AcornIcon({super.key, required this.color, this.size = 30});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AcornPainter(color)),
    );
  }
}

class _AcornPainter extends CustomPainter {
  const _AcornPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.083
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final body = Path()
      ..moveTo(size.width * 0.23, size.height * 0.44)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.70,
        size.width * 0.36,
        size.height * 0.94,
        size.width * 0.58,
        size.height * 0.88,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.82,
        size.width * 0.88,
        size.height * 0.55,
        size.width * 0.69,
        size.height * 0.37,
      );

    final cap = Path()
      ..moveTo(size.width * 0.18, size.height * 0.39)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.19,
        size.width * 0.58,
        size.height * 0.13,
        size.width * 0.78,
        size.height * 0.30,
      )
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.45,
        size.width * 0.38,
        size.height * 0.50,
        size.width * 0.18,
        size.height * 0.39,
      );

    canvas.drawPath(body, stroke);
    canvas.drawPath(cap, stroke);
    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.16),
      Offset(size.width * 0.66, size.height * 0.04),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _AcornPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
