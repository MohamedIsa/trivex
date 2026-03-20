import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivex/models/elo_record.dart';
import 'package:trivex/models/game_state.dart';
import 'package:trivex/models/question.dart';
import 'package:trivex/providers/game_state_notifier.dart';
import 'package:trivex/repositories/elo_repository.dart';

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

late EloRepository _eloRepo;

GameStateNotifier _notifier() => GameStateNotifier(_eloRepo);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    Hive.init('/tmp/hive_test_game_state');
    Hive.registerAdapter(EloRecordAdapter());
    await Hive.openBox<EloRecord>(EloRepository.boxName);
    _eloRepo = EloRepository();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  setUp(() async {
    final box = Hive.box<EloRecord>(EloRepository.boxName);
    await box.clear();
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

    test('clearSelectedIndex sets selectedIndex to null', () {
      const s = GameState(
        questions: [],
        difficulty: 'easy',
        currentIndex: 0,
        playerScore: 0,
        botScore: 0,
        selectedIndex: 2,
        isRevealing: false,
        isGameOver: false,
      );
      final s2 = s.copyWith(clearSelectedIndex: true);
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
    test('timeLeft=7 yields floor(7/15*50) = 23 bonus pts', () {
      final notifier = _notifier();
      notifier.initGame(_tenQuestions(), difficulty: 'medium');
      notifier.selectAnswer(0, timeLeft: 7);

      expect(notifier.state.playerScore, 123);
    });
  });
}
