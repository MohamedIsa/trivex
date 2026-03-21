import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import 'package:trivex/models/elo_record.dart';
import 'package:trivex/models/game_state.dart';
import 'package:trivex/models/question.dart';
import 'package:trivex/providers/game_state_notifier.dart';
import 'package:trivex/repositories/elo_repository.dart';
import 'package:trivex/screens/game_screen.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Question _q(int i) => Question(
      id: 'q$i',
      question: 'Question $i',
      options: ['Alpha', 'Bravo', 'Charlie', 'Delta'],
      correctIndex: 0,
      explanation: 'Explanation for $i.',
    );

List<Question> _tenQuestions() => List.generate(10, (i) => _q(i + 1));

/// Returns a game state where the player answered correctly (index 0).
GameState _correctRevealState({int currentIndex = 0}) => GameState(
      questions: _tenQuestions(),
      topic: 'Test',
      difficulty: 'medium',
      currentIndex: currentIndex,
      playerScore: 100,
      botScore: 0,
      selectedIndex: 0, // correct index
      isRevealing: true,
      isGameOver: false,
    );

/// Returns a game state where the player answered wrong (index 2).
GameState _wrongRevealState({int currentIndex = 0}) => GameState(
      questions: _tenQuestions(),
      topic: 'Test',
      difficulty: 'medium',
      currentIndex: currentIndex,
      playerScore: 0,
      botScore: 100,
      selectedIndex: 2, // wrong index
      isRevealing: true,
      isGameOver: false,
    );

/// Returns a timeout state (selectedIndex == null).
GameState _timeoutState({int currentIndex = 0}) => GameState(
      questions: _tenQuestions(),
      topic: 'Test',
      difficulty: 'medium',
      currentIndex: currentIndex,
      playerScore: 0,
      botScore: 100,
      selectedIndex: null,
      isRevealing: true,
      isGameOver: false,
    );

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps the full [GameScreen] with a pre-seeded game state using
/// [GameStateNotifier.initGame] + [selectAnswer]/[timeExpired] to reach
/// the desired state.
Future<ProviderContainer> _pumpRevealing(
  WidgetTester tester, {
  required GameState desiredState,
}) async {
  final container = ProviderContainer(
    overrides: [
      gameStateNotifierProvider.overrideWith(GameStateNotifier.new),
    ],
  );

  final notifier = container.read(gameStateNotifierProvider.notifier);
  notifier.initGame(
    desiredState.questions,
    topic: desiredState.topic,
    difficulty: desiredState.difficulty,
  );

  // Advance to the right question index.
  for (var i = 0; i < desiredState.currentIndex; i++) {
    notifier.selectAnswer(0, timeLeft: 5);
    notifier.nextQuestion();
  }

  // Now trigger the reveal for the current question.
  if (desiredState.selectedIndex != null) {
    notifier.selectAnswer(desiredState.selectedIndex!, timeLeft: 5);
  } else {
    notifier.timeExpired();
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/game',
          routes: [
            GoRoute(
              path: '/game',
              builder: (_, _) => const GameScreen(),
            ),
            GoRoute(
              path: '/result',
              builder: (_, _) => const Scaffold(body: Text('route: /result')),
            ),
          ],
        ),
      ),
    ),
  );
  // Let animations run so the bottom sheet slides in.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));

  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    final dir = '/tmp/hive_test_reveal_${DateTime.now().millisecondsSinceEpoch}';
    Hive.init(dir);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EloRecordAdapter());
    }
    await Hive.openBox<EloRecord>(EloRepository.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  setUp(() async {
    final box = Hive.box<EloRecord>(EloRepository.boxName);
    await box.clear();
  });

  group('RevealBottomSheet', () {
    // ── Correct answer → teal icon + "Correct!" heading ───────────────────

    testWidgets(
      'correct answer — "Correct!" heading visible',
      (tester) async {
        await _pumpRevealing(
          tester,
          desiredState: _correctRevealState(),
        );

        expect(find.text('Correct!'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
      },
    );

    // ── Wrong answer → red icon + "Wrong!" heading ────────────────────────

    testWidgets(
      'wrong answer — "Wrong!" heading visible',
      (tester) async {
        await _pumpRevealing(
          tester,
          desiredState: _wrongRevealState(),
        );

        expect(find.text('Wrong!'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      },
    );

    // ── Timeout → "Time's Up!" heading ────────────────────────────────────

    testWidgets(
      'timeout (selectedIndex null) — "Time\'s Up!" heading visible',
      (tester) async {
        await _pumpRevealing(
          tester,
          desiredState: _timeoutState(),
        );

        expect(find.text("Time's Up!"), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      },
    );

    // ── Tap "Next →" → calls nextQuestion ─────────────────────────────────

    testWidgets(
      'tap "Next →" — advances to next question',
      (tester) async {
        final container = await _pumpRevealing(
          tester,
          desiredState: _correctRevealState(currentIndex: 0),
        );

        // Find and tap "Next →".
        await tester.tap(find.text('Next →'));
        // Pump enough for the slide-down animation + state rebuild.
        // We can't use pumpAndSettle because the GameTimer starts a new
        // 15-second animation on the next question.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        final state = container.read(gameStateNotifierProvider);
        // After nextQuestion, currentIndex should advance.
        expect(state.currentIndex, 1);
        expect(state.isRevealing, isFalse);
      },
    );

    // ── Last question → button label is "Results" ─────────────────────────

    testWidgets(
      'last question (index 9) — button label is "Results"',
      (tester) async {
        await _pumpRevealing(
          tester,
          desiredState: _correctRevealState(currentIndex: 9),
        );

        expect(find.text('Results'), findsOneWidget);
        // "Next →" should NOT appear.
        expect(find.text('Next →'), findsNothing);
      },
    );
  });
}
