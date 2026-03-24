import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app/router.dart';
import 'models/elo_record.dart';
import 'models/question.dart';
import 'providers/theme_mode_provider.dart';
import 'theme/app_theme.dart';

/// Whether Firebase was successfully initialised.
///
/// Read by the [AnalyticsService] provider — when `false` the service
/// becomes a complete no-op so a missing `google-services.json` or any
/// other Firebase error never affects app behaviour.
bool firebaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pin status bar to light icons (white) regardless of device/app theme.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Android
    statusBarBrightness: Brightness.dark, // iOS
  ));

  // Firebase — initialise only in release/profile builds.
  // Wrapped in try/catch so a missing google-services.json (or any other
  // Firebase error) never blocks app launch — analytics simply becomes
  // a no-op (see AnalyticsService).
  if (!kDebugMode) {
    try {
      await Firebase.initializeApp();
      firebaseInitialized = true;
    } catch (_) {
      // Analytics unavailable — app continues.
    }
  }

  await Hive.initFlutter();
  Hive.registerAdapter(EloRecordAdapter());
  Hive.registerAdapter(QuestionAdapter());
  await Hive.openBox<EloRecord>('elo_history');
  await Hive.openBox('question_cache');
  await Hive.openBox('offline_questions');
  await Hive.openBox(kPrefsBoxName);
  await Hive.openBox('achievements');
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends HookConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp.router(
      title: 'Trivex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: goRouter,
    );
  }
}
