import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/providers.dart';
import '../../../data/models/extra.dart';
import '../../../theme/tally_colors.dart';
import '../../../theme/tally_typography.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/honey_button.dart';

class ExtrasSection extends ConsumerWidget {
  const ExtrasSection({super.key, required this.extras});
  final List<Extra> extras;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'EXTRAS',
              style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddSheet(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Add', style: TallyType.label(ink, size: 12)),
              style: TextButton.styleFrom(foregroundColor: ink),
            ),
          ],
        ),
        if (extras.isEmpty)
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              'No fees or extra payments this month.',
              style: TallyType.body(ink.withValues(alpha: 0.6), size: 13),
            ),
          )
        else
          ...extras.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (e.kind == ExtraKind.payment
                                  ? const Color(0xFF1F8A4C)
                                  : const Color(0xFFB04A2F))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          e.kind == ExtraKind.payment
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: e.kind == ExtraKind.payment
                              ? const Color(0xFF1F8A4C)
                              : const Color(0xFFB04A2F),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(e.label, style: TallyType.title(ink, size: 14)),
                      ),
                      Text(
                        '${e.kind == ExtraKind.payment ? '+' : '-'}${formatMoney(e.amount)}',
                        style: TallyType.title(
                          e.kind == ExtraKind.payment
                              ? const Color(0xFF1F8A4C)
                              : const Color(0xFFB04A2F),
                          size: 14,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: ink.withValues(alpha: 0.4),
                        onPressed: () {
                          final uid = ref.read(currentUidProvider);
                          if (uid != null) {
                            unawaited(
                              ref.read(extraRepoProvider).remove(uid, e.id),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExtraSheet(),
    );
  }
}

class _AddExtraSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddExtraSheet> createState() => _AddExtraSheetState();
}

class _AddExtraSheetState extends ConsumerState<_AddExtraSheet> {
  final _labelCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  ExtraKind _kind = ExtraKind.fee;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0 || _labelCtrl.text.trim().isEmpty) return;
    final month = ref.read(selectedMonthProvider);
    unawaited(ref.read(extraRepoProvider).add(
          uid,
          monthKey: Extra.monthKeyFor(month),
          label: _labelCtrl.text.trim(),
          amount: amount,
          kind: _kind,
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
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
            Text('Add an extra', style: TallyType.headline(ink, size: 22)),
            const SizedBox(height: 14),
            Row(
              children: [
                _kindChip(
                    label: 'Fee',
                    icon: Icons.trending_down_rounded,
                    active: _kind == ExtraKind.fee,
                    onTap: () => setState(() => _kind = ExtraKind.fee)),
                const SizedBox(width: 10),
                _kindChip(
                    label: 'Payment',
                    icon: Icons.trending_up_rounded,
                    active: _kind == ExtraKind.payment,
                    onTap: () => setState(() => _kind = ExtraKind.payment)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                labelText: 'Label (e.g. Claude subscription)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                prefixText: '£ ',
                labelText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 18),
            HoneyButton(label: 'Save extra', expanded: true, onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _kindChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active
                ? TallyColors.honey
                : ink.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18, color: active ? TallyColors.ink : ink),
              const SizedBox(width: 8),
              Text(
                label,
                style: TallyType.title(
                  active ? TallyColors.ink : ink,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
