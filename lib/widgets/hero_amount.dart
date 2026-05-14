import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../theme/tally_typography.dart';

/// Big editorial amount: e.g. £540.250 — integer in roman, decimals in italic
/// for character. Always uses 3-decimal money rounding (ceiling).
class HeroAmount extends StatelessWidget {
  const HeroAmount({
    super.key,
    required this.amount,
    this.size = 64,
    this.color,
    this.symbol = '£',
  });

  final double amount;
  final double size;
  final Color? color;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    final formatted = formatMoneyPlain(amount); // e.g. "540.250"
    final dot = formatted.indexOf('.');
    final whole = dot < 0 ? formatted : formatted.substring(0, dot);
    final dec = dot < 0 ? '' : formatted.substring(dot);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: size * 0.18),
          child: Text(symbol, style: TallyType.display(c, size: size * 0.55)),
        ),
        const SizedBox(width: 4),
        Text(whole, style: TallyType.display(c, size: size)),
        if (dec.isNotEmpty)
          Text(dec, style: TallyType.displayItalic(c, size: size * 0.6)),
      ],
    );
  }
}

class HeroHours extends StatelessWidget {
  const HeroHours({super.key, required this.totalMinutes, this.size = 56, this.color});

  final int totalMinutes;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return RichText(
      text: TextSpan(
        style: TallyType.display(c, size: size),
        children: [
          TextSpan(text: '$h'),
          TextSpan(text: 'h ', style: TallyType.displayItalic(c, size: size * 0.5)),
          TextSpan(text: m.toString().padLeft(2, '0')),
          TextSpan(text: 'm', style: TallyType.displayItalic(c, size: size * 0.5)),
        ],
      ),
    );
  }
}
