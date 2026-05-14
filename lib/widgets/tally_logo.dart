import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/tally_colors.dart';

/// Wordmark with tally-marks accent.
class TallyLogo extends StatelessWidget {
  const TallyLogo({super.key, this.size = 44, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'tally',
          style: GoogleFonts.bricolageGrotesque(
            color: c,
            fontSize: size,
            fontWeight: FontWeight.w800,
            letterSpacing: -2.2,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: size * 0.55,
          child: CustomPaint(
            painter: _TallyMarksPainter(color: TallyColors.honey),
            size: Size(size * 0.4, size * 0.55),
          ),
        ),
      ],
    );
  }
}

class _TallyMarksPainter extends CustomPainter {
  _TallyMarksPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final step = size.width / 5;
    for (var i = 0; i < 4; i++) {
      final x = step * (i + 0.5);
      canvas.drawLine(
        Offset(x, size.height * 0.1),
        Offset(x, size.height * 0.9),
        paint,
      );
    }
    canvas.drawLine(
      Offset(step * 0.2, size.height * 0.85),
      Offset(size.width - step * 0.2, size.height * 0.15),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TallyMarksPainter old) => old.color != color;
}
