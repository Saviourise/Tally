import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../data/models/entry.dart';
import '../../../theme/tally_colors.dart';
import '../../../theme/tally_typography.dart';

class RecentStrip extends StatelessWidget {
  const RecentStrip({
    super.key,
    required this.entries,
    required this.fullDayMinutes,
    required this.onTapDay,
  });

  final List<Entry> entries;
  final int fullDayMinutes;
  final void Function(DateTime) onTapDay;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final byId = {for (final e in entries) e.id: e};
    final today = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day - (6 - i)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'LAST 7 DAYS',
            style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final d in days)
              Expanded(
                child: _DayCell(
                  date: d,
                  entry: byId[Entry.idForDate(d)],
                  fullDayMinutes: fullDayMinutes,
                  onTap: () => onTapDay(d),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.entry,
    required this.fullDayMinutes,
    required this.onTap,
  });
  final DateTime date;
  final Entry? entry;
  final int fullDayMinutes;
  final VoidCallback onTap;

  static const _wd = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final isToday = _isSameDay(date, DateTime.now());
    final fillPct = entry == null
        ? 0.0
        : (entry!.totalMinutes / fullDayMinutes).clamp(0.0, 1.0);
    final fullDay = entry != null && entry!.totalMinutes >= fullDayMinutes;
    final partial = entry != null && entry!.totalMinutes > 0 && !fullDay;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Text(
              _wd[date.weekday - 1],
              style: TallyType.label(ink.withValues(alpha: 0.5), size: 11),
            ),
            const SizedBox(height: 6),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: isToday
                    ? Border.all(color: TallyColors.honey, width: 1.5)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  if (fillPct > 0)
                    FractionallySizedBox(
                      heightFactor: fillPct,
                      child: Container(
                        decoration: BoxDecoration(
                          color: fullDay
                              ? TallyColors.honey
                              : TallyColors.honey.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  Center(
                    child: Text(
                      '${date.day}',
                      style: TallyType.title(
                        fullDay || partial ? TallyColors.ink : ink,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry == null ? '—' : formatHM(entry!.totalMinutes),
              style: TallyType.label(ink.withValues(alpha: 0.55), size: 10),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
