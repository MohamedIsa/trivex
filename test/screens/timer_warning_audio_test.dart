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
  Future<void> dispose() async {}
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
      'timer reaches ≤5s on unanswered question (PlayingPhase) — audio plays once',
      (tester) async {
        final (:container, :player) = await _pumpGame(tester);

        // Verify we're in PlayingPhase.
        expect(
          container.read(gameStateNotifierProvider),
          isA<PlayingPhase>(),
        );

        // Fast-forward 10 seconds — timer is 15s, so 5s remain.
        // This crosses the ≤5s danger zone threshold.
        await tester.pump(const Duration(seconds: 10));
        await tester.pump(const Duration(milliseconds: 100));

        // Audio should have been triggered exactly once.
        expect(player.playCount, 1);

        // Continue pumping — should NOT fire again.
        await tester.pump(const Duration(seconds: 2));
        expect(player.playCount, 1);

        addTearDown(container.dispose);
      },
    );

    testWidgets(
      'question answered before ≤5s — audio NOT played',
      (tester) async {
        final (:container, :player) = await _pumpGame(tester);

        // Advance only 3 seconds (well before the ≤5s threshold).
        await tester.pump(const Duration(seconds: 3));

        // Answer the question — transitions to RevealingPhase.
        await tester.tap(find.text('Alpha'));
        await tester.pump();

        expect(
          container.read(gameStateNotifierProvider),
          isA<RevealingPhase>(),
        );

        // Advance past where the threshold would have been.
        await tester.pump(const Duration(seconds: 10));
        await tester.pump(const Duration(seconds: 5));

        // Audio should never have played.
        expect(player.playCount, 0);

        addTearDown(container.dispose);
      },
    );
  });
}
