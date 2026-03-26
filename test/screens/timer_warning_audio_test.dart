import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import 'package:trivex/models/elo_record.dart';
import 'package:trivex/models/question.dart';
import 'package:trivex/providers/game_state_notifier.dart';
import 'package:trivex/repositories/elo_repository.dart';
import 'package:trivex/screens/game_screen.dart';
import 'package:trivex/services/timer_warning_sound_player.dart';
import 'package:trivex/state/game_phase.dart';

// ---------------------------------------------------------------------------
// Fake — records play() calls without touching audio hardware
// ---------------------------------------------------------------------------

class _FakeSoundPlayer extends TimerWarningSoundPlayer {
  int playCount = 0;

  @override
  void play() => playCount++;

  @override
  Future<void> dispose() async {
    stopTicking();
  }
}

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

List<Question> _tenQuestions() => List.generate(10, (i) => _q(i + 1));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<({ProviderContainer container, _FakeSoundPlayer player})> _pumpGame(
  WidgetTester tester,
) async {
  final fakePlayer = _FakeSoundPlayer();

  final container = ProviderContainer(
    overrides: [
      gameStateNotifierProvider.overrideWith(GameStateNotifier.new),
      timerWarningSoundPlayerProvider.overrideWithValue(fakePlayer),
    ],
  );

  container.read(gameStateNotifierProvider.notifier).initGame(
        _tenQuestions(),
        topic: 'Test',
        difficulty: 'medium',
      );

  final router = GoRouter(
    initialLocation: '/game',
    routes: [
      GoRoute(path: '/game', builder: (_, _) => const GameScreen()),
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

  return (container: container, player: fakePlayer);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    Hive.init(
      '/tmp/hive_test_timer_audio_${DateTime.now().millisecondsSinceEpoch}',
    );
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

  group('TimerWarningAudio', () {
    testWidgets(
      'ticks during PlayingPhase and speeds up in danger zone (≤5s)',
      (tester) async {
        final (:container, :player) = await _pumpGame(tester);

        // Verify we're in PlayingPhase.
        expect(
          container.read(gameStateNotifierProvider),
          isA<PlayingPhase>(),
        );

        // Advance 3 seconds — normal ticking should have occurred.
        await tester.pump(const Duration(seconds: 3));
        final countAfter3s = player.playCount;
        expect(countAfter3s, greaterThan(0));

        // Advance to the danger zone (10s total → 5s remaining).
        final countBeforeDanger = player.playCount;
        await tester.pump(const Duration(seconds: 7));
        await tester.pump(const Duration(milliseconds: 100));
        expect(player.playCount, greaterThan(countBeforeDanger));

        // Continue in danger zone — fast ticking produces more plays.
        final countBeforeFast = player.playCount;
        await tester.pump(const Duration(seconds: 2));
        final fastTicks = player.playCount - countBeforeFast;
        // 2 s at 350 ms interval → ≈ 5-6 ticks.
        expect(fastTicks, greaterThan(3));

        addTearDown(container.dispose);
      },
    );

    testWidgets(
      'ticking stops when question is answered',
      (tester) async {
        final (:container, :player) = await _pumpGame(tester);

        // Advance 3 seconds — normal ticking occurs.
        await tester.pump(const Duration(seconds: 3));
        expect(player.playCount, greaterThan(0));

        // Answer the question — transitions to RevealingPhase.
        await tester.tap(find.text('Alpha'));
        await tester.pump();

        expect(
          container.read(gameStateNotifierProvider),
          isA<RevealingPhase>(),
        );

        // Record count right after answering.
        final countAfterAnswer = player.playCount;

        // Advance more time — ticking should have stopped.
        await tester.pump(const Duration(seconds: 5));
        expect(player.playCount, countAfterAnswer);

        addTearDown(container.dispose);
      },
    );
  });
}
