import 'package:flutter/material.dart';

class ShoplyLogo extends StatelessWidget {
  const ShoplyLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ShoplyLogoPainter()),
    ),
  );
}

class _ShoplyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 64, 64),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xFF196B58),
    );
    final Path bag = Path()
      ..moveTo(18, 24)
      ..lineTo(46, 24)
      ..lineTo(49, 48)
      ..quadraticBezierTo(49, 51, 46, 51)
      ..lineTo(18, 51)
      ..quadraticBezierTo(15, 51, 15, 48)
      ..close();
    canvas.drawPath(bag, Paint()..color = const Color(0xFFF0FAEE));
    final Paint stroke = Paint()
      ..color = const Color(0xFFF0FAEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(24, 25)
        ..lineTo(24, 21)
        ..cubicTo(24, 10, 40, 10, 40, 21)
        ..lineTo(40, 25),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(25, 37)
        ..lineTo(30, 42)
        ..lineTo(40, 32),
      stroke..color = const Color(0xFF196B58),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
