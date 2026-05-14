import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/pay_calc.dart';
import '../../../data/models/entry.dart';
import '../../../theme/tally_colors.dart';
import '../../../theme/tally_typography.dart';
import '../../../widgets/glass_card.dart';

class TodayCard extends StatelessWidget {
  const TodayCard({
    super.key,
    required this.entry,
    required this.monthEntries,
    required this.hourlyFullDayPay,
    required this.fullDayHours,
    required this.onTap,
  });

  final Entry? entry;
  final List<Entry> monthEntries;
  final double hourlyFullDayPay;
  final int fullDayHours;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final hasEntry = entry != null;
    final mins = entry?.totalMinutes ?? 0;
    final pay = entry == null
        ? 0.0
        : PayCalc.payForEntry(
            entry: entry!,
            monthEntries: monthEntries,
            hourlyFullDayPay: hourlyFullDayPay,
            fullDayHours: fullDayHours,
          );
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasEntry
                  ? TallyColors.honey
                  : ink.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasEntry ? Icons.check_rounded : Icons.add_rounded,
              color: hasEntry ? TallyColors.ink : ink,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasEntry ? 'Today logged' : 'Log today',
                  style: TallyType.title(ink, size: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  hasEntry
                      ? '${formatHM(mins)} · ${formatMoney(pay)}'
                      : 'Tap to add hours and minutes',
                  style: TallyType.body(ink.withValues(alpha: 0.6), size: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: ink.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}
