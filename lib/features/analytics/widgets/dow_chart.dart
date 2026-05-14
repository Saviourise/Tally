import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/models/entry.dart';
import '../../../theme/tally_colors.dart';
import '../../../theme/tally_typography.dart';
import '../../../widgets/glass_card.dart';

/// Average hours per weekday. Saturday + Sunday are merged into a single
/// "Weekend" bucket (index 5).
class DayOfWeekChart extends StatelessWidget {
  const DayOfWeekChart({super.key, required this.entries});
  final List<Entry> entries;

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Wknd'];

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;

    // 6 buckets: 0..4 = Mon..Fri, 5 = Weekend (Sat + Sun combined).
    final sums = List<int>.filled(6, 0);
    final counts = List<int>.filled(6, 0);
    for (final e in entries) {
      if (e.totalMinutes <= 0) continue;
      final i = e.date.weekday <= 5 ? e.date.weekday - 1 : 5;
      sums[i] += e.totalMinutes;
      counts[i] += 1;
    }
    final avgs = List<double>.generate(
      6,
      (i) => counts[i] == 0 ? 0 : sums[i] / counts[i] / 60.0,
    );
    final maxY = (avgs.fold<double>(0, (a, b) => b > a ? b : a)).clamp(2, 12) + 1;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AVG HOURS BY WEEKDAY',
              style: TallyType.label(ink.withValues(alpha: 0.55), size: 11)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i > 5) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _labels[i],
                            style: TallyType.label(
                                ink.withValues(alpha: 0.6), size: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                maxY: maxY.toDouble(),
                barGroups: [
                  for (var i = 0; i < 6; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: avgs[i],
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                        color: i < 5
                            ? TallyColors.honey
                            : TallyColors.honey.withValues(alpha: 0.5),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
