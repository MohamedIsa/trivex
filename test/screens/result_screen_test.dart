import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:trivex/models/achievement.dart';
import 'package:trivex/models/elo_record.dart';
import 'package:trivex/models/game_config.dart';
import 'package:trivex/models/question.dart';
import 'package:trivex/providers/elo_history_provider.dart';
import 'package:trivex/providers/game_state_notifier.dart';
import 'package:trivex/repositories/achievement_repository.dart';
import 'package:trivex/repositories/elo_repository.dart';
import 'package:trivex/repositories/question_cache_repository.dart';
import 'package:trivex/screens/result_screen.dart';
import 'package:trivex/services/elo_service.dart';
import 'package:trivex/state/game_phase.dart';

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

/// Exposes the protected `state` setter so we can seed an exact [GamePhase]
/// without playing through 10 questions.
class _SeedableNotifier extends GameStateNotifier {
  _SeedableNotifier(this._seedPhase);
  final GamePhase _seedPhase;

  @override
  GamePhase build() => _seedPhase;
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

/// In-memory [AchievementRepository] — avoids Hive.
/// Pre-populated with all achievements unlocked so no SnackBar toasts fire
/// during existing ResultScreen tests.
class _FakeAchievementRepository extends AchievementRepository {
  final Set<String> _unlocked = {
    'first_win',
    'perfect_round',
    'hot_streak',
    'beat_hard',
    'ten_games',
    'speed_demon',
    'polyglot',
    'centurion',
  };
  final Map<String, DateTime> _dates = {};
  int _winStreak = 0;
  int _gamesPlayed = 0;

  @override
  Set<String> getUnlocked() => Set.of(_unlocked);

  @override
  Future<void> unlock(String id) async {
    if (_unlocked.add(id)) _dates[id] = DateTime.now();
  }

  @override
  DateTime? getUnlockDate(String id) => _dates[id];

  @override
  int getWinStreak() => _winStreak;

  @override
  Future<void> setWinStreak(int streak) async => _winStreak = streak;

  @override
  int getGamesPlayed() => _gamesPlayed;

