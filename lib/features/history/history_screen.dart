import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/pay_calc.dart';
import '../../core/providers.dart';
import '../../data/models/entry.dart';
import '../../theme/tally_colors.dart';
import '../../theme/tally_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_amount.dart';
import '../analytics/analytics_logic.dart';
import '../entry/log_entry_sheet.dart';
import '../export/export_screen.dart';
import 'widgets/extras_section.dart';
import 'widgets/month_switcher.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const monthLabels = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final month = ref.watch(selectedMonthProvider);
    final entries = ref.watch(monthEntriesProvider).value ?? const [];
    final extras = ref.watch(monthExtrasProvider).value ?? const [];
    final ink = Theme.of(context).colorScheme.onSurface;

    final summary = summarize(
      entries,
      hourlyFullDayPay: settings.hourlyFullDayPay,
      fullDayHours: settings.fullDayHours,
    );
    final extrasNet = extras.fold<double>(0, (a, e) => a + e.signedAmount);
    final monthTotal = summary.entriesPay + extrasNet;
    final monthLabel = '${monthLabels[month.month - 1]} ${month.year}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text('History', style: TallyType.headline(ink, size: 28)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExportScreen()),
              ),
              style: IconButton.styleFrom(
                backgroundColor: TallyColors.honey,
                foregroundColor: TallyColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        MonthSwitcher(
          month: month,
          label: monthLabel,
          onPrev: () => ref.read(selectedMonthProvider.notifier).state =
              DateTime(month.year, month.month - 1, 1),
          onNext: () => ref.read(selectedMonthProvider.notifier).state =
              DateTime(month.year, month.month + 1, 1),
          // note: setter on Notifier subclass; works under riverpod 3
        ),
        const SizedBox(height: 16),
        GlassCard(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MONTH TOTAL',
                  style: TallyType.label(ink.withValues(alpha: 0.55), size: 11)),
              const SizedBox(height: 6),
              HeroAmount(amount: monthTotal, size: 52),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MiniStat(
                      label: 'Hours', value: formatHM(summary.totalMinutes)),
                  const SizedBox(width: 16),
                  _MiniStat(label: 'Full days', value: '${summary.fullDays}'),
                  const SizedBox(width: 16),
                  _MiniStat(
                      label: 'Partial', value: '${summary.partialDays}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ExtrasSection(extras: extras),
        const SizedBox(height: 16),
        Text(
          'DAILY LOG',
          style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          _EmptyDays()
        else
          ...entries.map((e) => _DayRow(
                entry: e,
                pay: PayCalc.payForEntry(
                  entry: e,
                  monthEntries: entries,
                  hourlyFullDayPay: settings.hourlyFullDayPay,
                  fullDayHours: settings.fullDayHours,
                ),
                isFullDay: PayCalc.qualifiesAsFullDay(
                  date: e.date,
                  totalMinutes: e.totalMinutes,
                  monthEntries: entries,
                  fullDayHours: settings.fullDayHours,
                ),
                onTap: () => LogEntrySheet.show(context, date: e.date, existing: e),
              )),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TallyType.label(ink.withValues(alpha: 0.5), size: 10)),
        const SizedBox(height: 2),
        Text(value, style: TallyType.title(ink, size: 15)),
      ],
    );
  }
}

class _EmptyDays extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded,
                size: 36, color: ink.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              'No entries this month yet.',
              style: TallyType.body(ink.withValues(alpha: 0.6), size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.entry,
    required this.pay,
    required this.isFullDay,
    required this.onTap,
  });
  final Entry entry;
  final double pay;
  final bool isFullDay;
  final VoidCallback onTap;

  static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final fullDay = isFullDay;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: fullDay
                    ? TallyColors.honey.withValues(alpha: 0.9)
                    : TallyColors.honey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '${entry.date.day}',
                  style: TallyType.title(TallyColors.ink, size: 16),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_wd[entry.date.weekday - 1],
                      style: TallyType.title(ink, size: 14)),
                  Text(formatHM(entry.totalMinutes),
                      style: TallyType.body(ink.withValues(alpha: 0.6), size: 12)),
                ],
              ),
            ),
            Text(formatMoney(pay),
                style: TallyType.title(ink, size: 16)),
          ],
        ),
      ),
    );
  }
}
