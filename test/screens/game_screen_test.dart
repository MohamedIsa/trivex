import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:trivex/models/elo_record.dart';
import 'package:trivex/models/game_state.dart';
import 'package:trivex/models/question.dart';
import 'package:trivex/providers/game_state_notifier.dart';
import 'package:trivex/repositories/elo_repository.dart';
import 'package:trivex/screens/game_screen.dart';
import 'package:trivex/widgets/reveal_bottom_sheet.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Question _q(int i) => Question(
      id: 'q$i',
      question: 'Question $i',
      options: ['Alpha', 'Bravo', 'Charlie', 'Delta'],
      correctIndex: 0,
      explanation: 'Because $i.',
    );

List<Question> _tenQuestions() => List.generate(10, (i) => _q(i + 1));

GameState _initialGameState() => GameState(
      questions: _tenQuestions(),
      topic: 'Test',
      difficulty: 'medium',
      currentIndex: 0,
      playerScore: 0,
      botScore: 0,
      selectedIndex: null,
      isRevealing: false,
      isGameOver: false,
    );

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps [GameScreen] with a pre-seeded notifier — override the StateNotifierProvider with a pre-seeded
/// notifier.
Future<ProviderContainer> _pumpWithState(
  WidgetTester tester,
  GameState state,
) async {
  final container = ProviderContainer(
    overrides: [
      gameStateProvider.overrideWith((ref) {
        final notifier = GameStateNotifier(EloRepository());
        return notifier;
      }),
    ],
  );

  // Seed the notifier's state.
  final notifier = container.read(gameStateProvider.notifier);
  notifier.initGame(
    state.questions,
    topic: state.topic,
    difficulty: state.difficulty,
  );

  // If the desired state has non-default fields, apply them by calling
  // the relevant notifier methods or by overriding the state directly.
  // For simplicity in tests, we'll just use initGame for the initial state
  // and let the test manipulate via notifier calls.

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: const GameScreen(),
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => Scaffold(body: Text('route: ${settings.name}')),
          );
        },
      ),
    ),
  );
  await tester.pump();

  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    Hive.init('/tmp/hive_test_game_screen_${DateTime.now().millisecondsSinceEpoch}');
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

  group('GameScreen', () {
    // ── Initial state — question text, 4 tiles, score row ─────────────────

    testWidgets(
      'initial state — question text, 4 answer tiles, score "You 0 · Bot 0"',
      (tester) async {
        await _pumpWithState(tester, _initialGameState());
        await tester.pump();

        // Question text visible.
        expect(find.text('Question 1'), findsOneWidget);

        // 4 answer tiles (each has a label letter: A, B, C, D).
        expect(find.text('A'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
        expect(find.text('C'), findsOneWidget);
        expect(find.text('D'), findsOneWidget);

        // Score row.
        expect(find.text('You 0'), findsOneWidget);
        expect(find.text('Bot 0'), findsOneWidget);
      },
    );

    // ── Tap answer tile A → selectAnswer called ───────────────────────────

    testWidgets(
      'tap answer tile A — selectAnswer called, isRevealing becomes true',
      (tester) async {
        final container = await _pumpWithState(tester, _initialGameState());
        await tester.pump();

        // Tap the first answer option text 'Alpha'.
        await tester.tap(find.text('Alpha'));
        await tester.pump();

        final state = container.read(gameStateProvider);
        expect(state.selectedIndex, 0);
        expect(state.isRevealing, isTrue);
      },
    );

    // ── Revealing state — IgnorePointer active, RevealBottomSheet visible ─

    testWidgets(
      'revealing state — tiles are IgnorePointer, RevealBottomSheet visible',
      (tester) async {
        final container = await _pumpWithState(tester, _initialGameState());
        await tester.pump();

        // Trigger reveal by tapping an answer.
        await tester.tap(find.text('Alpha'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Verify the state IS revealing.
        final state = container.read(gameStateProvider);
        expect(state.isRevealing, isTrue);

        // The IgnorePointer wrapping the ListView should have ignoring=true.
        // Walk the IgnorePointer widgets and find the one with ignoring=true.
        final allIgnore = tester
            .widgetList<IgnorePointer>(find.byType(IgnorePointer))
            .toList();
        final hasIgnoring = allIgnore.any((w) => w.ignoring);
        expect(hasIgnoring, isTrue);

        // RevealBottomSheet widget should be in the tree.
        expect(find.byType(RevealBottomSheet), findsOneWidget);
      },
    );

    // ── Score row updates on new state ────────────────────────────────────

    testWidgets(
      'score row updates when state emits new playerScore',
      (tester) async {
        final container = await _pumpWithState(tester, _initialGameState());
        await tester.pump();

        // Initial score.
        expect(find.text('You 0'), findsOneWidget);

        // Tap correct answer (index 0) to get some points.
        await tester.tap(find.text('Alpha'));
        await tester.pump();

        final state = container.read(gameStateProvider);
        expect(state.playerScore, greaterThan(0));

        // The score text should update.
        expect(find.text('You ${state.playerScore}'), findsOneWidget);
      },
    );
  });
}
