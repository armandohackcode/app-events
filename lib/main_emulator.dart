import 'package:app_events/config/di/service_locator.dart';
import 'package:app_events/firebase_options.dart';
import 'package:app_events/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Local sandbox entrypoint that connects Firestore and Cloud Functions to the
/// local Firebase Emulator Suite while keeping real Firebase Auth sign-in.
///
/// Production [main.dart] remains completely untouched. Run with:
/// `flutter run -t lib/main_emulator.dart -d <device_id>`
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const host = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  const firestorePort = int.fromEnvironment(
    'FIRESTORE_EMULATOR_PORT',
    defaultValue: 8080,
  );
  const functionsPort = int.fromEnvironment(
    'FUNCTIONS_EMULATOR_PORT',
    defaultValue: 5001,
  );

  FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
  FirebaseFirestore.instance.settings = const Settings(
    host: '$host:$firestorePort',
    sslEnabled: false,
    persistenceEnabled: false,
  );
  FirebaseFunctions.instanceFor(
    region: 'us-central1',
  ).useFunctionsEmulator(host, functionsPort);

  FirebaseAuth.instance.authStateChanges().listen((user) {
    debugPrint(
      '[SANDBOX] FirebaseAuth user: uid=${user?.uid ?? "null"} '
      'email=${user?.email ?? "null"} name=${user?.displayName ?? "null"}',
    );
  });

  setupServiceLocator();
  runApp(const MyApp());
}
