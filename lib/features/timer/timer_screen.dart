import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/notifications/reminder_service.dart';
import '../../core/pay_calc.dart';
import '../../core/providers.dart';
import '../../data/models/entry.dart';
import '../../data/repos/timer_repo.dart';
import '../../theme/tally_colors.dart';
import '../../theme/tally_typography.dart';
import '../../widgets/honey_button.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  Timer? _tick;
  Duration _elapsed = Duration.zero;
  TimerState _state = const TimerState(isRunning: false);
  int _lastNotifSecond = -30;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final newElapsed = Duration(seconds: _state.totalSeconds);
      if (newElapsed != _elapsed) setState(() => _elapsed = newElapsed);
      // Update notification every 30s while running (battery-friendly).
      if (_state.isRunning &&
          newElapsed.inSeconds - _lastNotifSecond >= 30) {
        _lastNotifSecond = newElapsed.inSeconds;
        ReminderService.instance.showTimer(
          elapsed: newElapsed,
          isRunning: true,
        );
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref.read(timerRepoProvider).start(uid);
    await ReminderService.instance.showTimer(
      elapsed: Duration.zero,
      isRunning: true,
    );
    _lastNotifSecond = 0;
  }

  Future<void> _pause() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref.read(timerRepoProvider).pause(uid, _state);
    final banked = Duration(seconds: _state.totalSeconds);
    await ReminderService.instance.showTimer(
      elapsed: banked,
      isRunning: false,
    );
  }

  Future<void> _resume() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref.read(timerRepoProvider).resume(uid, _state);
    await ReminderService.instance.showTimer(
      elapsed: Duration(seconds: _state.totalSeconds),
      isRunning: true,
    );
    _lastNotifSecond = _state.totalSeconds;
  }

  Future<void> _stopAndPrompt() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final total = _state.totalSeconds;
    if (total <= 0) {
      await ref.read(timerRepoProvider).clear(uid);
      await ReminderService.instance.cancelTimer();
      return;
    }
    // Pause first so the displayed time stops ticking while user decides.
    if (_state.isRunning) {
      await ref.read(timerRepoProvider).pause(uid, _state);
    }
    if (!mounted) return;
    final settings = ref.read(settingsProvider);
    final monthEntries = ref.read(monthEntriesProvider).value ?? const [];
    final minutes = (total / 60).round();
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    // Preview the marginal pay this timer adds to today, considering today's
    // existing entry and weekend pooling.
    final today = DateTime.now();
    final todayId = Entry.idForDate(today);
    final existingToday = monthEntries
        .where((e) => e.id == todayId)
        .fold<int>(0, (a, e) => a + e.totalMinutes);
    final newTotalToday = existingToday + minutes;
    final payAfter = PayCalc.previewPay(
      date: today,
      totalMinutes: newTotalToday,
      monthEntries: monthEntries,
      hourlyFullDayPay: settings.hourlyFullDayPay,
      fullDayHours: settings.fullDayHours,
    );
    final payBefore = existingToday > 0
        ? PayCalc.previewPay(
            date: today,
            totalMinutes: existingToday,
            monthEntries: monthEntries,
            hourlyFullDayPay: settings.hourlyFullDayPay,
            fullDayHours: settings.fullDayHours,
          )
        : 0.0;
    final pay = (payAfter - payBefore).clamp(0.0, double.infinity);

    final shouldLog = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log this time?', style: TallyType.headline(
            Theme.of(context).colorScheme.onSurface, size: 22)),
        content: Text(
          'You tracked ${formatHM(minutes)} (${formatMoney(pay)}).\nAdd it to today\'s entry?',
          style: TallyType.body(
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Discard',
                style: TallyType.title(
                    Theme.of(context).colorScheme.onSurface, size: 14)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: TallyColors.honey),
            child: Text('Log $hours h ${mins.toString().padLeft(2, '0')} m',
                style: TallyType.title(Colors.white, size: 14)),
          ),
        ],
      ),
    );

    final repo = ref.read(entryRepoProvider);
    if (shouldLog == true) {
      await repo.addMinutesToDay(
        uid,
        date: DateTime.now(),
        minutesToAdd: minutes,
        source: 'timer',
      );
    }
    await ref.read(timerRepoProvider).clear(uid);
    await ReminderService.instance.cancelTimer();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(timerStateProvider);
    _state = asyncState.value ?? const TimerState(isRunning: false);
    _elapsed = Duration(seconds: _state.totalSeconds);

    // React to notification action payloads.
    ref.listen<String?>(pendingActionProvider, (prev, next) {
      if (next == null) return;
      ref.read(pendingActionProvider.notifier).set(null);
      switch (next) {
        case NotifPayload.timerPause:
          _pause();
          break;
        case NotifPayload.timerResume:
          _resume();
          break;
        case NotifPayload.timerStop:
          _stopAndPrompt();
          break;
      }
    });

    final ink = Theme.of(context).colorScheme.onSurface;
    final hours = _elapsed.inHours;
    final mins = _elapsed.inMinutes.remainder(60);
    final secs = _elapsed.inSeconds.remainder(60);
    final hourFraction = (_elapsed.inSeconds / 3600.0).clamp(0.0, 12.0);
    final progress = (hourFraction % 12) / 12;
    final hasActive = _state.isActive;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIMER', style: TallyType.label(ink.withValues(alpha: 0.55), size: 11)),
          const SizedBox(height: 4),
          Text('Tick away', style: TallyType.headline(ink, size: 30)),
          const SizedBox(height: 28),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: _state.isRunning ? progress : (hasActive ? progress : 0),
                    color: TallyColors.honey,
                    trackColor: ink.withValues(alpha: 0.08),
                    pulse: _state.isRunning,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _state.isRunning
                                ? TallyColors.honey.withValues(alpha: 0.15)
                                : ink.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _state.isRunning
                                ? 'WORKING'
                                : hasActive
                                    ? 'PAUSED'
                                    : 'READY',
                            style: TallyType.label(
                              _state.isRunning
                                  ? TallyColors.honeyDeep
                                  : ink.withValues(alpha: 0.5),
                              size: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}',
                          style: TallyType.display(ink, size: 64),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${secs.toString().padLeft(2, '0')}s',
                          style: TallyType.mono(ink.withValues(alpha: 0.5), size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _Controls(
            state: _state,
            onStart: _start,
            onPause: _pause,
            onResume: _resume,
            onStop: _stopAndPrompt,
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final TimerState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    if (!state.isActive) {
      return HoneyButton(
        label: 'Start',
        icon: Icons.play_arrow_rounded,
        expanded: true,
        onPressed: onStart,
      );
    }
    return Row(
      children: [
        Expanded(
          child: state.isRunning
              ? _SecondaryButton(
                  label: 'Pause',
                  icon: Icons.pause_rounded,
                  onPressed: onPause,
                )
              : HoneyButton(
                  label: 'Resume',
                  icon: Icons.play_arrow_rounded,
                  expanded: true,
                  onPressed: onResume,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: state.isRunning
              ? HoneyButton(
                  label: 'Stop',
                  icon: Icons.stop_rounded,
                  expanded: true,
                  onPressed: onStop,
                )
              : _SecondaryButton(
                  label: 'Stop',
                  icon: Icons.stop_rounded,
                  onPressed: onStop,
                ),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: 56,
      child: Material(
        color: ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: ink),
                const SizedBox(width: 8),
                Text(label, style: TallyType.title(ink, size: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.pulse = false,
  });
  final double progress;
  final Color color;
  final Color trackColor;
  final bool pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 14;
    final track = Paint()
      ..color = trackColor
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;
    final fg = Paint()
      ..color = color
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fg);
    final tickPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 1;
    for (var i = 0; i < 60; i++) {
      final a = -math.pi / 2 + (2 * math.pi * i / 60);
      final r1 = radius + 10;
      final r2 = radius + (i % 5 == 0 ? 18 : 14);
      canvas.drawLine(
        center + Offset(math.cos(a) * r1, math.sin(a) * r1),
        center + Offset(math.cos(a) * r2, math.sin(a) * r2),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.pulse != pulse;
}
