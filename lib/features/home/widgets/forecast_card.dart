import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme/tally_colors.dart';
import '../../../theme/tally_typography.dart';
import '../../../widgets/glass_card.dart';

class ForecastCard extends StatelessWidget {
  const ForecastCard({
    super.key,
    required this.projected,
    required this.workdaysRemaining,
    required this.confidence, // 0..1
  });

  final double projected;
  final int workdaysRemaining;
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: confidence.clamp(0.0, 1.0),
                  strokeWidth: 5,
                  backgroundColor: ink.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(TallyColors.honey),
                ),
                Icon(Icons.auto_graph_rounded, color: ink.withValues(alpha: 0.7), size: 20),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ON PACE FOR',
                  style: TallyType.label(ink.withValues(alpha: 0.6), size: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  formatMoney(projected),
                  style: TallyType.headline(ink, size: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  workdaysRemaining > 0
                      ? '$workdaysRemaining weekdays left this month'
                      : 'Month is closed — final number',
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
