import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/formatters.dart';
import '../../core/pay_calc.dart';
import '../../data/models/entry.dart';
import '../../data/models/extra.dart';
import '../../theme/tally_colors.dart';
import '../../widgets/tally_logo.dart';

class InvoiceData {
  final String monthLabel;
  final int year;
  final List<Entry> entries;
  final List<Extra> extras;
  final double hourlyFullDayPay;
  final int fullDayHours;
  final String? displayName;

  InvoiceData({
    required this.monthLabel,
    required this.year,
    required this.entries,
    required this.extras,
    required this.hourlyFullDayPay,
    required this.fullDayHours,
    this.displayName,
  });
}

class InvoiceWidget extends StatelessWidget {
  const InvoiceWidget({super.key, required this.data});
  final InvoiceData data;

  static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final pays = data.entries
        .map((e) => PayCalc.payForEntry(
              entry: e,
              monthEntries: data.entries,
              hourlyFullDayPay: data.hourlyFullDayPay,
              fullDayHours: data.fullDayHours,
            ))
        .toList();
    final entriesTotal = pays.fold<double>(0, (a, b) => a + b);
    final extrasNet = data.extras.fold<double>(0, (a, e) => a + e.signedAmount);
    final total = entriesTotal + extrasNet;
    final totalMinutes =
        data.entries.fold<int>(0, (a, e) => a + e.totalMinutes);

    return Container(
      width: 720,
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
      color: TallyColors.cream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TallyLogo(size: 38, color: TallyColors.ink),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('STATEMENT',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: TallyColors.ink.withValues(alpha: 0.6),
                          fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    '${data.monthLabel} ${data.year}',
                    style: GoogleFonts.fraunces(
                      fontWeight: FontWeight.w600,
                      color: TallyColors.ink,
                      fontSize: 28,
                      height: 1.0,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: TallyColors.ink.withValues(alpha: 0.12)),
          const SizedBox(height: 20),
          if (data.displayName != null) ...[
            Text('FOR',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: TallyColors.ink.withValues(alpha: 0.6),
                    fontSize: 10)),
            const SizedBox(height: 4),
            Text(data.displayName!,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: TallyColors.ink,
                    fontSize: 16)),
            const SizedBox(height: 20),
          ],
          // Header row
          _row(
            day: 'DATE',
            label: 'HOURS',
            amount: 'PAY',
            bold: true,
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: TallyColors.ink.withValues(alpha: 0.12)),
          for (var i = 0; i < data.entries.length; i++) ...[
            _row(
              day:
                  '${_wd[data.entries[i].date.weekday - 1]} ${data.entries[i].date.day.toString().padLeft(2, '0')} ${data.monthLabel.substring(0, 3)}',
              label: formatHM(data.entries[i].totalMinutes),
              amount: formatMoney(pays[i]),
            ),
          ],
          const SizedBox(height: 10),
          Container(height: 1, color: TallyColors.ink.withValues(alpha: 0.12)),
          _row(
            day: 'Subtotal (${data.entries.length} days, ${formatHM(totalMinutes)})',
            label: '',
            amount: formatMoney(entriesTotal),
          ),
          if (data.extras.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('EXTRAS',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: TallyColors.ink.withValues(alpha: 0.6),
                    fontSize: 10)),
            const SizedBox(height: 6),
            for (final e in data.extras)
              _row(
                day: e.label,
                label: e.kind == ExtraKind.payment ? 'payment' : 'fee',
                amount:
                    '${e.kind == ExtraKind.payment ? '+' : '-'}${formatMoney(e.amount)}',
              ),
          ],
          const SizedBox(height: 16),
          Container(height: 2, color: TallyColors.ink),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('TOTAL',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: TallyColors.ink,
                      fontSize: 13)),
              const Spacer(),
              Text(
                formatMoney(total),
                style: GoogleFonts.fraunces(
                  fontWeight: FontWeight.w600,
                  color: TallyColors.ink,
                  fontSize: 34,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Generated with Tally on ${DateTime.now().toIso8601String().substring(0, 10)}.',
            style: GoogleFonts.dmSans(
              color: TallyColors.ink.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required String day,
    required String label,
    required String amount,
    bool bold = false,
  }) {
    final style = GoogleFonts.dmSans(
      color: TallyColors.ink.withValues(alpha: bold ? 0.6 : 0.9),
      fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
      fontSize: bold ? 11 : 14,
      letterSpacing: bold ? 1.5 : 0,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(day, style: style)),
          Expanded(
            flex: 2,
            child: Text(label, style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: bold
                  ? style
                  : GoogleFonts.fraunces(
                      color: TallyColors.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
