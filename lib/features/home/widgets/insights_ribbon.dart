import 'package:flutter/material.dart';

import '../../../theme/tally_colors.dart';
import '../../../theme/tally_typography.dart';
import '../../../widgets/glass_card.dart';

class InsightsRibbon extends StatelessWidget {
  const InsightsRibbon({super.key, required this.insights});
  final List<({IconData icon, String label, String value})> insights;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: insights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final ins = insights[i];
          return SizedBox(
            width: 180,
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(ins.icon, color: TallyColors.honey, size: 18),
                  Text(
                    ins.value,
                    style: TallyType.headline(ink, size: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ins.label,
                    style: TallyType.label(ink.withValues(alpha: 0.6), size: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
