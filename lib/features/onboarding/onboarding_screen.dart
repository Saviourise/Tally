import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../data/models/user_settings.dart';
import '../../theme/tally_colors.dart';
import '../../theme/tally_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/honey_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _payCtrl = TextEditingController(text: '16.25');
  int _hours = 8;

  @override
  void dispose() {
    _payCtrl.dispose();
    super.dispose();
  }

  void _finish() {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final pay = double.tryParse(_payCtrl.text.trim()) ?? 16.25;
    final user = ref.read(firebaseAuthProvider).currentUser;
    // Fire-and-forget: local cache writes synchronously; AuthGate rebuilds
    // as soon as the settings stream emits onboarded: true.
    unawaited(ref.read(settingsRepoProvider).write(
      uid,
      UserSettings(
        hourlyFullDayPay: pay,
        fullDayHours: _hours,
        onboarded: true,
      ),
      profile: {
        'displayName': user?.displayName,
        'email': user?.email,
        'photoURL': user?.photoURL,
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final pay = double.tryParse(_payCtrl.text.trim()) ?? 0;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Set your rate', style: TallyType.headline(ink, size: 36)),
              const SizedBox(height: 6),
              Text(
                "We'll use this to total up your earnings.\nYou can change it any time in Settings.",
                style: TallyType.body(ink.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 28),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAY PER FULL DAY',
                      style: TallyType.label(ink.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('£', style: TallyType.display(ink, size: 36)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _payCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            ],
                            style: TallyType.display(ink, size: 44),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preview: a full day pays ${formatMoney(pay)}, a partial day pays ${formatMoney(pay / 2)}.',
                      style: TallyType.body(ink.withValues(alpha: 0.6), size: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOURS FOR A FULL DAY',
                      style: TallyType.label(ink.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final h in [4, 6, 8, 10, 12]) _chip(h, ink)],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              HoneyButton(
                label: 'Start tallying',
                expanded: true,
                onPressed: _finish,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(int h, Color ink) {
    final active = _hours == h;
    return GestureDetector(
      onTap: () => setState(() => _hours = h),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? TallyColors.honey : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? TallyColors.honey : ink.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          '${h}h',
          style: TallyType.title(
            active ? TallyColors.ink : ink,
            size: 15,
          ),
        ),
      ),
    );
  }
}
