import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../theme/tally_colors.dart';

/// Payloads that the notification callback emits. The app listens for these
/// via [onActionPayload] and reacts (e.g. shows a confirmation dialog).
class NotifPayload {
  static const timerStop = 'timer.stop';
  static const timerOpen = 'timer.open';
}

class ReminderService {
  ReminderService._();
  static final instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Daily 10pm reminder
  static const _reminderId = 1001;
  static const _reminderChannelId = 'tally_reminder';
  static const _reminderChannelName = 'Daily log reminder';

  // Live timer ongoing notification
  static const _timerId = 2001;
  static const _timerChannelId = 'tally_timer';
  static const _timerChannelName = 'Timer running';

  bool _initialized = false;

  /// Listener for action button payloads from notifications. Set by the app at
  /// startup so it can react (e.g. show the "Log this time?" dialog).
  ValueChanged<String>? onActionPayload;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    // Pin to the device's actual zone so scheduled fire-times match wall clock.
    try {
      final name = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(_tzAlias(name)));
    } catch (_) {
      // Fall back silently — local stays whatever the package picked.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notifGranted = await android?.requestNotificationsPermission();
    final exactGranted = await android?.requestExactAlarmsPermission();
    debugPrint(
      '[Tally][ReminderService] notifPerm=$notifGranted '
      'exactAlarmPerm=$exactGranted',
    );

    _initialized = true;
  }

  /// Maps abbreviations like "BST"/"GMT" to IANA zones the timezone package
  /// understands. Falls back to Europe/London for UK abbreviations.
  String _tzAlias(String abbr) {
    switch (abbr) {
      case 'BST':
      case 'GMT':
      case 'British Summer Time':
      case 'Greenwich Mean Time':
        return 'Europe/London';
      case 'WAT':
      case 'West Africa Standard Time':
        return 'Africa/Lagos';
      default:
        return abbr; // try as-is; package may already know it
    }
  }

  void _onResponse(NotificationResponse r) {
    final payload = r.actionId ?? r.payload;
    if (payload != null && payload.isNotEmpty) {
      debugPrint('[Tally] notification action: $payload');
      onActionPayload?.call(payload);
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundResponse(NotificationResponse r) {
    debugPrint('[Tally] bg notification action: ${r.actionId ?? r.payload}');
  }

  // ---- daily reminder ----

  Future<void> schedule(String hhmm) async {
    await init();
    await cancel();
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts[0]) ?? 22;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final scheduled = _nextInstanceOf(hour, minute);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        channelDescription:
            'Nudges you to log your hours at the end of the day',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    debugPrint(
      '[Tally][ReminderService] scheduling daily reminder for $hhmm '
      '→ first fire at $scheduled (zone: ${tz.local.name})',
    );
    try {
      await _plugin.zonedSchedule(
        id: _reminderId,
        title: 'Tally',
        body: "Don't forget to log today's hours.",
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('[Tally][ReminderService] scheduled with exactAllowWhileIdle');
    } catch (e) {
      debugPrint('[Tally][ReminderService] exact failed ($e); falling back');
      await _plugin.zonedSchedule(
        id: _reminderId,
        title: 'Tally',
        body: "Don't forget to log today's hours.",
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancel() async {
    await _plugin.cancel(id: _reminderId);
  }

  /// Fire an immediate test notification to verify the channel + permission.
  Future<void> sendTestReminder() async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        channelDescription:
            'Nudges you to log your hours at the end of the day',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: _reminderId + 1,
      title: 'Tally test',
      body: 'If you see this, reminders are working.',
      notificationDetails: details,
    );
  }

  /// Returns the next scheduled fire time, for debugging.
  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();

  // ---- live timer ongoing notification ----

  /// Show or update the ongoing timer notification.
  ///
  /// While running, we hand the counting to Android's native chronometer:
  /// [usesChronometer] + a [when] base equal to the wall-clock instant the
  /// timer effectively started from (now minus [elapsed]). Android then ticks
  /// the seconds live in the notification on its own, so it stays in real time
  /// even when the app is backgrounded or the timer screen is unmounted. When
  /// paused we turn the chronometer off and show the frozen banked time.
  Future<void> showTimer({
    required Duration elapsed,
    required bool isRunning,
  }) async {
    await init();
    final chronometerBase = DateTime.now().subtract(elapsed);
    final body = isRunning
        ? 'Working'
        : 'Paused · ${_format(elapsed)}';
    // Only a Stop action — pause/resume are driven from the app's ring. The
    // label is tinted with our honey accent to match the Tally theme.
    const actions = [
      AndroidNotificationAction(
        NotifPayload.timerStop,
        'Stop',
        cancelNotification: false,
        showsUserInterface: true,
        titleColor: TallyColors.honeyDeep,
      ),
    ];
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _timerChannelId,
        _timerChannelName,
        channelDescription: 'Shows the running Tally timer',
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        importance: Importance.low,
        priority: Priority.low,
        showWhen: isRunning,
        when: isRunning ? chronometerBase.millisecondsSinceEpoch : null,
        usesChronometer: isRunning,
        category: AndroidNotificationCategory.stopwatch,
        // Honey accent for the app-name/icon tint to match the brand.
        color: TallyColors.honey,
        actions: actions,
      ),
      iOS: const DarwinNotificationDetails(presentAlert: false),
    );
    await _plugin.show(
      id: _timerId,
      title: 'Tally timer',
      body: body,
      notificationDetails: details,
      payload: NotifPayload.timerOpen,
    );
  }

  Future<void> cancelTimer() async {
    await _plugin.cancel(id: _timerId);
  }

  // ---- internals ----

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    if (m > 0) {
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${s}s';
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
