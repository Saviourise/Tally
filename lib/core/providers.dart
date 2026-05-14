import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/entry.dart';
import '../data/models/extra.dart';
import '../data/models/user_settings.dart';
import '../data/repos/entry_repo.dart';
import '../data/repos/extra_repo.dart';
import '../data/repos/settings_repo.dart';
import '../data/repos/timer_repo.dart';
import 'auth/auth_repo.dart';

// --- Firebase singletons -------------------------------------------------

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

// --- Repos ---------------------------------------------------------------

final authRepoProvider = Provider<AuthRepo>((ref) => AuthRepo(ref.watch(firebaseAuthProvider)));
final settingsRepoProvider = Provider<SettingsRepo>((ref) => SettingsRepo(ref.watch(firestoreProvider)));
final entryRepoProvider = Provider<EntryRepo>((ref) => EntryRepo(ref.watch(firestoreProvider)));
final extraRepoProvider = Provider<ExtraRepo>((ref) => ExtraRepo(ref.watch(firestoreProvider)));
final timerRepoProvider = Provider<TimerRepo>((ref) => TimerRepo(ref.watch(firestoreProvider)));

// --- Auth state ----------------------------------------------------------

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepoProvider).authStateChanges(),
);

final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).value?.uid,
);

// --- Settings ------------------------------------------------------------

final settingsStreamProvider = StreamProvider<UserSettings>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const UserSettings());
  return ref.watch(settingsRepoProvider).watch(uid);
});

final settingsProvider = Provider<UserSettings>(
  (ref) => ref.watch(settingsStreamProvider).value ?? const UserSettings(),
);

// --- Selected month ------------------------------------------------------

class SelectedMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, 1);
  }

  @override
  set state(DateTime value) {
    super.state = value;
  }
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonth, DateTime>(SelectedMonth.new);

// --- Entries -------------------------------------------------------------

final monthEntriesProvider = StreamProvider<List<Entry>>((ref) {
  final uid = ref.watch(currentUidProvider);
  final month = ref.watch(selectedMonthProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(entryRepoProvider).watchMonth(uid, month.year, month.month);
});

final todayEntryProvider = StreamProvider<Entry?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(entryRepoProvider).watchDay(uid, DateTime.now());
});

final yearEntriesProvider = StreamProvider<List<Entry>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(entryRepoProvider).watchYear(uid, DateTime.now().year);
});

// --- Extras --------------------------------------------------------------

final monthExtrasProvider = StreamProvider<List<Extra>>((ref) {
  final uid = ref.watch(currentUidProvider);
  final month = ref.watch(selectedMonthProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(extraRepoProvider).watchMonth(uid, Extra.monthKeyFor(month));
});

// --- Timer ---------------------------------------------------------------

final timerStateProvider = StreamProvider<TimerState>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const TimerState(isRunning: false));
  return ref.watch(timerRepoProvider).watch(uid);
});

/// Pending UI action from a notification tap (e.g. timer.stop). Cleared by
/// the screen that handles it.
class PendingAction extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) {
    state = value;
  }
}

final pendingActionProvider =
    NotifierProvider<PendingAction, String?>(PendingAction.new);
