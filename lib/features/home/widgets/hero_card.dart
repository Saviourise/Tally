import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme/tally_colors.dart';
import '../../../theme/tally_typography.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/hero_amount.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.monthLabel,
    required this.earned,
    required this.totalMinutes,
    required this.daysLogged,
    required this.deltaVsLastMonth,
  });

  final String monthLabel;
  final double earned;
  final int totalMinutes;
  final int daysLogged;
  final double? deltaVsLastMonth; // percentage, can be null on first month

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = ink.withValues(alpha: 0.55);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      radius: 32,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      color: dark
          ? TallyColors.honey.withValues(alpha: 0.18)
          : TallyColors.honey.withValues(alpha: 0.35),
      borderColor: TallyColors.honey.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(monthLabel.toUpperCase(),
                  style: TallyType.label(muted, size: 11)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$daysLogged days',
                  style: TallyType.label(ink, size: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          HeroAmount(amount: earned, size: 64),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${formatHM(totalMinutes)} worked',
                style: TallyType.body(ink.withValues(alpha: 0.7), size: 14),
              ),
              if (deltaVsLastMonth != null) ...[
                const SizedBox(width: 10),
                _DeltaPill(value: deltaVsLastMonth!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    final color = positive ? const Color(0xFF1F8A4C) : const Color(0xFFB04A2F);
    final sign = positive ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            '$sign${value.toStringAsFixed(0)}% vs last month',
            style: TallyType.label(color, size: 10),
          ),
        ],
      ),
    );
  }
}
