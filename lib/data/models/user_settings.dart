import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserSettings {
  final double hourlyFullDayPay;
  final int fullDayHours;
  final String currency;
  final ThemeMode themeMode;
  final bool reminderEnabled;
  final String reminderTime; // "HH:mm" 24h
  final bool onboarded;

  const UserSettings({
    this.hourlyFullDayPay = 16.25,
    this.fullDayHours = 8,
    this.currency = 'GBP',
    this.themeMode = ThemeMode.system,
    this.reminderEnabled = true,
    this.reminderTime = '22:00',
    this.onboarded = false,
  });

  UserSettings copyWith({
    double? hourlyFullDayPay,
    int? fullDayHours,
    String? currency,
    ThemeMode? themeMode,
    bool? reminderEnabled,
    String? reminderTime,
    bool? onboarded,
  }) =>
      UserSettings(
        hourlyFullDayPay: hourlyFullDayPay ?? this.hourlyFullDayPay,
        fullDayHours: fullDayHours ?? this.fullDayHours,
        currency: currency ?? this.currency,
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
      currency: (d['currency'] as String?) ?? 'GBP',
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
        'themeMode': _modeToString(themeMode),
        'reminderEnabled': reminderEnabled,
        'reminderTime': reminderTime,
        'onboarded': onboarded,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

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
