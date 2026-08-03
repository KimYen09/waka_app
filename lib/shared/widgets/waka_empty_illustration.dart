import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum WakaEmptyIllustrationType { book, wallet, address }

class WakaEmptyIllustration extends StatelessWidget {
  const WakaEmptyIllustration({
    super.key,
    required this.message,
    this.type = WakaEmptyIllustrationType.book,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final WakaEmptyIllustrationType type;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 140,
              child: CustomPaint(
                painter: _EmptyIllustrationPainter(type: type),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtitle != null ? WakaColors.text : WakaColors.mutedText,
                fontSize: subtitle != null ? 18 : 16,
                fontWeight: subtitle != null ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: WakaColors.mutedText,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: WakaColors.accent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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

class _EmptyIllustrationPainter extends CustomPainter {
  _EmptyIllustrationPainter({required this.type});

  final WakaEmptyIllustrationType type;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    _drawCloud(canvas, Offset(cx - 50, cy - 40), 0.7);
    _drawCloud(canvas, Offset(cx + 45, cy - 35), 0.55);
    _drawLeaf(canvas, Offset(cx - 55, cy + 30));
    _drawLeaf(canvas, Offset(cx + 55, cy + 25));

    switch (type) {
      case WakaEmptyIllustrationType.book:
        _drawBook(canvas, Offset(cx, cy + 10));
      case WakaEmptyIllustrationType.wallet:
        _drawWallet(canvas, Offset(cx, cy + 5));
      case WakaEmptyIllustrationType.address:
        _drawAddress(canvas, Offset(cx, cy + 5));
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()
      ..color = const Color(0xFF3A3A3D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12 * scale, paint);
    canvas.drawCircle(
      Offset(center.dx + 14 * scale, center.dy + 2),
      10 * scale,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx - 12 * scale, center.dy + 3),
      8 * scale,
      paint,
    );
  }

  void _drawLeaf(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = const Color(0xFF4A4A4D)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - 10)
      ..quadraticBezierTo(center.dx + 8, center.dy, center.dx, center.dy + 12)
      ..quadraticBezierTo(center.dx - 8, center.dy, center.dx, center.dy - 10);
    canvas.drawPath(path, paint);
  }

  void _drawBook(Canvas canvas, Offset center) {
    final mound = Paint()
      ..color = const Color(0xFF2A2A2D)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 18), width: 80, height: 30),
      3.14,
      3.14,
      true,
      mound,
    );

    final bookPaint = Paint()
      ..color = const Color(0xFF5A5A5D)
      ..style = PaintingStyle.fill;
    final bookRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 36, height: 48),
      const Radius.circular(3),
    );
    canvas.drawRRect(bookRect, bookPaint);

    final spine = Paint()
      ..color = const Color(0xFF707073)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx, center.dy - 24),
      Offset(center.dx, center.dy + 24),
      spine,
    );

    final badge = Paint()..color = WakaColors.accent;
    canvas.drawCircle(Offset(center.dx, center.dy + 38), 14, badge);
    final tp = TextPainter(
      text: const TextSpan(
        text: 'W',
        style: TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + 38 - tp.height / 2));
  }

  void _drawWallet(Canvas canvas, Offset center) {
    final mound = Paint()
      ..color = const Color(0xFF2A2A2D)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 20), width: 90, height: 32),
      3.14,
      3.14,
      true,
      mound,
    );

    final wallet = Paint()
      ..color = const Color(0xFF5A5A5D)
      ..style = PaintingStyle.fill;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 56, height: 40),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, wallet);

    final tp = TextPainter(
      text: const TextSpan(
        text: '\$',
        style: TextStyle(
          color: Color(0xFF9C9C9F),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawAddress(Canvas canvas, Offset center) {
    final mound = Paint()
      ..color = const Color(0xFF2A2A2D)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 22), width: 90, height: 32),
      3.14,
      3.14,
      true,
      mound,
    );

    final body = Paint()
      ..color = const Color(0xFF5A5A5D)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + 4), width: 40, height: 44),
        const Radius.circular(4),
      ),
      body,
    );

    final eye = Paint()..color = const Color(0xFF2A2A2D);
    canvas.drawLine(
      Offset(center.dx - 8, center.dy - 6),
      Offset(center.dx - 2, center.dy),
      eye..strokeWidth = 2.5,
    );
    canvas.drawLine(
      Offset(center.dx + 8, center.dy - 6),
      Offset(center.dx + 2, center.dy),
      eye,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
