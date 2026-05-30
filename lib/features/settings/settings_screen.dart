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

enum _SaveFeedbackState { idle, saving, success, error }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _payCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();
  final _contractorNameCtrl = TextEditingController();
  final _contractorAddress1Ctrl = TextEditingController();
  final _contractorAddress2Ctrl = TextEditingController();
  final _contractorAddress3Ctrl = TextEditingController();
  final _contractorPostcodeCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _companyAddress1Ctrl = TextEditingController();
  final _companyAddress2Ctrl = TextEditingController();
  final _companyAddress3Ctrl = TextEditingController();
  final _companyNumberCtrl = TextEditingController();
  final _paymentAccountNameCtrl = TextEditingController();
  final _paymentSortCodeCtrl = TextEditingController();
  final _paymentAccountNumberCtrl = TextEditingController();
  final _paymentSwiftCodeCtrl = TextEditingController();
  final _paymentBankNameCtrl = TextEditingController();
  final _paymentBankAddressCtrl = TextEditingController();
  bool _seeded = false;
  _SaveFeedbackState _companyInvoiceSaveState = _SaveFeedbackState.idle;
  String? _companyInvoiceFeedback;

  @override
  void dispose() {
    _payCtrl.dispose();
    _currencyCtrl.dispose();
    _contractorNameCtrl.dispose();
    _contractorAddress1Ctrl.dispose();
    _contractorAddress2Ctrl.dispose();
    _contractorAddress3Ctrl.dispose();
    _contractorPostcodeCtrl.dispose();
    _companyNameCtrl.dispose();
    _companyAddress1Ctrl.dispose();
    _companyAddress2Ctrl.dispose();
    _companyAddress3Ctrl.dispose();
    _companyNumberCtrl.dispose();
    _paymentAccountNameCtrl.dispose();
    _paymentSortCodeCtrl.dispose();
    _paymentAccountNumberCtrl.dispose();
    _paymentSwiftCodeCtrl.dispose();
    _paymentBankNameCtrl.dispose();
    _paymentBankAddressCtrl.dispose();
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

  UserSettings _companyInvoiceSettings(UserSettings s) {
    return s.copyWith(
      currency: _currencyCtrl.text.trim().isEmpty
          ? s.currency
          : _currencyCtrl.text.trim().toUpperCase(),
      contractorName: _contractorNameCtrl.text.trim(),
      contractorAddressLine1: _contractorAddress1Ctrl.text.trim(),
      contractorAddressLine2: _contractorAddress2Ctrl.text.trim(),
      contractorAddressLine3: _contractorAddress3Ctrl.text.trim(),
      contractorPostcode: _contractorPostcodeCtrl.text.trim(),
      companyName: _companyNameCtrl.text.trim(),
      companyAddressLine1: _companyAddress1Ctrl.text.trim(),
      companyAddressLine2: _companyAddress2Ctrl.text.trim(),
      companyAddressLine3: _companyAddress3Ctrl.text.trim(),
      companyNumber: _companyNumberCtrl.text.trim(),
      paymentAccountName: _paymentAccountNameCtrl.text.trim(),
      paymentSortCode: _paymentSortCodeCtrl.text.trim(),
      paymentAccountNumber: _paymentAccountNumberCtrl.text.trim(),
      paymentSwiftCode: _paymentSwiftCodeCtrl.text.trim(),
      paymentBankName: _paymentBankNameCtrl.text.trim(),
      paymentBankAddress: _paymentBankAddressCtrl.text.trim(),
    );
  }

  Future<void> _saveCompanyInvoiceDetails(UserSettings s) async {
    final messenger = ScaffoldMessenger.of(context);
    final uid = ref.read(currentUidProvider);
    if (uid == null) {
      setState(() {
        _companyInvoiceSaveState = _SaveFeedbackState.error;
        _companyInvoiceFeedback =
            'You need to be signed in to save invoice details.';
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('You need to be signed in to save invoice details.'),
        ),
      );
      return;
    }

    setState(() {
      _companyInvoiceSaveState = _SaveFeedbackState.saving;
      _companyInvoiceFeedback = 'Saving company invoice details...';
    });

    try {
      await ref
          .read(settingsRepoProvider)
          .write(uid, _companyInvoiceSettings(s));
      if (!mounted) return;
      setState(() {
        _companyInvoiceSaveState = _SaveFeedbackState.success;
        _companyInvoiceFeedback = 'Company invoice details saved to Firebase.';
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Company invoice details saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _companyInvoiceSaveState = _SaveFeedbackState.error;
        _companyInvoiceFeedback =
            'Could not save company invoice details. Please try again.';
      });
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final user = ref.watch(authStateProvider).value;
    final ink = Theme.of(context).colorScheme.onSurface;
    if (!_seeded) {
      _payCtrl.text = s.hourlyFullDayPay.toString();
      _currencyCtrl.text = s.currency;
      _contractorNameCtrl.text = s.contractorName.isNotEmpty
          ? s.contractorName
          : (user?.displayName ?? '');
      _contractorAddress1Ctrl.text = s.contractorAddressLine1;
      _contractorAddress2Ctrl.text = s.contractorAddressLine2;
      _contractorAddress3Ctrl.text = s.contractorAddressLine3;
      _contractorPostcodeCtrl.text = s.contractorPostcode;
      _companyNameCtrl.text = s.companyName;
      _companyAddress1Ctrl.text = s.companyAddressLine1;
      _companyAddress2Ctrl.text = s.companyAddressLine2;
      _companyAddress3Ctrl.text = s.companyAddressLine3;
      _companyNumberCtrl.text = s.companyNumber;
      _paymentAccountNameCtrl.text = s.paymentAccountName.isNotEmpty
          ? s.paymentAccountName
          : (user?.displayName ?? '');
      _paymentSortCodeCtrl.text = s.paymentSortCode;
      _paymentAccountNumberCtrl.text = s.paymentAccountNumber;
      _paymentSwiftCodeCtrl.text = s.paymentSwiftCode;
      _paymentBankNameCtrl.text = s.paymentBankName;
      _paymentBankAddressCtrl.text = s.paymentBankAddress;
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
                      Text(
                        user.displayName ?? 'Tally user',
                        style: TallyType.title(ink, size: 16),
                      ),
                      Text(
                        user.email ?? '',
                        style: TallyType.body(
                          ink.withValues(alpha: 0.6),
                          size: 12,
                        ),
                      ),
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
                    child: Text(
                      'Full-day pay',
                      style: TallyType.title(ink, size: 14),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _payCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      textAlign: TextAlign.right,
                      style: TallyType.title(ink, size: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
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
                    items: [
                      for (final h in [4, 6, 8, 10, 12])
                        DropdownMenuItem(value: h, child: Text('${h}h')),
                    ],
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
                        Text(
                          'Preview',
                          style: TallyType.label(
                            ink.withValues(alpha: 0.55),
                            size: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Full: ${formatMoney(s.hourlyFullDayPay)}  |  Half: ${formatMoney(s.hourlyFullDayPay / 2)}',
                          style: TallyType.body(
                            ink.withValues(alpha: 0.7),
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  HoneyButton(
                    label: 'Save',
                    compact: true,
                    onPressed: () {
                      final n =
                          double.tryParse(_payCtrl.text.trim()) ??
                          s.hourlyFullDayPay;
                      _save(s.copyWith(hourlyFullDayPay: n));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _section('COMPANY INVOICE', ink),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'These details feed the new company invoice template. Cozm defaults are prefilled for the bill-to section.',
                style: TallyType.body(ink.withValues(alpha: 0.7), size: 13),
              ),
              const SizedBox(height: 16),
              _field(
                label: 'Currency code',
                controller: _currencyCtrl,
                ink: ink,
                hint: '£',
                textCapitalization: TextCapitalization.characters,
              ),
              const Divider(height: 24),
              Text(
                'FROM',
                style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
              ),
              const SizedBox(height: 10),
              _field(
                label: 'Full name or trading name',
                controller: _contractorNameCtrl,
                ink: ink,
              ),
              const Divider(height: 24),
              _field(
                label: 'Address line 1',
                controller: _contractorAddress1Ctrl,
                ink: ink,
              ),
              const Divider(height: 24),
              _field(
                label: 'Address line 2',
                controller: _contractorAddress2Ctrl,
                ink: ink,
              ),
              const Divider(height: 24),
              _field(
                label: 'Address line 3',
                controller: _contractorAddress3Ctrl,
                ink: ink,
              ),
              const Divider(height: 24),
              _field(
                label: 'Postcode / region',
                controller: _contractorPostcodeCtrl,
                ink: ink,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BILL TO',
                style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
              ),
              const SizedBox(height: 10),
              _field(
                label: 'Company name',
                controller: _companyNameCtrl,
                ink: ink,
              ),
              const Divider(height: 24),
              _field(
                label: 'Address line 1',
                controller: _companyAddress1Ctrl,
                ink: ink,
              ),
              const Divider(height: 24),
              _field(
                label: 'Address line 2',
                controller: _companyAddress2Ctrl,
                ink: ink,
              ),
              const Divider(height: 24),
              _field(
                label: 'Address line 3',
                controller: _companyAddress3Ctrl,
                ink: ink,
              ),
              const Divider(height: 24),
              _field(
                label: 'Company number',
                controller: _companyNumberCtrl,
                ink: ink,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PAYMENT DETAILS',
                style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
              ),
              const SizedBox(height: 10),
              _field(
                label: 'Account name',
                controller: _paymentAccountNameCtrl,
                ink: ink,
              ),
              const Divider(height: 24),
              _field(
                label: 'Sort code',
                controller: _paymentSortCodeCtrl,
                ink: ink,
              ),
              const Divider(height: 24),
              _field(
                label: 'Account number',
                controller: _paymentAccountNumberCtrl,
                ink: ink,
                keyboardType: TextInputType.number,
              ),
              const Divider(height: 24),
              _field(
                label: 'Swift code',
                controller: _paymentSwiftCodeCtrl,
                ink: ink,
                hint: 'Optional',
                textCapitalization: TextCapitalization.characters,
              ),
              const Divider(height: 24),
              _field(
                label: 'Bank name',
                controller: _paymentBankNameCtrl,
                ink: ink,
                hint: 'Optional',
              ),
              const Divider(height: 24),
              _field(
                label: 'Bank address',
                controller: _paymentBankAddressCtrl,
                ink: ink,
                hint: 'Optional',
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HoneyButton(
          label: switch (_companyInvoiceSaveState) {
            _SaveFeedbackState.saving => 'Saving...',
            _ => 'Save company invoice details',
          },
          expanded: true,
          onPressed: _companyInvoiceSaveState == _SaveFeedbackState.saving
              ? null
              : () => _saveCompanyInvoiceDetails(s),
        ),
        if (_companyInvoiceFeedback != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                switch (_companyInvoiceSaveState) {
                  _SaveFeedbackState.saving => Icons.hourglass_top_rounded,
                  _SaveFeedbackState.success => Icons.check_circle_rounded,
                  _SaveFeedbackState.error => Icons.error_rounded,
                  _SaveFeedbackState.idle => Icons.info_outline_rounded,
                },
                size: 18,
                color: switch (_companyInvoiceSaveState) {
                  _SaveFeedbackState.success => const Color(0xFF1F8A4C),
                  _SaveFeedbackState.error => const Color(0xFFB04A2F),
                  _SaveFeedbackState.saving => TallyColors.honeyDeep,
                  _SaveFeedbackState.idle => ink.withValues(alpha: 0.6),
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _companyInvoiceFeedback!,
                  style: TallyType.body(switch (_companyInvoiceSaveState) {
                    _SaveFeedbackState.success => const Color(0xFF1F8A4C),
                    _SaveFeedbackState.error => const Color(0xFFB04A2F),
                    _SaveFeedbackState.saving => ink.withValues(alpha: 0.75),
                    _SaveFeedbackState.idle => ink.withValues(alpha: 0.65),
                  }, size: 12),
                ),
              ),
            ],
          ),
        ],
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
                  title: Text(
                    _themeLabel(mode),
                    style: TallyType.title(ink, size: 14),
                  ),
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
                title: Text(
                  'Daily reminder to log hours',
                  style: TallyType.title(ink, size: 14),
                ),
                subtitle: Text(
                  'Default 10:00 PM',
                  style: TallyType.body(ink.withValues(alpha: 0.6), size: 12),
                ),
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
                        final messenger = ScaffoldMessenger.of(context);
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
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Reminder set for ${_displayTime('$hh:$mm')}',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
              ),
              const Divider(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Send test reminder',
                  style: TallyType.title(ink, size: 14),
                ),
                subtitle: Text(
                  'Fires immediately so you can verify it works',
                  style: TallyType.body(ink.withValues(alpha: 0.6), size: 12),
                ),
                trailing: const Icon(
                  Icons.notifications_active_rounded,
                  color: TallyColors.honey,
                ),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ReminderService.instance.sendTestReminder();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
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
              Text(
                'Sign out',
                style: TallyType.title(const Color(0xFFB04A2F), size: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required Color ink,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TallyType.label(ink.withValues(alpha: 0.5), size: 10),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: TallyType.title(ink, size: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TallyType.title(ink.withValues(alpha: 0.35), size: 14),
            isDense: true,
            contentPadding: const EdgeInsets.only(top: 4, bottom: 2),
            border: InputBorder.none,
          ),
        ),
      ],
    );
  }

  Widget _section(String label, Color ink) => Padding(
    padding: const EdgeInsets.only(left: 6, bottom: 10),
    child: Text(
      label,
      style: TallyType.label(ink.withValues(alpha: 0.55), size: 11),
    ),
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
      child: Text(initial, style: TallyType.headline(Colors.white, size: 20)),
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
