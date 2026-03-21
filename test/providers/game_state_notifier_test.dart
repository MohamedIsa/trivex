import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivex/models/elo_record.dart';
import 'package:trivex/models/game_state.dart';
import 'package:trivex/models/question.dart';
import 'package:trivex/providers/game_state_notifier.dart';
import 'package:trivex/repositories/elo_repository.dart';
import 'package:trivex/services/bot_engine.dart';

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

Question _q(int i) => Question(
      id: 'q$i',
      question: 'Question $i',
      options: ['A', 'B', 'C', 'D'],
      correctIndex: 0, // correct answer is always index 0
      explanation: 'Because $i.',
    );

List<Question> _tenQuestions() => List.generate(10, (i) => _q(i + 1));

ProviderContainer? _container;

GameStateNotifier _notifier() {
  _container = ProviderContainer();
  return _container!.read(gameStateNotifierProvider.notifier);
}

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
  // ── GameState immutability / copyWith ─────────────────────────────────────

  group('GameState.copyWith', () {
    test('returns new instance with overridden fields', () {
      const s = GameState.empty;
      final s2 = s.copyWith(playerScore: 100, isRevealing: true);

      expect(s2.playerScore, 100);
      expect(s2.isRevealing, isTrue);
      expect(s2.botScore, 0); // unchanged
    });

    test('copyWith(selectedIndex: null) clears selectedIndex', () {
      final s = GameState(
        questions: const [],
        topic: 'test',
        difficulty: 'easy',
        currentIndex: 0,
        playerScore: 0,
        botScore: 0,
        selectedIndex: 2,
        isRevealing: false,
        isGameOver: false,
      );
      final s2 = s.copyWith(selectedIndex: null);
      expect(s2.selectedIndex, isNull);
    });
  });

  // ── initGame ──────────────────────────────────────────────────────────────

  group('initGame', () {
    test('loads questions and resets all counters', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'easy');
      final s = notifier.state;

      expect(s.questions.length, 10);
      expect(s.currentIndex, 0);
      expect(s.playerScore, 0);
      expect(s.botScore, 0);
      expect(s.selectedIndex, isNull);
      expect(s.isRevealing, isFalse);
      expect(s.isGameOver, isFalse);
      expect(s.difficulty, 'easy');
    });

    test('resets an in-progress game when called again', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'hard');
      notifier.selectAnswer(0, timeLeft: 15); // correct
      notifier.initGame(_tenQuestions(), difficulty: 'medium');

      expect(notifier.state.playerScore, 0);
      expect(notifier.state.isRevealing, isFalse);
    });
  });

  // ── selectAnswer ──────────────────────────────────────────────────────────

  group('selectAnswer', () {
    test('correct answer increments playerScore by at least 100', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 0); // correct index is 0

      expect(notifier.state.playerScore, greaterThanOrEqualTo(100));
      expect(notifier.state.isRevealing, isTrue);
    });

    test('correct answer with full time gives speed bonus of 50', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 15); // max speed bonus

      expect(notifier.state.playerScore, 150);
    });

    test('correct answer with 0 time left gives exactly 100', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 0);

      expect(notifier.state.playerScore, 100);
    });

    test('wrong answer does NOT increment playerScore', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(3, timeLeft: 15); // wrong — correctIndex is 0

      expect(notifier.state.playerScore, 0);
      expect(notifier.state.isRevealing, isTrue);
    });

    test('sets selectedIndex to the tapped index', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(2, timeLeft: 8);

      expect(notifier.state.selectedIndex, 2);
    });

    test('second tap while isRevealing is ignored', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 10);
      final scoreAfterFirst = notifier.state.playerScore;
      notifier.selectAnswer(1, timeLeft: 10); // should be ignored

      expect(notifier.state.playerScore, scoreAfterFirst);
      expect(notifier.state.selectedIndex, 0);
    });
  });

  // ── nextQuestion ──────────────────────────────────────────────────────────

  group('nextQuestion', () {
    test('advances currentIndex', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 5);
      notifier.nextQuestion();

      expect(notifier.state.currentIndex, 1);
      expect(notifier.state.isRevealing, isFalse);
      expect(notifier.state.selectedIndex, isNull);
    });

    test('sets isGameOver = true after question 10 (index 9)', () {
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

      expect(notifier.state.isGameOver, isTrue);
    });

    test('isGameOver is false before last question', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 5);
      notifier.nextQuestion();

      expect(notifier.state.isGameOver, isFalse);
    });
  });

  // ── timeExpired ───────────────────────────────────────────────────────────

  group('timeExpired', () {
    test('does NOT award player any points', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.timeExpired();

      expect(notifier.state.playerScore, 0);
    });

    test('sets isRevealing = true and selectedIndex stays null', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.timeExpired();

      expect(notifier.state.isRevealing, isTrue);
      expect(notifier.state.selectedIndex, isNull);
    });

    test('is ignored when isRevealing is already true', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 10);
      final scoreBefore = notifier.state.botScore;
      notifier.timeExpired(); // should be ignored

      // botScore must not increase again
      expect(notifier.state.botScore, scoreBefore);
    });
  });

  // ── speed bonus edge cases ────────────────────────────────────────────────

  group('speed bonus formula', () {
    test('timeLeft=7 yields round(7/15*50) = 23 bonus pts', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 7);

      expect(notifier.state.playerScore, 123);
    });
  });

  // ── Bot scoring (BUG-001) ─────────────────────────────────────────────────

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

      expect(notifier.state.playerScore, 0, reason: 'player was wrong');
      expect(notifier.state.botScore, 100, reason: 'bot scored independently');
    });

    test('player times out → bot still scores', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.timeExpired();

      expect(notifier.state.playerScore, 0, reason: 'timeout gives 0 pts');
      expect(notifier.state.botScore, 100, reason: 'bot scored independently');
    });

    test('player correct AND bot correct → both scores increment', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 15); // correct

      expect(notifier.state.playerScore, 150, reason: '100 base + 50 bonus');
      expect(notifier.state.botScore, 100, reason: 'bot also scored');
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
