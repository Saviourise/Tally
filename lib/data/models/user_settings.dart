import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserSettings {
  final double hourlyFullDayPay;
  final int fullDayHours;
  final String currency;
  final String contractorName;
  final String contractorAddressLine1;
  final String contractorAddressLine2;
  final String contractorAddressLine3;
  final String contractorPostcode;
  final String companyName;
  final String companyAddressLine1;
  final String companyAddressLine2;
  final String companyAddressLine3;
  final String companyNumber;
  final String paymentAccountName;
  final String paymentSortCode;
  final String paymentAccountNumber;
  final String paymentSwiftCode;
  final String paymentBankName;
  final String paymentBankAddress;
  final Map<String, int> invoiceSequenceByMonth;
  final Map<String, String> invoiceCarryForwardStartByMonth;
  final ThemeMode themeMode;
  final bool reminderEnabled;
  final String reminderTime; // "HH:mm" 24h
  final bool onboarded;

  const UserSettings({
    this.hourlyFullDayPay = 16.25,
    this.fullDayHours = 8,
    this.currency = '£',
    this.contractorName = '',
    this.contractorAddressLine1 = '',
    this.contractorAddressLine2 = '',
    this.contractorAddressLine3 = '',
    this.contractorPostcode = '',
    this.companyName = 'The Cozm Ltd',
    this.companyAddressLine1 = '20-22 Wenlock Road',
    this.companyAddressLine2 = 'London, N1 7GU',
    this.companyAddressLine3 = 'UK',
    this.companyNumber = '14293339',
    this.paymentAccountName = '',
    this.paymentSortCode = '',
    this.paymentAccountNumber = '',
    this.paymentSwiftCode = '',
    this.paymentBankName = '',
    this.paymentBankAddress = '',
    this.invoiceSequenceByMonth = const {},
    this.invoiceCarryForwardStartByMonth = const {},
    this.themeMode = ThemeMode.system,
    this.reminderEnabled = true,
    this.reminderTime = '22:00',
    this.onboarded = false,
  });

  UserSettings copyWith({
    double? hourlyFullDayPay,
    int? fullDayHours,
    String? currency,
    String? contractorName,
    String? contractorAddressLine1,
    String? contractorAddressLine2,
    String? contractorAddressLine3,
    String? contractorPostcode,
    String? companyName,
    String? companyAddressLine1,
    String? companyAddressLine2,
    String? companyAddressLine3,
    String? companyNumber,
    String? paymentAccountName,
    String? paymentSortCode,
    String? paymentAccountNumber,
    String? paymentSwiftCode,
    String? paymentBankName,
    String? paymentBankAddress,
    Map<String, int>? invoiceSequenceByMonth,
    Map<String, String>? invoiceCarryForwardStartByMonth,
    ThemeMode? themeMode,
    bool? reminderEnabled,
    String? reminderTime,
    bool? onboarded,
  }) => UserSettings(
    hourlyFullDayPay: hourlyFullDayPay ?? this.hourlyFullDayPay,
    fullDayHours: fullDayHours ?? this.fullDayHours,
    currency: currency ?? this.currency,
    contractorName: contractorName ?? this.contractorName,
    contractorAddressLine1:
        contractorAddressLine1 ?? this.contractorAddressLine1,
    contractorAddressLine2:
        contractorAddressLine2 ?? this.contractorAddressLine2,
    contractorAddressLine3:
        contractorAddressLine3 ?? this.contractorAddressLine3,
    contractorPostcode: contractorPostcode ?? this.contractorPostcode,
    companyName: companyName ?? this.companyName,
    companyAddressLine1: companyAddressLine1 ?? this.companyAddressLine1,
    companyAddressLine2: companyAddressLine2 ?? this.companyAddressLine2,
    companyAddressLine3: companyAddressLine3 ?? this.companyAddressLine3,
    companyNumber: companyNumber ?? this.companyNumber,
    paymentAccountName: paymentAccountName ?? this.paymentAccountName,
    paymentSortCode: paymentSortCode ?? this.paymentSortCode,
    paymentAccountNumber: paymentAccountNumber ?? this.paymentAccountNumber,
    paymentSwiftCode: paymentSwiftCode ?? this.paymentSwiftCode,
    paymentBankName: paymentBankName ?? this.paymentBankName,
    paymentBankAddress: paymentBankAddress ?? this.paymentBankAddress,
    invoiceSequenceByMonth:
        invoiceSequenceByMonth ?? this.invoiceSequenceByMonth,
    invoiceCarryForwardStartByMonth:
        invoiceCarryForwardStartByMonth ??
        this.invoiceCarryForwardStartByMonth,
    themeMode: themeMode ?? this.themeMode,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderTime: reminderTime ?? this.reminderTime,
    onboarded: onboarded ?? this.onboarded,
  );

  factory UserSettings.fromMap(Map<String, dynamic>? data) {
    final d = data ?? {};
    return UserSettings(
      hourlyFullDayPay: (d['hourlyFullDayPay'] as num?)?.toDouble() ?? 16.25,
      fullDayHours: (d['fullDayHours'] as num?)?.toInt() ?? 8,
      currency: (d['currency'] as String?) ?? '£',
      contractorName: (d['contractorName'] as String?) ?? '',
      contractorAddressLine1: (d['contractorAddressLine1'] as String?) ?? '',
      contractorAddressLine2: (d['contractorAddressLine2'] as String?) ?? '',
      contractorAddressLine3: (d['contractorAddressLine3'] as String?) ?? '',
      contractorPostcode: (d['contractorPostcode'] as String?) ?? '',
      companyName: (d['companyName'] as String?) ?? 'The Cozm Ltd',
      companyAddressLine1:
          (d['companyAddressLine1'] as String?) ?? '20-22 Wenlock Road',
      companyAddressLine2:
          (d['companyAddressLine2'] as String?) ?? 'London, N1 7GU',
      companyAddressLine3: (d['companyAddressLine3'] as String?) ?? 'UK',
      companyNumber: (d['companyNumber'] as String?) ?? '14293339',
      paymentAccountName: (d['paymentAccountName'] as String?) ?? '',
      paymentSortCode: (d['paymentSortCode'] as String?) ?? '',
      paymentAccountNumber: (d['paymentAccountNumber'] as String?) ?? '',
      paymentSwiftCode: (d['paymentSwiftCode'] as String?) ?? '',
      paymentBankName: (d['paymentBankName'] as String?) ?? '',
      paymentBankAddress: (d['paymentBankAddress'] as String?) ?? '',
      invoiceSequenceByMonth: _invoiceSequenceMap(d['invoiceSequenceByMonth']),
      invoiceCarryForwardStartByMonth: _stringMap(
        d['invoiceCarryForwardStartByMonth'],
      ),
      themeMode: _modeFromString(d['themeMode'] as String?),
      reminderEnabled: (d['reminderEnabled'] as bool?) ?? true,
      reminderTime: (d['reminderTime'] as String?) ?? '22:00',
      onboarded: (d['onboarded'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'hourlyFullDayPay': hourlyFullDayPay,
    'fullDayHours': fullDayHours,
    'currency': currency,
    'contractorName': contractorName,
    'contractorAddressLine1': contractorAddressLine1,
    'contractorAddressLine2': contractorAddressLine2,
    'contractorAddressLine3': contractorAddressLine3,
    'contractorPostcode': contractorPostcode,
    'companyName': companyName,
    'companyAddressLine1': companyAddressLine1,
    'companyAddressLine2': companyAddressLine2,
    'companyAddressLine3': companyAddressLine3,
    'companyNumber': companyNumber,
    'paymentAccountName': paymentAccountName,
    'paymentSortCode': paymentSortCode,
    'paymentAccountNumber': paymentAccountNumber,
    'paymentSwiftCode': paymentSwiftCode,
    'paymentBankName': paymentBankName,
    'paymentBankAddress': paymentBankAddress,
    'invoiceSequenceByMonth': invoiceSequenceByMonth,
    'invoiceCarryForwardStartByMonth': invoiceCarryForwardStartByMonth,
    'themeMode': _modeToString(themeMode),
    'reminderEnabled': reminderEnabled,
    'reminderTime': reminderTime,
    'onboarded': onboarded,
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  };

  static Map<String, int> _invoiceSequenceMap(dynamic value) {
    if (value is! Map) return const {};
    final map = <String, int>{};
    for (final entry in value.entries) {
      final key = entry.key?.toString();
      final amount = (entry.value as num?)?.toInt();
      if (key == null || key.isEmpty || amount == null) continue;
      map[key] = amount;
    }
    return map;
  }

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) return const {};
    final map = <String, String>{};
    for (final entry in value.entries) {
      final key = entry.key?.toString();
      final text = entry.value?.toString();
      if (key == null || key.isEmpty || text == null || text.isEmpty) {
        continue;
      }
      map[key] = text;
    }
    return map;
  }

  static ThemeMode _modeFromString(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _modeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
