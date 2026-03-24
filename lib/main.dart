import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app/router.dart';
import 'models/elo_record.dart';
import 'models/question.dart';
import 'providers/theme_mode_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase — initialise only in release/profile builds.
  // In debug mode or when google-services.json / GoogleService-Info.plist
  // are missing, analytics is a no-op (see AnalyticsService).
  if (!kDebugMode) {
    await Firebase.initializeApp();
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
