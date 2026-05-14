import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/notifications/reminder_service.dart';
import '../../core/providers.dart';
import '../../data/models/user_settings.dart';
import '../../theme/tally_colors.dart';
import '../../theme/tally_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/honey_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _payCtrl = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _payCtrl.dispose();
    super.dispose();
  }

  void _save(UserSettings s) {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    unawaited(ref.read(settingsRepoProvider).write(uid, s));
    if (s.reminderEnabled) {
      unawaited(ReminderService.instance.schedule(s.reminderTime));
    } else {
      unawaited(ReminderService.instance.cancel());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final user = ref.watch(authStateProvider).value;
    final ink = Theme.of(context).colorScheme.onSurface;
    if (!_seeded) {
      _payCtrl.text = s.hourlyFullDayPay.toString();
      _seeded = true;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        const SizedBox(height: 8),
        Text('Settings', style: TallyType.headline(ink, size: 28)),
        const SizedBox(height: 18),
        if (user != null)
          GlassCard(
            child: Row(
              children: [
                _ProfileAvatar(user: user),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName ?? 'Tally user',
                          style: TallyType.title(ink, size: 16)),
                      Text(user.email ?? '',
                          style: TallyType.body(ink.withValues(alpha: 0.6), size: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        _section('PAY', ink),
        GlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Full-day pay (£)',
                        style: TallyType.title(ink, size: 14)),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _payCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      textAlign: TextAlign.right,
                      style: TallyType.title(ink, size: 16),
                      decoration: const InputDecoration(border: InputBorder.none),
                      onSubmitted: (v) {
                        final n = double.tryParse(v) ?? s.hourlyFullDayPay;
                        _save(s.copyWith(hourlyFullDayPay: n));
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hours per full day',
                      style: TallyType.title(ink, size: 14),
                    ),
                  ),
                  DropdownButton<int>(
                    value: s.fullDayHours,
                    underline: const SizedBox.shrink(),
                    items: [for (final h in [4, 6, 8, 10, 12])
                      DropdownMenuItem(value: h, child: Text('${h}h'))],
                    onChanged: (v) {
                      if (v != null) _save(s.copyWith(fullDayHours: v));
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preview',
                            style: TallyType.label(ink.withValues(alpha: 0.55), size: 11)),
                        const SizedBox(height: 4),
                        Text(
                          'Full: ${formatMoney(s.hourlyFullDayPay)}  ·  Half: ${formatMoney(s.hourlyFullDayPay / 2)}',
                          style: TallyType.body(ink.withValues(alpha: 0.7), size: 12),
                        ),
                      ],
                    ),
                  ),
                  HoneyButton(
                    label: 'Save',
                    compact: true,
                    onPressed: () {
                      final n = double.tryParse(_payCtrl.text.trim()) ?? s.hourlyFullDayPay;
                      _save(s.copyWith(hourlyFullDayPay: n));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _section('APPEARANCE', ink),
        GlassCard(
          child: Column(
            children: [
              for (final mode in ThemeMode.values)
                RadioListTile<ThemeMode>(
                  contentPadding: EdgeInsets.zero,
                  value: mode,
                  groupValue: s.themeMode,
                  activeColor: TallyColors.honey,
                  onChanged: (v) {
                    if (v != null) _save(s.copyWith(themeMode: v));
                  },
                  title: Text(_themeLabel(mode), style: TallyType.title(ink, size: 14)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _section('REMINDERS', ink),
        GlassCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.reminderEnabled,
                activeThumbColor: TallyColors.honey,
                title: Text('Daily reminder to log hours',
                    style: TallyType.title(ink, size: 14)),
                subtitle: Text('Default 10:00 PM',
                    style: TallyType.body(ink.withValues(alpha: 0.6), size: 12)),
                onChanged: (v) => _save(s.copyWith(reminderEnabled: v)),
              ),
              const Divider(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: s.reminderEnabled,
                title: Text('Time', style: TallyType.title(ink, size: 14)),
                trailing: Text(
                  _displayTime(s.reminderTime),
                  style: TallyType.title(ink, size: 14),
                ),
                onTap: !s.reminderEnabled
                    ? null
                    : () async {
                        final parts = s.reminderTime.split(':');
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: int.tryParse(parts[0]) ?? 22,
                            minute: int.tryParse(parts[1]) ?? 0,
                          ),
                        );
                        if (picked != null) {
                          final hh = picked.hour.toString().padLeft(2, '0');
                          final mm = picked.minute.toString().padLeft(2, '0');
                          _save(s.copyWith(reminderTime: '$hh:$mm'));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Reminder set for ${_displayTime('$hh:$mm')}',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
              ),
              const Divider(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Send test reminder',
                    style: TallyType.title(ink, size: 14)),
                subtitle: Text('Fires immediately so you can verify it works',
                    style: TallyType.body(ink.withValues(alpha: 0.6), size: 12)),
                trailing: const Icon(Icons.notifications_active_rounded,
                    color: TallyColors.honey),
                onTap: () async {
                  await ReminderService.instance.sendTestReminder();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GlassCard(
          onTap: () => ref.read(authRepoProvider).signOut(),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFB04A2F)),
              const SizedBox(width: 12),
              Text('Sign out',
                  style: TallyType.title(const Color(0xFFB04A2F), size: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String label, Color ink) => Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 10),
        child: Text(label,
            style: TallyType.label(ink.withValues(alpha: 0.55), size: 11)),
      );

  String _themeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _displayTime(String s) {
    final parts = s.split(':');
    final h = int.tryParse(parts[0]) ?? 22;
    final m = int.tryParse(parts[1]) ?? 0;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final hh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hh:${m.toString().padLeft(2, '0')} $ampm';
  }
}

class _ProfileAvatar extends StatefulWidget {
  const _ProfileAvatar({required this.user});
  final User user;

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  bool _imageFailed = false;

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.displayName ?? widget.user.email ?? 'T';
    final initial = displayName.trim().isEmpty
        ? 'T'
        : displayName.trim().characters.first.toUpperCase();
    final url = widget.user.photoURL;
    final fallback = Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: TallyColors.honey,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TallyType.headline(Colors.white, size: 20),
      ),
    );
    if (_imageFailed || url == null || url.isEmpty) return fallback;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TallyColors.honey.withValues(alpha: 0.3),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
          onError: (e, st) {
            debugPrint('[Tally] profile image load failed: $e');
            if (mounted) setState(() => _imageFailed = true);
          },
        ),
      ),
    );
  }
}
