import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../data/models/entry.dart';
import '../../theme/tally_typography.dart';
import '../../widgets/tally_logo.dart';
import '../analytics/analytics_logic.dart';
import '../entry/log_entry_sheet.dart';
import 'widgets/forecast_card.dart';
import 'widgets/hero_card.dart';
import 'widgets/insights_ribbon.dart';
import 'widgets/month_calendar.dart';
import 'widgets/today_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const monthLabels = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final monthEntries = ref.watch(monthEntriesProvider).value ?? const [];
    final extras = ref.watch(monthExtrasProvider).value ?? const [];
    final todayEntry = ref.watch(todayEntryProvider).value;
    final selectedMonth = ref.watch(selectedMonthProvider);
    final user = ref.watch(authStateProvider).value;
    final ink = Theme.of(context).colorScheme.onSurface;

    final summary = summarize(
      monthEntries,
      hourlyFullDayPay: settings.hourlyFullDayPay,
      fullDayHours: settings.fullDayHours,
    );
    final extrasNet = extras.fold<double>(0, (a, e) => a + e.signedAmount);
    final monthTotal = summary.entriesPay + extrasNet;

    final forecast = projectMonthly(
      monthEntries: monthEntries,
      month: selectedMonth,
      hourlyFullDayPay: settings.hourlyFullDayPay,
      fullDayHours: settings.fullDayHours,
    );

    final patterns = computeWeekdayPatterns(
      monthEntries,
      fullDayMinutes: settings.fullDayHours * 60,
    );

    final greeting = _greeting();
    final monthLabel = '${monthLabels[selectedMonth.month - 1]} ${selectedMonth.year}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: TallyType.label(ink.withValues(alpha: 0.55), size: 12)),
                const SizedBox(height: 2),
                Text(
                  user?.displayName?.split(' ').first ?? 'there',
                  style: TallyType.headline(ink, size: 22),
                ),
              ],
            ),
            const Spacer(),
            TallyLogo(size: 26, color: ink),
          ],
        ),
        const SizedBox(height: 20),
        HeroCard(
          monthLabel: monthLabel,
          earned: monthTotal,
          totalMinutes: summary.totalMinutes,
          daysLogged: summary.daysLogged,
          deltaVsLastMonth: null,
        ),
        const SizedBox(height: 14),
        TodayCard(
          entry: todayEntry,
          monthEntries: monthEntries,
          hourlyFullDayPay: settings.hourlyFullDayPay,
          fullDayHours: settings.fullDayHours,
          onTap: () => LogEntrySheet.show(
            context,
            date: DateTime.now(),
            existing: todayEntry,
          ),
        ),
        const SizedBox(height: 14),
        ForecastCard(
          projected: forecast.projection,
          workdaysRemaining: forecast.weekdaysRemaining,
          confidence: forecast.confidence,
        ),
        const SizedBox(height: 22),
        MonthCalendar(
          month: selectedMonth,
          entries: monthEntries,
          hourlyFullDayPay: settings.hourlyFullDayPay,
          fullDayHours: settings.fullDayHours,
          onTapDay: (d) {
            final existing = monthEntries.firstWhereOrNull(
              (e) => e.id == Entry.idForDate(d),
            );
            LogEntrySheet.show(context, date: d, existing: existing);
          },
        ),
        const SizedBox(height: 22),
        Text(
          'INSIGHTS',
          style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
        ),
        const SizedBox(height: 10),
        InsightsRibbon(insights: [
          (
            icon: Icons.workspace_premium_rounded,
            label: 'Best weekday this month',
            value: weekdayNames[patterns.bestBucket],
          ),
          (
            icon: Icons.timelapse_rounded,
            label: 'avg on your best day',
            value: '${patterns.bestAvgHours.toStringAsFixed(1)}h',
          ),
          (
            icon: Icons.percent_rounded,
            label: 'weekdays at full-day rate',
            value: '${(patterns.fullDayHitRate * 100).toStringAsFixed(0)}%',
          ),
          (
            icon: Icons.summarize_rounded,
            label: 'extras this month',
            value: formatMoney(extrasNet),
          ),
        ]),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Working late';
  }
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E e) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