  @override
  Future<void> incrementGamesPlayed() async => _gamesPlayed++;
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

GamePhase _winState() {
  final elo = EloService.calculate(1000, true);
  return GamePhase.finished(
    round: GameRound(
      questions: _tenQuestions(),
      topic: 'Test',
      difficulty: 'medium',
      currentIndex: 9,
      playerScore: 500,
      botScore: 200,
    ),
    eloResult: elo,
  );
}

GamePhase _loseState() {
  final elo = EloService.calculate(1000, false);
  return GamePhase.finished(
    round: GameRound(
      questions: _tenQuestions(),
      topic: 'Test',
      difficulty: 'medium',
      currentIndex: 9,
      playerScore: 100,
      botScore: 400,
    ),
    eloResult: elo,
  );
}

GamePhase _highScoreState() {
  final elo = EloService.calculate(1000, true);
  return GamePhase.finished(
    round: GameRound(
      questions: _tenQuestions(),
      topic: 'Test',
      difficulty: 'medium',
      currentIndex: 9,
      playerScore: 1450,
      botScore: 0,
    ),
    eloResult: elo,
  );
}

GamePhase _drawState() {
  final elo = EloService.calculate(1000, true);
  return GamePhase.finished(
    round: GameRound(
      questions: _tenQuestions(),
      topic: 'Test',
      difficulty: 'medium',
      currentIndex: 9,
      playerScore: 300,
      botScore: 300,
    ),
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
  required GamePhase state,
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
  final fakeAchieveRepo = _FakeAchievementRepository();

  final container = ProviderContainer(
    overrides: [
      eloRepositoryProvider.overrideWithValue(fakeRepo),
      questionCacheRepositoryProvider.overrideWithValue(fakeCacheRepo),
      achievementRepositoryProvider.overrideWithValue(fakeAchieveRepo),
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
        final fakeAchieveRepo = _FakeAchievementRepository();
        final state = _highScoreState();

        final container = ProviderContainer(
          overrides: [
            eloRepositoryProvider.overrideWithValue(fakeRepo),
            questionCacheRepositoryProvider.overrideWithValue(fakeCacheRepo),
            achievementRepositoryProvider.overrideWithValue(fakeAchieveRepo),
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

    // ── Confetti fires on win ─────────────────────────────────────────────

    testWidgets(
      'player wins — ConfettiWidget is in the tree',
      (tester) async {
        await _pumpResultScreen(tester, state: _winState());

        expect(find.byType(ConfettiWidget), findsOneWidget);
      },
    );

    // ── No confetti on loss ───────────────────────────────────────────────

    testWidgets(
      'player loses — no ConfettiWidget in the tree',
      (tester) async {
        await _pumpResultScreen(tester, state: _loseState());

        expect(find.byType(ConfettiWidget), findsNothing);
      },
    );

    // ── No confetti on draw ───────────────────────────────────────────────

    testWidgets(
      'draw — no ConfettiWidget in the tree',
      (tester) async {
        await _pumpResultScreen(tester, state: _drawState());

        expect(find.byType(ConfettiWidget), findsNothing);
      },
    );

    // ── Score counter starts at 0, reaches final value after animation ────

    testWidgets(
      'score counter animates from 0 to final value',
      (tester) async {
        await _pumpResultScreen(tester, state: _winState());

        // After full stagger + score animation, we should see final scores.
        // Advance past the score counter animation (800ms).
        await tester.pump(const Duration(milliseconds: 900));

        // Final scores should be visible.
        expect(find.text('500'), findsOneWidget);
        expect(find.text('200'), findsOneWidget);
      },
    );
  });

  _achievementDialogTests();
}

// ---------------------------------------------------------------------------
// _pumpWithRouter — returns GoRouter for stack-depth assertions
// ---------------------------------------------------------------------------

Future<GoRouter> _pumpWithRouter(
  WidgetTester tester, {
  required GamePhase state,
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
  final fakeAchieveRepo = _FakeAchievementRepository();

  final container = ProviderContainer(
    overrides: [
      eloRepositoryProvider.overrideWithValue(fakeRepo),
      questionCacheRepositoryProvider.overrideWithValue(fakeCacheRepo),
      achievementRepositoryProvider.overrideWithValue(fakeAchieveRepo),
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

// ---------------------------------------------------------------------------
// Achievement dialog tests — helpers
// ---------------------------------------------------------------------------

/// In-memory repo with NO achievements unlocked — triggers real unlock logic.
class _EmptyAchievementRepository extends AchievementRepository {
  final Set<String> _unlocked = {};
  final Map<String, DateTime> _dates = {};
  int _winStreak = 0;
  int _gamesPlayed = 0;

  @override
  Set<String> getUnlocked() => Set.of(_unlocked);

  @override
  Future<void> unlock(String id) async {
    if (_unlocked.add(id)) _dates[id] = DateTime.now();
  }

  @override
  DateTime? getUnlockDate(String id) => _dates[id];

  @override
  int getWinStreak() => _winStreak;

  @override
  Future<void> setWinStreak(int streak) async => _winStreak = streak;

  @override
  int getGamesPlayed() => _gamesPlayed;

  @override
  Future<void> incrementGamesPlayed() async => _gamesPlayed++;
}

/// Pumps [ResultScreen] with an empty achievement repository so real
/// achievement dialogs can trigger.
Future<void> _pumpWithAchievements(
  WidgetTester tester, {
  required GamePhase state,
  AchievementRepository? achievementRepo,
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final fakeRepo = _FakeEloRepository();
  final fakeCacheRepo = _FakeQuestionCacheRepository();
  final fakeAchieveRepo = achievementRepo ?? _EmptyAchievementRepository();

  final container = ProviderContainer(
    overrides: [
      eloRepositoryProvider.overrideWithValue(fakeRepo),
      questionCacheRepositoryProvider.overrideWithValue(fakeCacheRepo),
      achievementRepositoryProvider.overrideWithValue(fakeAchieveRepo),
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
        builder: (_, _) => const Scaffold(body: Text('route: /loading')),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  // Walk past staggered entry animations.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

// ---------------------------------------------------------------------------
// Achievement dialog tests
// ---------------------------------------------------------------------------

void _achievementDialogTests() {
  group('Achievement dialog', () {
    testWidgets(
      'single achievement unlocked — dialog shown with correct name',
      (tester) async {
        // Win state triggers first_win achievement.
        await _pumpWithAchievements(tester, state: _winState());

        // Advance past the 500ms delay before showing the dialog.
        await tester.pump(const Duration(milliseconds: 600));
        // Let the dialog animation settle (avoid pumpAndSettle due to
        // confetti controller keeping the tree alive).
        await tester.pump(const Duration(milliseconds: 300));

        // Dialog heading and achievement name visible.
        expect(find.text('Achievement Unlocked!'), findsOneWidget);

        final firstWin = kAchievements.firstWhere((a) => a.id == 'first_win');
        expect(find.text(firstWin.name), findsOneWidget);
        expect(find.text(firstWin.hint), findsOneWidget);
        expect(find.text('Awesome!'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping "Awesome!" dismisses the dialog',
      (tester) async {
        await _pumpWithAchievements(tester, state: _winState());

        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 300));

        // Dialog is showing.
        expect(find.text('Achievement Unlocked!'), findsOneWidget);

        // Tap dismiss.
        await tester.tap(find.text('Awesome!'));
        // Let the dialog close animation complete.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Dialog dismissed.
        expect(find.text('Achievement Unlocked!'), findsNothing);
      },
    );

    testWidgets(
      'no achievements — no dialog shown',
      (tester) async {
        // Use the fully-unlocked repo so nothing new triggers.
        await _pumpWithAchievements(
          tester,
          state: _winState(),
          achievementRepo: _FakeAchievementRepository(),
        );

        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 300));

        // No dialog.
        expect(find.text('Achievement Unlocked!'), findsNothing);
      },
    );
  });
}
