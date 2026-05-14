import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/extra.dart';

class ExtraRepo {
  ExtraRepo(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('extras');

  Stream<List<Extra>> watchMonth(String uid, String monthKey) => _col(uid)
      .where('monthKey', isEqualTo: monthKey)
      .snapshots()
      .map((q) {
        final items = q.docs.map(Extra.fromSnapshot).toList();
        // Sort client-side to avoid needing a composite Firestore index.
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return items;
      });

  Future<void> add(
    String uid, {
    required String monthKey,
    required String label,
    required double amount,
    required ExtraKind kind,
  }) async {
    await _col(uid).add(Extra(
      id: '',
      monthKey: monthKey,
      label: label,
      amount: amount,
      kind: kind,
      createdAt: DateTime.now(),
    ).toMap());
  }

  Future<void> remove(String uid, String id) async {
    await _col(uid).doc(id).delete();
  }
}
