import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme/tally_colors.dart';
import '../../theme/tally_typography.dart';
import '../../widgets/glass_card.dart';
import 'analytics_logic.dart';
import 'widgets/dow_chart.dart';
import 'widgets/heatmap.dart';
import 'widgets/streak_badge.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final year = ref.watch(yearEntriesProvider).value ?? const [];
    final month = ref.watch(monthEntriesProvider).value ?? const [];
    final ink = Theme.of(context).colorScheme.onSurface;

    final streaks = computeStreaks(year);
    final summary = summarize(year,
        hourlyFullDayPay: settings.hourlyFullDayPay,
        fullDayHours: settings.fullDayHours);
    final patterns = computeWeekdayPatterns(month,
        fullDayMinutes: settings.fullDayHours * 60);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        const SizedBox(height: 8),
        Text('Analytics', style: TallyType.headline(ink, size: 28)),
        const SizedBox(height: 18),
        StreakBadge(current: streaks.currentStreak, best: streaks.bestStreak),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Heatmap(
            entries: year,
            fullDayMinutes: settings.fullDayHours * 60,
          ),
        ),
        const SizedBox(height: 16),
        DayOfWeekChart(entries: month),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THIS YEAR',
                  style: TallyType.label(ink.withValues(alpha: 0.55), size: 11)),
              const SizedBox(height: 8),
              _row(ink, 'Total hours', formatHM(summary.totalMinutes)),
              _row(ink, 'Days logged', '${summary.daysLogged}'),
              _row(ink, 'Full days', '${summary.fullDays}'),
              _row(ink, 'Partial days', '${summary.partialDays}'),
              const Divider(height: 24),
              _row(
                ink,
                'Best weekday',
                weekdayNames[patterns.bestBucket],
                emphasis: true,
              ),
              _row(
                ink,
                'Full-day hit rate (weekdays)',
                '${(patterns.fullDayHitRate * 100).toStringAsFixed(0)}%',
                emphasis: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(Color ink, String label, String value, {bool emphasis = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TallyType.body(ink.withValues(alpha: 0.7), size: 13)),
          ),
          Text(
            value,
            style: emphasis
                ? TallyType.title(TallyColors.copper, size: 15)
                : TallyType.title(ink, size: 14),
          ),
        ],
      ),
    );
  }
}
