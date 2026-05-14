import 'package:flutter/material.dart';

import '../../../theme/tally_typography.dart';
import '../../../widgets/glass_card.dart';

class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final now = DateTime.now();
    final canForward = !(month.year == now.year && month.month == now.month);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: ink,
            onPressed: onPrev,
          ),
          Expanded(
            child: Center(
              child: Text(label, style: TallyType.title(ink, size: 16)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: canForward ? ink : ink.withValues(alpha: 0.25),
            onPressed: canForward ? onNext : null,
          ),
        ],
      ),
    );
  }
}
