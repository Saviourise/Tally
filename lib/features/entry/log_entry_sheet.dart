import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/pay_calc.dart';
import '../../core/providers.dart';
import '../../data/models/entry.dart';
import '../../theme/tally_colors.dart';
import '../../theme/tally_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/honey_button.dart';

class LogEntrySheet extends ConsumerStatefulWidget {
  const LogEntrySheet({super.key, this.date, this.existing});

  final DateTime? date;
  final Entry? existing;

  static Future<void> show(BuildContext context, {DateTime? date, Entry? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogEntrySheet(date: date, existing: existing),
    );
  }

  @override
  ConsumerState<LogEntrySheet> createState() => _LogEntrySheetState();
}

class _LogEntrySheetState extends ConsumerState<LogEntrySheet> {
  late int _hours;
  late int _minutes;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.date ?? widget.date ?? DateTime.now();
    _hours = widget.existing?.hours ?? 8;
    _minutes = widget.existing?.minutes ?? 0;
  }

  void _save() {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    // Fire-and-forget: the local Firestore cache updates synchronously and
    // streaming listeners reflect the change immediately. Server ack happens
    // in the background — don't block the UI on it.
    unawaited(ref.read(entryRepoProvider).upsert(
          uid,
          date: _date,
          hours: _hours,
          minutes: _minutes,
          source: 'manual',
        ));
    Navigator.of(context).pop();
  }

  void _delete() {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    unawaited(ref.read(entryRepoProvider).delete(uid, _date));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final monthEntries = ref.watch(monthEntriesProvider).value ?? const [];
    final ink = Theme.of(context).colorScheme.onSurface;
    final total = _hours * 60 + _minutes;
    final pay = PayCalc.previewPay(
      date: _date,
      totalMinutes: total,
      monthEntries: monthEntries,
      hourlyFullDayPay: settings.hourlyFullDayPay,
      fullDayHours: settings.fullDayHours,
    );
    final isFullDay = PayCalc.qualifiesAsFullDay(
      date: _date,
      totalMinutes: total,
      monthEntries: monthEntries,
      fullDayHours: settings.fullDayHours,
    );
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GlassCard(
        radius: 32,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Log hours', style: TallyType.headline(ink, size: 26)),
                const Spacer(),
                _DatePill(date: _date, onPick: (d) => setState(() => _date = d)),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                height: 170,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _wheel(
                      max: 24,
                      value: _hours,
                      onChanged: (v) => setState(() => _hours = v),
                      suffix: 'h',
                    ),
                    const SizedBox(width: 12),
                    _wheel(
                      max: 60,
                      step: 5,
                      value: _minutes - (_minutes % 5),
                      onChanged: (v) => setState(() => _minutes = v),
                      suffix: 'm',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TallyColors.honey.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TallyColors.honey.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_money_rounded, color: ink.withValues(alpha: 0.7), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    total <= 0
                        ? 'No pay'
                        : isFullDay
                            ? 'Full-day rate'
                            : 'Half-day rate',
                    style: TallyType.label(ink, size: 12),
                  ),
                  const Spacer(),
                  Text(formatMoney(pay), style: TallyType.title(ink, size: 18)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.existing != null) ...[
                  IconButton(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: ink.withValues(alpha: 0.06),
                      foregroundColor: ink.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: HoneyButton(
                    label: 'Save',
                    expanded: true,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _wheel({
    required int max,
    required int value,
    required ValueChanged<int> onChanged,
    int step = 1,
    String suffix = '',
  }) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final items = [for (var i = 0; i < max; i += step) i];
    final controller = FixedExtentScrollController(initialItem: items.indexOf(value).clamp(0, items.length - 1));
    return SizedBox(
      width: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: ink.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          CupertinoPicker(
            scrollController: controller,
            itemExtent: 44,
            useMagnifier: true,
            magnification: 1.05,
            squeeze: 1.1,
            backgroundColor: Colors.transparent,
            onSelectedItemChanged: (i) => onChanged(items[i]),
            children: [
              for (final v in items)
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TallyType.display(ink, size: 28),
                      children: [
                        TextSpan(text: '$v'),
                        TextSpan(
                          text: suffix,
                          style: TallyType.body(ink.withValues(alpha: 0.5), size: 14),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.date, required this.onPick});
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  String _label() {
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    if (isToday) return 'Today';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return GlassPillButton(
      label: _label(),
      icon: Icons.calendar_today_rounded,
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
    );
  }
}
