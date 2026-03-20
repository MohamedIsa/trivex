import 'package:flutter/material.dart';
import '../models/game_config.dart';
import '../models/question.dart';
import '../screens/game_screen.dart';

// ---------------------------------------------------------------------------
// Screen stubs — full implementations live in the UI epic.
// ---------------------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Triv',
                    style: TextStyle(
                      color: Color(0xFFF0EDF8),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'ex',
                    style: TextStyle(
                      color: Color(0xFF00E5C3),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C3AE8),
                foregroundColor: const Color(0xFFF0EDF8),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, '/topic'),
              child: const Text('Play',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class TopicScreen extends StatelessWidget {
  const TopicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A0A2E),
      body: Center(
        child: Text(
          'Topic Screen — stub',
          style: TextStyle(color: Color(0xFFF0EDF8)),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pushReplacementNamed(context, '/topic');
      },
      child: const Scaffold(
        backgroundColor: Color(0xFF1A0A2E),
        body: Center(
          child: Text(
            'Loading Screen — stub',
            style: TextStyle(color: Color(0xFFF0EDF8)),
          ),
        ),
      ),
    );
  }
}

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

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Result Screen — stub',
              style: TextStyle(color: Color(0xFFF0EDF8)),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (r) => false),
              child: const Text('Home',
                  style: TextStyle(color: Color(0xFFA67FF5))),
            ),
          ],
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
