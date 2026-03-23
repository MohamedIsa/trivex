import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/router.dart';
import 'models/elo_record.dart';
import 'models/question.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(EloRecordAdapter());
  Hive.registerAdapter(QuestionAdapter());
  await Hive.openBox<EloRecord>('elo_history');
  await Hive.openBox('question_cache');
  await Hive.openBox('offline_questions');
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Trivex',
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter,
    );
  }
}
