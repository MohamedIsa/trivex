import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivex/models/elo_record.dart';
import 'package:trivex/models/question.dart';
import 'package:trivex/providers/game_state_notifier.dart';
import 'package:trivex/repositories/elo_repository.dart';
import 'package:trivex/services/bot_engine.dart';
import 'package:trivex/state/game_phase.dart';

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

Question _q(int i) => Question(
      id: 'q$i',
      question: 'Question $i',
      options: ['A', 'B', 'C', 'D'],
      correctIndex: 0, // correct answer is always index 0
      explanation: 'Because $i.',
      timeLimit: 15,
    );

List<Question> _tenQuestions() => List.generate(10, (i) => _q(i + 1));

ProviderContainer? _container;

GameStateNotifier _notifier() {
  _container = ProviderContainer();
  return _container!.read(gameStateNotifierProvider.notifier);
}

/// Convenience: extract the [GameRound] from the current [GamePhase].
///
/// Valid for [PlayingPhase], [RevealingPhase], and [FinishedPhase].
GameRound _round(GameStateNotifier n) => switch (n.state) {
      PlayingPhase(:final round) => round,
      RevealingPhase(:final round) => round,
      FinishedPhase(:final round) => round,
      _ => throw StateError('No round in ${n.state.runtimeType}'),
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    Hive.init('/tmp/hive_test_game_state');
    Hive.registerAdapter(EloRecordAdapter());
    await Hive.openBox<EloRecord>(EloRepository.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  setUp(() async {
    final box = Hive.box<EloRecord>(EloRepository.boxName);
    await box.clear();
  });

  tearDown(() {
    _container?.dispose();
    _container = null;
  });

  // ── GameRound immutability / copyWith ─────────────────────────────────────

  group('GameRound.copyWith', () {
    test('returns new instance with overridden fields', () {
      final r = GameRound(
        questions: const [],
        topic: 'test',
        difficulty: 'medium',
        currentIndex: 0,
        playerScore: 0,
        botScore: 0,
      );
      final r2 = r.copyWith(playerScore: 100);

      expect(r2.playerScore, 100);
      expect(r2.botScore, 0); // unchanged
    });
  });

  // ── initGame ──────────────────────────────────────────────────────────────

  group('initGame', () {
    test('loads questions and resets all counters', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'easy');

      expect(notifier.state, isA<PlayingPhase>());
      final round = _round(notifier);
      expect(round.questions.length, 10);
      expect(round.currentIndex, 0);
      expect(round.playerScore, 0);
      expect(round.botScore, 0);
      expect(round.difficulty, 'easy');
    });

    test('resets an in-progress game when called again', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'hard');
      notifier.selectAnswer(0, timeLeft: 15); // correct
      notifier.initGame(_tenQuestions(), difficulty: 'medium');

      expect(notifier.state, isA<PlayingPhase>());
      expect(_round(notifier).playerScore, 0);
    });
  });

  // ── selectAnswer ──────────────────────────────────────────────────────────

  group('selectAnswer', () {
    test('correct answer increments playerScore by at least 100', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 0); // correct index is 0

      expect(notifier.state, isA<RevealingPhase>());
      expect(_round(notifier).playerScore, greaterThanOrEqualTo(100));
    });

    test('correct answer with full time gives speed bonus of 50', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 15); // max speed bonus

      expect(_round(notifier).playerScore, 150);
    });

    test('correct answer with 0 time left gives exactly 100', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 0);

      expect(_round(notifier).playerScore, 100);
    });

    test('wrong answer does NOT increment playerScore', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(3, timeLeft: 15); // wrong — correctIndex is 0

      expect(notifier.state, isA<RevealingPhase>());
      expect(_round(notifier).playerScore, 0);
    });

    test('sets selectedIndex to the tapped index', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(2, timeLeft: 8);

      expect((notifier.state as RevealingPhase).selectedIndex, 2);
    });

    test('second tap while revealing is ignored', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 10);
      final scoreAfterFirst = _round(notifier).playerScore;
      notifier.selectAnswer(1, timeLeft: 10); // should be ignored

      expect(_round(notifier).playerScore, scoreAfterFirst);
      expect((notifier.state as RevealingPhase).selectedIndex, 0);
    });
  });

  // ── nextQuestion ──────────────────────────────────────────────────────────

  group('nextQuestion', () {
    test('advances currentIndex', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 5);
      notifier.nextQuestion();

      expect(notifier.state, isA<PlayingPhase>());
      expect(_round(notifier).currentIndex, 1);
    });

    test('transitions to FinishedPhase after question 10 (index 9)', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');

      // Simulate answering all 10 questions
      for (var i = 0; i < 9; i++) {
        notifier.selectAnswer(0, timeLeft: 5);
        notifier.nextQuestion();
      }
      // Answer final question
      notifier.selectAnswer(0, timeLeft: 5);
      notifier.nextQuestion();

      expect(notifier.state, isA<FinishedPhase>());
    });

    test('stays in PlayingPhase before last question', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 5);
      notifier.nextQuestion();

      expect(notifier.state, isA<PlayingPhase>());
    });

    test(
      'nextQuestion emits exactly one PlayingPhase state',
      () {
        final notifier = _notifier();
        notifier.initGame(_tenQuestions(), difficulty: 'medium');
        notifier.selectAnswer(0, timeLeft: 5);

        // Collect every state emitted during nextQuestion().
        final emissions = <GamePhase>[];
        _container!.listen(
          gameStateNotifierProvider,
          (_, next) => emissions.add(next),
          fireImmediately: false,
        );

        notifier.nextQuestion();

        expect(emissions, hasLength(1), reason: 'exactly one state emission');
        expect(emissions.first, isA<PlayingPhase>());
      },
    );
  });

  // ── timeExpired ───────────────────────────────────────────────────────────

  group('timeExpired', () {
    test('does NOT award player any points', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.timeExpired();

      expect(_round(notifier).playerScore, 0);
    });

    test('transitions to RevealingPhase with selectedIndex null', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.timeExpired();

      expect(notifier.state, isA<RevealingPhase>());
      expect((notifier.state as RevealingPhase).selectedIndex, isNull);
    });

    test('is ignored when already revealing', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 10);
      final scoreBefore = _round(notifier).botScore;
      notifier.timeExpired(); // should be ignored

      // botScore must not increase again
      expect(_round(notifier).botScore, scoreBefore);
    });
  });

  // ── speed bonus edge cases ────────────────────────────────────────────────

  group('speed bonus formula', () {
    test('timeLeft=7 yields round(7/15*50) = 23 bonus pts', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 7);

      expect(_round(notifier).playerScore, 123);
    });
  });

  // ── Bot scoring  ─────────────────────────────────────────────────

  group('bot scoring independence', () {
    setUp(() {
      // Force the bot to always answer correctly (nextDouble returns 0.0).
      BotEngine.debugRandom = _FixedRandom(0.0);
    });

    tearDown(() {
      BotEngine.debugRandom = null; // restore default RNG
    });

    test('player answers wrong → bot still scores', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(3, timeLeft: 10); // wrong — correctIndex is 0

      expect(_round(notifier).playerScore, 0, reason: 'player was wrong');
      expect(_round(notifier).botScore, 100,
          reason: 'bot scored independently');
    });

    test('player times out → bot still scores', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.timeExpired();

      expect(_round(notifier).playerScore, 0, reason: 'timeout gives 0 pts');
      expect(_round(notifier).botScore, 100,
          reason: 'bot scored independently');
    });

    test('player correct AND bot correct → both scores increment', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 15); // correct

      expect(_round(notifier).playerScore, 150,
          reason: '100 base + 50 bonus');
      expect(_round(notifier).botScore, 100, reason: 'bot also scored');
    });
  });
}

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A [Random] that always returns [_fixedValue] from [nextDouble].
class _FixedRandom implements Random {
  _FixedRandom(this._fixedValue);
  final double _fixedValue;

  @override
  double nextDouble() => _fixedValue;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => true;
}
