import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../data/models/entry.dart';
import '../../../theme/tally_colors.dart';
import '../../../theme/tally_typography.dart';

/// Full month grid. Sat + Sun are merged into a single "S/S" column.
/// Visual style mirrors the original RecentStrip cells.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.entries,
    required this.hourlyFullDayPay,
    required this.fullDayHours,
    required this.onTapDay,
  });

  final DateTime month;
  final List<Entry> entries;
  final double hourlyFullDayPay;
  final int fullDayHours;
  final void Function(DateTime day) onTapDay;

  static const _headers = ['M', 'T', 'W', 'T', 'F', 'S/S'];

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final fullDayMinutes = fullDayHours * 60;
    final today = DateTime.now();

    // Map of day-of-month -> entry minutes
    final byDay = <int, int>{};
    for (final e in entries) {
      if (e.date.year == month.year && e.date.month == month.month) {
        byDay[e.date.day] = (byDay[e.date.day] ?? 0) + e.totalMinutes;
      }
    }

    // Build weeks: Monday of week containing day 1 → Sunday of week containing
    // last day of month. Each week renders as 6 cells (Mon..Fri + Weekend).
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstMonday = firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1));
    final lastSunday = lastOfMonth.add(Duration(days: 7 - lastOfMonth.weekday));
    final totalWeeks = (lastSunday.difference(firstMonday).inDays + 1) ~/ 7;

    final daysLogged = byDay.values.where((m) => m > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _monthTitle(month).toUpperCase(),
              style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
            ),
            const Spacer(),
            Text(
              '$daysLogged day${daysLogged == 1 ? '' : 's'} logged',
              style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Header row
        Row(
          children: [
            for (final h in _headers)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Center(
                    child: Text(
                      h,
                      style: TallyType.label(
                        ink.withValues(alpha: 0.5),
                        size: 10,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var w = 0; w < totalWeeks; w++) ...[
          _weekRow(
            context: context,
            ink: ink,
            weekStart: firstMonday.add(Duration(days: w * 7)),
            byDay: byDay,
            today: today,
            fullDayMinutes: fullDayMinutes,
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _weekRow({
    required BuildContext context,
    required Color ink,
    required DateTime weekStart,
    required Map<int, int> byDay,
    required DateTime today,
    required int fullDayMinutes,
  }) {
    final cells = <Widget>[];

    // Mon..Fri (5 cells)
    for (var i = 0; i < 5; i++) {
      final d = weekStart.add(Duration(days: i));
      final inMonth = d.year == month.year && d.month == month.month;
      cells.add(Expanded(
        child: inMonth
            ? _DayCell(
                date: d,
                minutes: byDay[d.day] ?? 0,
                today: today,
                fullDayMinutes: fullDayMinutes,
                onTap: () => onTapDay(d),
              )
            : const _DayCell.placeholder(),
      ));
    }
    // Weekend (Sat + Sun merged)
    final sat = weekStart.add(const Duration(days: 5));
    final sun = weekStart.add(const Duration(days: 6));
    final satIn = sat.year == month.year && sat.month == month.month;
    final sunIn = sun.year == month.year && sun.month == month.month;
    if (!satIn && !sunIn) {
      cells.add(const Expanded(child: _DayCell.placeholder()));
    } else {
      final satMins = satIn ? (byDay[sat.day] ?? 0) : 0;
      final sunMins = sunIn ? (byDay[sun.day] ?? 0) : 0;
      cells.add(Expanded(
        child: _WeekendCell(
          satDate: satIn ? sat : null,
          sunDate: sunIn ? sun : null,
          satMinutes: satMins,
          sunMinutes: sunMins,
          today: today,
          fullDayMinutes: fullDayMinutes,
          onTap: () {
            // Prefer Sunday if it has minutes, else Saturday, else Sunday
            if (sunIn && sunMins > 0) {
              onTapDay(sun);
            } else if (satIn) {
              onTapDay(sat);
            } else if (sunIn) {
              onTapDay(sun);
            }
          },
        ),
      ));
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells);
  }

  String _monthTitle(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.minutes,
    required this.today,
    required this.fullDayMinutes,
    required this.onTap,
  }) : _isPlaceholder = false;

  const _DayCell.placeholder()
      : date = null,
        minutes = 0,
        today = null,
        fullDayMinutes = 0,
        onTap = null,
        _isPlaceholder = true;

  final DateTime? date;
  final int minutes;
  final DateTime? today;
  final int fullDayMinutes;
  final VoidCallback? onTap;
  final bool _isPlaceholder;

  @override
  Widget build(BuildContext context) {
    if (_isPlaceholder) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(height: 58),
      );
    }
    final ink = Theme.of(context).colorScheme.onSurface;
    final isToday = date!.year == today!.year &&
        date!.month == today!.month &&
        date!.day == today!.day;
    final fillPct = (minutes / fullDayMinutes).clamp(0.0, 1.0);
    final fullDay = minutes >= fullDayMinutes;
    final partial = minutes > 0 && !fullDay;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
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
                      '${date!.day}',
                      style: TallyType.title(
                        fullDay || partial ? Colors.white : ink,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              minutes > 0 ? formatHM(minutes) : '—',
              style: TallyType.label(ink.withValues(alpha: 0.55), size: 9),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekendCell extends StatelessWidget {
  const _WeekendCell({
    required this.satDate,
    required this.sunDate,
    required this.satMinutes,
    required this.sunMinutes,
    required this.today,
    required this.fullDayMinutes,
    required this.onTap,
  });

  final DateTime? satDate;
  final DateTime? sunDate;
  final int satMinutes;
  final int sunMinutes;
  final DateTime today;
  final int fullDayMinutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final totalMins = satMinutes + sunMinutes;
    // Weekend is treated as ONE day for pay/threshold.
    final fillPct = (totalMins / fullDayMinutes).clamp(0.0, 1.0);
    final fullDay = totalMins >= fullDayMinutes;
    final partial = totalMins > 0 && !fullDay;
    final isToday = (satDate != null &&
            satDate!.year == today.year &&
            satDate!.month == today.month &&
            satDate!.day == today.day) ||
        (sunDate != null &&
            sunDate!.year == today.year &&
            sunDate!.month == today.month &&
            sunDate!.day == today.day);

    final label = _label();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
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
                      label,
                      style: TallyType.title(
                        fullDay || partial ? Colors.white : ink,
                        size: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              totalMins > 0 ? formatHM(totalMins) : '—',
              style: TallyType.label(ink.withValues(alpha: 0.55), size: 9),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ],
        ),
      ),
    );
  }

  String _label() {
    final sat = satDate?.day;
    final sun = sunDate?.day;
    if (sat != null && sun != null) return '$sat/$sun';
    return '${sat ?? sun ?? ""}';
  }
}
