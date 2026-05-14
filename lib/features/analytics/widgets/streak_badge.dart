import 'package:flutter/material.dart';

import '../../../theme/tally_colors.dart';
import '../../../theme/tally_typography.dart';
import '../../../widgets/glass_card.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.current, required this.best});
  final int current;
  final int best;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return GlassCard(
      color: TallyColors.honey.withValues(alpha: 0.25),
      borderColor: TallyColors.honey.withValues(alpha: 0.45),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CustomPaint(painter: _FlamePainter(color: TallyColors.copper)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STREAK',
                    style: TallyType.label(ink.withValues(alpha: 0.6), size: 11)),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: TallyType.headline(ink, size: 30),
                    children: [
                      TextSpan(text: '$current'),
                      TextSpan(
                        text: current == 1 ? ' day' : ' days',
                        style: TallyType.body(ink.withValues(alpha: 0.7), size: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Best this year: $best',
                  style: TallyType.body(ink.withValues(alpha: 0.6), size: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..cubicTo(w * 0.85, h * 0.30, w * 0.85, h * 0.55, w * 0.65, h * 0.50)
      ..cubicTo(w * 0.78, h * 0.78, w * 0.62, h * 0.95, w * 0.5, h * 0.95)
      ..cubicTo(w * 0.18, h * 0.95, w * 0.10, h * 0.55, w * 0.36, h * 0.42)
      ..cubicTo(w * 0.42, h * 0.55, w * 0.50, h * 0.55, w * 0.55, h * 0.30)
      ..cubicTo(w * 0.46, h * 0.22, w * 0.46, h * 0.12, w * 0.5, h * 0.05)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.40)
        ..cubicTo(w * 0.62, h * 0.55, w * 0.62, h * 0.78, w * 0.5, h * 0.85)
        ..cubicTo(w * 0.38, h * 0.78, w * 0.38, h * 0.55, w * 0.5, h * 0.40),
      Paint()..color = TallyColors.honey,
    );
  }

  @override
  bool shouldRepaint(covariant _FlamePainter old) => false;
}
