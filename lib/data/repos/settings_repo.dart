import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_settings.dart';

class SettingsRepo {
  SettingsRepo(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<UserSettings> watch(String uid) => _doc(uid).snapshots().map((s) {
        final data = s.data();
        if (data == null) return const UserSettings();
        return UserSettings.fromMap(data['settings'] as Map<String, dynamic>?);
      });

  Future<UserSettings> read(String uid) async {
    final snap = await _doc(uid).get();
    final data = snap.data();
    if (data == null) return const UserSettings();
    return UserSettings.fromMap(data['settings'] as Map<String, dynamic>?);
  }

  Future<void> write(String uid, UserSettings settings, {Map<String, dynamic>? profile}) async {
    final payload = <String, dynamic>{
      'settings': settings.toMap(),
      if (profile != null) 'profile': profile,
    };
    await _doc(uid).set(payload, SetOptions(merge: true));
  }
}
