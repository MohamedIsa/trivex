import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      timeLimit: 15,
    );

/// Question with very long answer options (~80 chars each).
Question _longOptionQ() => Question(
      id: 'qLong',
      question:
          'This is a deliberately verbose question that the AI might produce to test wrapping behaviour',
      options: [
        'A' * 80,
        'B' * 80,
        'C' * 80,
        'D' * 80,
      ],
      correctIndex: 0,
      explanation: 'Long option test.',
      timeLimit: 15,
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
      gameStateNotifierProvider.overrideWith(GameStateNotifier.new),
    ],
  );

  // Seed the notifier's state.
  final notifier = container.read(gameStateNotifierProvider.notifier);
  notifier.initGame(
    state.questions,
    topic: state.topic,
    difficulty: state.difficulty,
  );

  // If the desired state has non-default fields, apply them by calling
  // the relevant notifier methods or by overriding the state directly.
  // For simplicity in tests, we'll just use initGame for the initial state
  // and let the test manipulate via notifier calls.

  final router = GoRouter(
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
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
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

        final state = container.read(gameStateNotifierProvider);
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
        final state = container.read(gameStateNotifierProvider);
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

        final state = container.read(gameStateNotifierProvider);
        expect(state.playerScore, greaterThan(0));

        // The score text should update.
        expect(find.text('You ${state.playerScore}'), findsOneWidget);
      },
    );

    // ── Long answer text — no overflow ──────────────────────────────────

    testWidgets(
      'long answer options (80 chars each) — all 4 tiles render, no overflow',
      (tester) async {
        final longQuestions =
            List.generate(10, (i) => i == 0 ? _longOptionQ() : _q(i + 1));
        final longState = GameState(
          questions: longQuestions,
          topic: 'Test',
          difficulty: 'medium',
          currentIndex: 0,
          playerScore: 0,
          botScore: 0,
          selectedIndex: null,
          isRevealing: false,
          isGameOver: false,
        );

        await _pumpWithState(tester, longState);
        await tester.pump();

        // All 4 badge labels must render (proves all tiles are in the tree).
        expect(find.text('A'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
        expect(find.text('C'), findsOneWidget);
        expect(find.text('D'), findsOneWidget);

        // All 4 long option texts must be present (no clipping / omission).
        expect(find.text('A' * 80), findsOneWidget);
        expect(find.text('B' * 80), findsOneWidget);
        expect(find.text('C' * 80), findsOneWidget);
        expect(find.text('D' * 80), findsOneWidget);
      },
    );

    // ── Haptic feedback — mediumImpact on tap ─────────────────────────────

    testWidgets(
      'tap answer — HapticFeedback.mediumImpact is invoked',
      (tester) async {
        final hapticCalls = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call.arguments as String);
          }
          return null;
        });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        await _pumpWithState(tester, _initialGameState());
        await tester.pump();

        await tester.tap(find.text('Alpha'));
        await tester.pump();

        expect(hapticCalls, contains('HapticFeedbackType.mediumImpact'));
      },
    );

    // ── Shake animation — wrong answer triggers Transform.translate ───────

    testWidgets(
      'wrong answer — shake Transform.translate present during reveal',
      (tester) async {
        // Use a question where correct = 0, then tap index 1 (wrong).
        final container = await _pumpWithState(tester, _initialGameState());
        await tester.pump();

        // Tap the wrong answer 'Bravo' (index 1, correct is 0).
        await tester.tap(find.text('Bravo'));
        await tester.pump();
        // Advance past shake animation start.
        await tester.pump(const Duration(milliseconds: 50));

        final state = container.read(gameStateNotifierProvider);
        expect(state.isRevealing, isTrue);
        expect(state.selectedIndex, 1); // wrong

        // A Transform widget with a non-zero horizontal offset should exist
        // from the shake animation on the selected-wrong tile.
        final transforms = tester
            .widgetList<Transform>(find.byType(Transform))
            .toList();
        final hasHorizontalShake = transforms.any((t) {
          // Transform.translate uses a Matrix4 with [0][3] = dx.
          final dx = t.transform.entry(0, 3);
          return dx != 0.0;
        });
        expect(hasHorizontalShake, isTrue);
      },
    );
  });
}
