import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_options.dart';
import 'core/notifications/reminder_service.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await ReminderService.instance.init();

  final container = ProviderContainer();
  ReminderService.instance.onActionPayload = (payload) {
    // The only notification action is Stop, which needs the "Log this time?"
    // dialog — route it to the timer screen via the pending-action provider.
    container.read(pendingActionProvider.notifier).set(payload);
  };

  runApp(
    UncontrolledProviderScope(container: container, child: const TallyApp()),
  );
}
