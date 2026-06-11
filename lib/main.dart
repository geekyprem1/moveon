import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/journal/data/journal_repository.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive for Offline Journal Caching
  try {
    await Hive.initFlutter();
    await JournalRepository.init();
  } catch (e) {
    debugPrint('Hive failed to initialize: $e');
  }

  // 2. Initialize Firebase (Gracefully catches if not configured yet)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase failed to initialize: $e. Make sure to drop google-services.json (Android) / GoogleService-Info.plist (iOS) in place.');
  }

  // 3. Initialize Notification Service
  final container = ProviderContainer();
  try {
    final notificationService = container.read(notificationServiceProvider);
    await notificationService.init();
  } catch (e) {
    debugPrint('Notification service failed to initialize: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MoveOnApp(),
    ),
  );
}
