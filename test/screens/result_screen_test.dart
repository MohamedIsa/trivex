import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:trivex/models/elo_record.dart';
import 'package:trivex/models/game_config.dart';
import 'package:trivex/models/game_state.dart';
import 'package:trivex/models/question.dart';
import 'package:trivex/providers/elo_history_provider.dart';
import 'package:trivex/providers/game_state_notifier.dart';
import 'package:trivex/repositories/elo_repository.dart';
import 'package:trivex/repositories/question_cache_repository.dart';
import 'package:trivex/screens/result_screen.dart';
import 'package:trivex/services/elo_service.dart';

// ---------------------------------------------------------------------------
// Fakes — no Hive I/O
// ---------------------------------------------------------------------------

/// In-memory [EloRepository] so tests never touch Hive.
class _FakeEloRepository extends EloRepository {
  int _rating = 1000;
  final List<EloRecord> _records = [];

  @override
  int getCurrentRating() => _rating;

  @override
  Future<void> saveResult(EloResult result) async {
    _rating = result.newRating;
    _records.add(
      EloRecord(rating: result.newRating, timestamp: DateTime.now()),
    );
  }

  @override
  List<EloRecord> getHistory() => List.unmodifiable(_records);
}

/// Exposes the protected `state` setter so we can seed an exact [GameState]
/// without playing through 10 questions.
class _SeedableNotifier extends GameStateNotifier {
  _SeedableNotifier(this._seedState);
  final GameState _seedState;

  @override
  GameState build() => _seedState;
}

/// In-memory [QuestionCacheRepository] — stores nothing, avoids Hive.
class _FakeQuestionCacheRepository extends QuestionCacheRepository {
  final Map<String, List<String>> _store = {};

  @override
  List<String> getSeenQuestions(String key) =>
      _store[key] ?? <String>[];

