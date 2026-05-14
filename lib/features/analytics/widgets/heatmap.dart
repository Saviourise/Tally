import 'package:flutter/material.dart';

import '../../../data/models/entry.dart';
import '../../../theme/tally_colors.dart';
import '../../../theme/tally_typography.dart';

/// Year heatmap (GitHub-style) in honey tones.
/// Saturday and Sunday are merged into a single "Weekend" row.
class Heatmap extends StatelessWidget {
  const Heatmap({
    super.key,
    required this.entries,
    required this.fullDayMinutes,
  });
  final List<Entry> entries;
  final int fullDayMinutes;

  static const double _cell = 13;
  static const double _gap = 3;
  static const _rows = 6; // Mon, Tue, Wed, Thu, Fri, Weekend
  static const _rowLabels = ['', 'Tue', '', 'Thu', '', 'Wknd'];

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final byId = {
      for (final e in entries) Entry.idForDate(e.date): e.totalMinutes,
    };

    // Build a 52-week grid ending on the current week.
    final today = DateTime.now();
    final endDay = DateTime(today.year, today.month, today.day);
    // Monday of this week
    final mondayOfThisWeek =
        endDay.subtract(Duration(days: endDay.weekday - 1));
    // 52 weeks total: go back 51 more from Monday-of-this-week
    final start = mondayOfThisWeek.subtract(const Duration(days: 51 * 7));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONSISTENCY HEATMAP',
          style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
        ),
        const SizedBox(height: 12),
        // Scrollable horizontally so the grid never overflows.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // start scrolled to "now" on the right
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row labels gutter
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var r = 0; r < _rows; r++)
                      Padding(
                        padding: EdgeInsets.only(bottom: _gap),
                        child: SizedBox(
                          height: _cell,
                          child: Text(
                            _rowLabels[r],
                            style: TallyType.label(
                              ink.withValues(alpha: 0.45),
                              size: 9,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Week columns
              for (var w = 0; w < 52; w++)
                Padding(
                  padding: EdgeInsets.only(right: _gap),
                  child: Column(
                    children: [for (var r = 0; r < _rows; r++) _cellFor(start, w, r, byId, ink)],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('less',
                style: TallyType.label(ink.withValues(alpha: 0.5), size: 10)),
            const SizedBox(width: 6),
            for (final p in [0.0, 0.25, 0.5, 0.75, 1.0])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _colorForLevel(p, ink),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Text('more',
                style: TallyType.label(ink.withValues(alpha: 0.5), size: 10)),
          ],
        ),
      ],
    );
  }

  Widget _cellFor(
    DateTime start,
    int week,
    int row,
    Map<String, int> byId,
    Color ink,
  ) {
    int mins;
    bool inFuture;
    final now = DateTime.now();
    if (row < 5) {
      // Mon..Fri — single day
      final day = start.add(Duration(days: week * 7 + row));
      mins = byId[Entry.idForDate(day)] ?? 0;
      inFuture = day.isAfter(DateTime(now.year, now.month, now.day));
    } else {
      // Weekend row — sum Sat + Sun
      final sat = start.add(Duration(days: week * 7 + 5));
      final sun = start.add(Duration(days: week * 7 + 6));
      mins = (byId[Entry.idForDate(sat)] ?? 0) + (byId[Entry.idForDate(sun)] ?? 0);
      inFuture = sat.isAfter(DateTime(now.year, now.month, now.day));
    }
    final level = (mins / fullDayMinutes).clamp(0.0, 1.0);
    return Padding(
      padding: EdgeInsets.only(bottom: _gap),
      child: Container(
        width: _cell,
        height: _cell,
        decoration: BoxDecoration(
          color: inFuture ? ink.withValues(alpha: 0.02) : _colorForLevel(level, ink),
          borderRadius: BorderRadius.circular(_cell * 0.22),
        ),
      ),
    );
  }

  Color _colorForLevel(double level, Color ink) {
    if (level <= 0) return ink.withValues(alpha: 0.06);
    if (level < 0.3) return TallyColors.honey.withValues(alpha: 0.25);
    if (level < 0.6) return TallyColors.honey.withValues(alpha: 0.5);
    if (level < 0.9) return TallyColors.honey.withValues(alpha: 0.8);
    return TallyColors.honey;
  }
}
