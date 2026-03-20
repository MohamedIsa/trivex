import 'package:flutter/material.dart';
import '../models/game_config.dart';
import '../models/question.dart';
import '../screens/game_screen.dart';
import '../screens/home_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/result_screen.dart';
import '../screens/topic_screen.dart';

// ---------------------------------------------------------------------------
// Screen stubs — full implementations live in the UI epic.
// ---------------------------------------------------------------------------







class RevealScreen extends StatelessWidget {
  const RevealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A0A2E),
      body: Center(
        child: Text(
          'Reveal Screen — stub',
          style: TextStyle(color: Color(0xFFF0EDF8)),
        ),
      ),
    );
  }
}



// ---------------------------------------------------------------------------
// Route generator — parse arguments for type-safe navigation.
// ---------------------------------------------------------------------------

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/home':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const HomeScreen(),
      );

    case '/topic':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const TopicScreen(),
      );

    case '/loading':
      // Expects: RouteSettings.arguments = GameConfig
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const LoadingScreen(),
      );

    case '/game':
      // Expects: RouteSettings.arguments = List<Question>
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const GameScreen(),
      );

    case '/reveal':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const RevealScreen(),
      );

    case '/result':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const ResultScreen(),
      );

    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFF1A0A2E),
          body: Center(
            child: Text(
              '404 — ${settings.name} not found',
              style: const TextStyle(color: Color(0xFFE84747)),
            ),
          ),
        ),
      );
  }
}

/// Helper to cast route arguments safely.
GameConfig? routeArgAsGameConfig(BuildContext context) {
  final args = ModalRoute.of(context)?.settings.arguments;
  if (args is GameConfig) return args;
  return null;
}

List<Question>? routeArgAsQuestions(BuildContext context) {
  final args = ModalRoute.of(context)?.settings.arguments;
  if (args is List<Question>) return args;
  return null;
}