  @override
  Future<void> save(String key, List<String> questions) async {
    _store[key] = [...getSeenQuestions(key), ...questions];
  }
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Question _q(int i) => Question(
      id: 'q$i',
      question: 'Question $i',
      options: ['A', 'B', 'C', 'D'],
      correctIndex: 0,
      explanation: 'Because $i.',
      timeLimit: 15,
    );

List<Question> _tenQuestions() => List.generate(10, (i) => _q(i + 1));

GameState _winState() {
  final elo = EloService.calculate(1000, true);
  return GameState(
    questions: _tenQuestions(),
    topic: 'Test',
    difficulty: 'medium',
    currentIndex: 9,
    playerScore: 500,
    botScore: 200,
    selectedIndex: 0,
    isRevealing: false,
    isGameOver: true,
    eloResult: elo,
  );
}

GameState _loseState() {
  final elo = EloService.calculate(1000, false);
  return GameState(
    questions: _tenQuestions(),
    topic: 'Test',
    difficulty: 'medium',
    currentIndex: 9,
    playerScore: 100,
    botScore: 400,
    selectedIndex: 0,
    isRevealing: false,
    isGameOver: true,
    eloResult: elo,
  );
}

GameState _highScoreState() {
  final elo = EloService.calculate(1000, true);
  return GameState(
    questions: _tenQuestions(),
    topic: 'Test',
    difficulty: 'medium',
    currentIndex: 9,
    playerScore: 1450,
    botScore: 0,
    selectedIndex: 0,
    isRevealing: false,
    isGameOver: true,
    eloResult: elo,
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps [ResultScreen] with the given [state] pre-seeded.
/// Uses a phone-sized surface and fully-faked providers (no Hive).
Future<ProviderContainer> _pumpResultScreen(
  WidgetTester tester, {
  required GameState state,
  void Function(String routeName)? onRoute,
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final fakeRepo = _FakeEloRepository();
  final fakeCacheRepo = _FakeQuestionCacheRepository();

  final container = ProviderContainer(
    overrides: [
      eloRepositoryProvider.overrideWithValue(fakeRepo),
      questionCacheRepositoryProvider.overrideWithValue(fakeCacheRepo),
      gameStateNotifierProvider.overrideWith(() => _SeedableNotifier(state)),
      eloHistoryProvider.overrideWith((_) async => <EloRecord>[]),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/result',
    routes: [
      GoRoute(
        path: '/result',
        builder: (_, _) => const ResultScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) {
          onRoute?.call('/home');
          return const Scaffold(body: Text('route: /home'));
        },
      ),
      GoRoute(
        path: '/topic',
        builder: (_, _) {
          onRoute?.call('/topic');
          return const Scaffold(body: Text('route: /topic'));
        },
      ),
      GoRoute(
        path: '/loading',
        builder: (_, _) {
          onRoute?.call('/loading');
          return const Scaffold(body: Text('route: /loading'));
        },
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  // Walk past the 6 staggered entry animations
  //   Future.delayed(100ms × i) + AnimationController(500ms)
  // Total ≈ 1100ms.  6 × 200ms = 1200ms covers them all.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }

  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ResultScreen', () {
    // ── Player wins → "Victory" label visible ─────────────────────────────

    testWidgets(
      'player wins — "Victory" label visible',
      (tester) async {
        await _pumpResultScreen(tester, state: _winState());

        expect(find.text('Victory'), findsOneWidget);
      },
    );

    // ── Player loses → "Defeat" label visible ─────────────────────────────

    testWidgets(
      'player loses — "Defeat" label visible',
      (tester) async {
        await _pumpResultScreen(tester, state: _loseState());

        expect(find.text('Defeat'), findsOneWidget);
      },
    );

    // ── ELO delta positive → trending_up icon + "+n" text ─────────────────

    testWidgets(
      'ELO delta positive — Icons.trending_up visible',
      (tester) async {
        await _pumpResultScreen(tester, state: _winState());

        expect(find.byIcon(Icons.trending_up), findsOneWidget);
        expect(find.textContaining('+'), findsWidgets);
      },
    );

    // ── Tap "Play Again" → navigates to /loading ──────────────────────────

    testWidgets(
      'tap "Play Again" — navigates to /loading',
      (tester) async {
        String? pushedRoute;

        await _pumpResultScreen(
          tester,
          state: _winState(),
          onRoute: (name) => pushedRoute = name,
        );

        await tester.tap(find.text('Play Again'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(pushedRoute, '/loading');
      },
    );

    // ── Tap "New Topic" → navigates to /topic ─────────────────────────────

    testWidgets(
      'tap "New Topic" — navigates to /topic',
      (tester) async {
        String? pushedRoute;

        await _pumpResultScreen(
          tester,
          state: _winState(),
          onRoute: (name) => pushedRoute = name,
        );

        await tester.tap(find.text('New Topic'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(pushedRoute, '/topic');
      },
    );

    // ── Tap "Home" → navigation stack cleared, at /home ───────────────────

    testWidgets(
      'tap "Home" — navigates to /home',
      (tester) async {
        String? pushedRoute;

        await _pumpResultScreen(
          tester,
          state: _winState(),
          onRoute: (name) => pushedRoute = name,
        );

        await tester.tap(find.text('Home'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(pushedRoute, '/home');
      },
    );

    // ── High score (1450 vs 0) on 360dp screen — no overflow ──────────────

    testWidgets(
      'score 1450 vs 0 on 360dp screen — no RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeRepo = _FakeEloRepository();
        final fakeCacheRepo = _FakeQuestionCacheRepository();
        final state = _highScoreState();

        final container = ProviderContainer(
          overrides: [
            eloRepositoryProvider.overrideWithValue(fakeRepo),
            questionCacheRepositoryProvider.overrideWithValue(fakeCacheRepo),
            gameStateNotifierProvider
                .overrideWith(() => _SeedableNotifier(state)),
            eloHistoryProvider.overrideWith((_) async => <EloRecord>[]),
          ],
        );
        addTearDown(container.dispose);

        final router = GoRouter(
          initialLocation: '/result',
          routes: [
            GoRoute(
              path: '/result',
              builder: (_, _) => const ResultScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }

        // No RenderFlex overflow — test passes if no exceptions were thrown.
        expect(find.text('1450'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
      },
    );

    // ── Tap "New Topic" → go() clears stack, location is /topic ─────────

    testWidgets(
      'tap "New Topic" — go() clears stack, location is /topic',
      (tester) async {
        final router = await _pumpWithRouter(tester, state: _winState());

        await tester.tap(find.text('New Topic'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // go('/topic') cleared the entire game stack.
        expect(find.text('route: /topic'), findsOneWidget);

        // No stale game routes remain — canPop is false (only /topic).
        expect(router.canPop(), isFalse);
      },
    );

    // ── Tap "Play Again" → /loading with correct GameConfig ───────────────

    testWidgets(
      'tap "Play Again" — location is /loading with correct GameConfig extra',
      (tester) async {
        Object? capturedExtra;

        await _pumpWithRouter(
          tester,
          state: _winState(),
          onLoadingExtra: (extra) => capturedExtra = extra,
        );

        await tester.tap(find.text('Play Again'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Location is /loading.
        expect(find.text('route: /loading'), findsOneWidget);

        // GameConfig extra matches the game state.
        expect(capturedExtra, isA<GameConfig>());
        final config = capturedExtra! as GameConfig;
        expect(config.topic, 'Test');
        expect(config.difficulty, 'medium');
        expect(config.count, 10);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// _pumpWithRouter — returns GoRouter for stack-depth assertions
// ---------------------------------------------------------------------------

Future<GoRouter> _pumpWithRouter(
  WidgetTester tester, {
  required GameState state,
  void Function(Object? extra)? onLoadingExtra,
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final fakeRepo = _FakeEloRepository();
  final fakeCacheRepo = _FakeQuestionCacheRepository();

  final container = ProviderContainer(
    overrides: [
      eloRepositoryProvider.overrideWithValue(fakeRepo),
      questionCacheRepositoryProvider.overrideWithValue(fakeCacheRepo),
      gameStateNotifierProvider.overrideWith(() => _SeedableNotifier(state)),
      eloHistoryProvider.overrideWith((_) async => <EloRecord>[]),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/result',
    routes: [
      GoRoute(
        path: '/result',
        builder: (_, _) => const ResultScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('route: /home')),
      ),
      GoRoute(
        path: '/topic',
        builder: (_, _) => const Scaffold(body: Text('route: /topic')),
      ),
      GoRoute(
        path: '/loading',
        builder: (_, routeState) {
          onLoadingExtra?.call(routeState.extra);
          return const Scaffold(body: Text('route: /loading'));
        },
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  // Walk past the 6 staggered entry animations.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }

  return router;
}
