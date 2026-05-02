import 'package:flutter/material.dart';

class TeamFlowLogo extends StatelessWidget {
  final double size;
  final Color bubbleColor;
  final Color peopleColor;

  const TeamFlowLogo({
    super.key,
    this.size = 80,
    this.bubbleColor = const Color(0xFF2196F3),
    this.peopleColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TeamFlowLogoPainter(
        bubbleColor: bubbleColor,
        peopleColor: peopleColor,
      ),
    );
  }
}

class _TeamFlowLogoPainter extends CustomPainter {
  final Color bubbleColor;
  final Color peopleColor;

  _TeamFlowLogoPainter({required this.bubbleColor, required this.peopleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.1, size.width * 0.8, size.height * 0.8),
      Radius.circular(size.width * 0.12),
    );

    final bubblePaint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rect, bubblePaint);

    final linePaint = Paint()
      ..color = peopleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = peopleColor
      ..style = PaintingStyle.fill;

    final headRadius = size.width * 0.045;
    final bodyLength = size.width * 0.09;
    final armLength = size.width * 0.06;

    void drawPerson(double x, double y, double rotation) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      canvas.drawCircle(Offset(0, -bodyLength - headRadius), headRadius, fillPaint);

      canvas.drawLine(
        Offset(0, -bodyLength + headRadius * 0.5),
        Offset(0, 0),
        linePaint,
      );

      canvas.drawLine(
        Offset(0, -bodyLength * 0.6),
        Offset(-armLength, -bodyLength * 0.6 + armLength * 0.3),
        linePaint,
      );

      canvas.drawLine(
        Offset(0, -bodyLength * 0.6),
        Offset(armLength, -bodyLength * 0.6 + armLength * 0.3),
        linePaint,
      );

      canvas.restore();
    }

    drawPerson(size.width * 0.35, size.height * 0.38, 0);
    drawPerson(size.width * 0.65, size.height * 0.38, 0);
    drawPerson(size.width * 0.5, size.height * 0.68, 0);

    final connectionPaint = Paint()
      ..color = peopleColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.35, size.height * 0.38);
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.28,
      size.width * 0.65, size.height * 0.38,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.53,
      size.width * 0.5, size.height * 0.68,
    );
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.53,
      size.width * 0.35, size.height * 0.38,
    );
    canvas.drawPath(path, connectionPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}