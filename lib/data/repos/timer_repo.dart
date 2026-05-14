import 'package:cloud_firestore/cloud_firestore.dart';

class TimerState {
  final bool isRunning;
  final DateTime? startedAt; // when the current run started (null if paused/idle)
  final int accumulatedSeconds; // banked across pauses; doesn't include current run
  final String? label;

  const TimerState({
    required this.isRunning,
    this.startedAt,
    this.accumulatedSeconds = 0,
    this.label,
  });

  /// Total elapsed seconds (banked + current run if running).
  int get totalSeconds {
    if (!isRunning || startedAt == null) return accumulatedSeconds;
    return accumulatedSeconds + DateTime.now().difference(startedAt!).inSeconds;
  }

  bool get isActive => isRunning || accumulatedSeconds > 0;

  factory TimerState.fromMap(Map<String, dynamic>? d) {
    if (d == null) return const TimerState(isRunning: false);
    return TimerState(
      isRunning: (d['isRunning'] as bool?) ?? false,
      startedAt: (d['startedAt'] as Timestamp?)?.toDate(),
      accumulatedSeconds: (d['accumulatedSeconds'] as num?)?.toInt() ?? 0,
      label: d['label'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'isRunning': isRunning,
        'startedAt': startedAt == null ? null : Timestamp.fromDate(startedAt!),
        'accumulatedSeconds': accumulatedSeconds,
        'label': label,
      };
}

class TimerRepo {
  TimerRepo(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid).collection('state').doc('timer');

  Stream<TimerState> watch(String uid) =>
      _doc(uid).snapshots().map((s) => TimerState.fromMap(s.data()));

  Future<TimerState> read(String uid) async {
    final s = await _doc(uid).get();
    return TimerState.fromMap(s.data());
  }

  Future<void> start(String uid, {String? label}) async {
    await _doc(uid).set(
      TimerState(
        isRunning: true,
        startedAt: DateTime.now(),
        accumulatedSeconds: 0,
        label: label,
      ).toMap(),
    );
  }

  /// Pause a currently-running timer, banking the elapsed seconds.
  Future<void> pause(String uid, TimerState current) async {
    if (!current.isRunning || current.startedAt == null) return;
    final banked = current.accumulatedSeconds +
        DateTime.now().difference(current.startedAt!).inSeconds;
    await _doc(uid).set(TimerState(
      isRunning: false,
      startedAt: null,
      accumulatedSeconds: banked,
      label: current.label,
    ).toMap());
  }

  /// Resume from paused state.
  Future<void> resume(String uid, TimerState current) async {
    if (current.isRunning) return;
    await _doc(uid).set(TimerState(
      isRunning: true,
      startedAt: DateTime.now(),
      accumulatedSeconds: current.accumulatedSeconds,
      label: current.label,
    ).toMap());
  }

  /// Clear the timer state entirely (after Stop+log or discard).
  Future<void> clear(String uid) async {
    await _doc(uid).set(const TimerState(isRunning: false).toMap());
  }
}
