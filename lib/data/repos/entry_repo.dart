import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/entry.dart';

class EntryRepo {
  EntryRepo(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('entries');

  Stream<List<Entry>> watchMonth(String uid, int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _col(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map((q) => q.docs.map(Entry.fromSnapshot).toList());
  }

  Stream<List<Entry>> watchYear(String uid, int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);
    return _col(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map((q) => q.docs.map(Entry.fromSnapshot).toList());
  }

  Stream<Entry?> watchDay(String uid, DateTime day) =>
      _col(uid).doc(Entry.idForDate(day)).snapshots().map(
        (s) => s.exists ? Entry.fromSnapshot(s) : null,
      );

  Future<Entry?> readDay(String uid, DateTime day) async {
    final snap = await _col(uid).doc(Entry.idForDate(day)).get();
    return snap.exists ? Entry.fromSnapshot(snap) : null;
  }

  Future<void> upsert(
    String uid, {
    required DateTime date,
    required int hours,
    required int minutes,
    String source = 'manual',
  }) async {
    final id = Entry.idForDate(date);
    final day = DateTime(date.year, date.month, date.day);
    final totalMinutes = hours * 60 + minutes;
    // Merge-only write: no pre-read (which can hang when offline / slow network).
    // createdAt is only written when the doc is new — uses set with merge so
    // we don't overwrite an earlier createdAt on subsequent updates.
    await _col(uid).doc(id).set({
      'date': Timestamp.fromDate(day),
      'hours': hours,
      'minutes': minutes,
      'totalMinutes': totalMinutes,
      'source': source,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addMinutesToDay(
    String uid, {
    required DateTime date,
    required int minutesToAdd,
    String source = 'timer',
  }) async {
    final existing = await readDay(uid, date);
    final totalMinutes = (existing?.totalMinutes ?? 0) + minutesToAdd;
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    await upsert(uid, date: date, hours: h, minutes: m, source: source);
  }

  Future<void> delete(String uid, DateTime date) async {
    await _col(uid).doc(Entry.idForDate(date)).delete();
  }
}
