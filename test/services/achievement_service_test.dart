import 'package:flutter_test/flutter_test.dart';
import 'package:trivex/models/question.dart';
import 'package:trivex/services/achievement_service.dart';
import 'package:trivex/services/elo_service.dart';
import 'package:trivex/state/game_phase.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Question _q(int i) => Question(
      id: 'q$i',
      question: 'Question $i',
      options: ['A', 'B', 'C', 'D'],
      correctIndex: 0,
      explanation: 'Because $i.',
      timeLimit: 15,
    );

/// Builds a finished [GameRound] with configurable tracking data.
GameRound _round({
  int playerScore = 200,
  int botScore = 100,
  String difficulty = 'medium',
  String language = 'en',
  List<bool>? playerCorrect,
  List<int>? answerTimesSeconds,
  int questionCount = 10,
}) {
  return GameRound(
    questions: List.generate(questionCount, (i) => _q(i + 1)),
    topic: 'test',
    difficulty: difficulty,
    language: language,
    currentIndex: questionCount - 1,
    playerScore: playerScore,
    botScore: botScore,
    playerCorrect: playerCorrect ?? List.filled(questionCount, true),
    answerTimesSeconds: answerTimesSeconds ?? List.filled(questionCount, 8),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── first_win ─────────────────────────────────────────────────────────────

  group('first_win', () {
    test('unlocks on first win (player > bot)', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(playerScore: 200, botScore: 100),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 1,
      );
      expect(result, contains('first_win'));
    });

    test('does NOT unlock on a loss', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(playerScore: 50, botScore: 200),
        eloResult: EloService.calculate(1000, false),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 0,
      );
      expect(result, isNot(contains('first_win')));
    });

    test('does NOT unlock on a tie', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(playerScore: 100, botScore: 100),
        eloResult: EloService.calculate(1000, false),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 0,
      );
      expect(result, isNot(contains('first_win')));
    });

    test('is not re-awarded if already unlocked', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(playerScore: 200, botScore: 100),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {'first_win'},
        gamesPlayed: 2,
        winStreak: 2,
      );
      expect(result, isNot(contains('first_win')));
    });
  });

  // ── perfect_round ─────────────────────────────────────────────────────────

  group('perfect_round', () {
    test('unlocks when all answers are correct', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(
          playerCorrect: List.filled(10, true),
        ),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 1,
      );
      expect(result, contains('perfect_round'));
    });

    test('does NOT unlock if any answer is wrong', () {
      final correct = List.filled(10, true)..[4] = false;
      final result = AchievementService.checkNewUnlocks(
        round: _round(playerCorrect: correct),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 1,
      );
      expect(result, isNot(contains('perfect_round')));
    });
  });

  // ── hot_streak ────────────────────────────────────────────────────────────

  group('hot_streak', () {
    test('unlocks at exactly 3 consecutive wins', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(playerScore: 200, botScore: 100),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 3,
        winStreak: 3,
      );
      expect(result, contains('hot_streak'));
    });

    test('does NOT unlock at 2 consecutive wins', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(playerScore: 200, botScore: 100),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 2,
        winStreak: 2,
      );
      expect(result, isNot(contains('hot_streak')));
    });

    test('does NOT unlock when streak is 0 (loss)', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(playerScore: 50, botScore: 200),
        eloResult: EloService.calculate(1000, false),
        alreadyUnlocked: {},
        gamesPlayed: 5,
        winStreak: 0,
      );
      expect(result, isNot(contains('hot_streak')));
    });
  });

  // ── beat_hard ─────────────────────────────────────────────────────────────

  group('beat_hard', () {
    test('unlocks on a win with hard difficulty', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(playerScore: 200, botScore: 100, difficulty: 'hard'),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 1,
      );
      expect(result, contains('beat_hard'));
    });

    test('does NOT unlock on easy difficulty win', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(playerScore: 200, botScore: 100, difficulty: 'easy'),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 1,
      );
      expect(result, isNot(contains('beat_hard')));
    });

    test('does NOT unlock on hard difficulty loss', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(playerScore: 50, botScore: 200, difficulty: 'hard'),
        eloResult: EloService.calculate(1000, false),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 0,
      );
      expect(result, isNot(contains('beat_hard')));
    });
  });

  // ── ten_games ─────────────────────────────────────────────────────────────

  group('ten_games', () {
    test('unlocks at exactly 10 games', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 10,
        winStreak: 1,
      );
      expect(result, contains('ten_games'));
    });

    test('does NOT unlock at 9 games', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 9,
        winStreak: 1,
      );
      expect(result, isNot(contains('ten_games')));
    });
  });

  // ── speed_demon ───────────────────────────────────────────────────────────

  group('speed_demon', () {
    test('unlocks when 5+ answers are under 5 seconds each', () {
      // 6 fast answers (< 5s) and 4 slow ones.
      final times = [2, 3, 4, 1, 3, 2, 10, 12, 8, 9];
      final result = AchievementService.checkNewUnlocks(
        round: _round(answerTimesSeconds: times),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 1,
      );
      expect(result, contains('speed_demon'));
    });

    test('does NOT unlock with only 4 fast answers', () {
      // Exactly 4 fast, 6 slow.
      final times = [2, 3, 4, 1, 8, 10, 12, 9, 7, 6];
      final result = AchievementService.checkNewUnlocks(
        round: _round(answerTimesSeconds: times),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 1,
      );
      expect(result, isNot(contains('speed_demon')));
    });

    test('answers at exactly 5s do NOT count as fast', () {
      // All answers exactly 5 seconds — should NOT qualify (threshold is < 5).
      final times = List.filled(10, 5);
      final result = AchievementService.checkNewUnlocks(
        round: _round(answerTimesSeconds: times),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 1,
      );
      expect(result, isNot(contains('speed_demon')));
    });
  });

  // ── polyglot ──────────────────────────────────────────────────────────────

  group('polyglot', () {
    test('unlocks when language is "ar"', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(language: 'ar'),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 1,
      );
      expect(result, contains('polyglot'));
    });

    test('does NOT unlock for English games', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(language: 'en'),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 1,
      );
      expect(result, isNot(contains('polyglot')));
    });
  });

  // ── centurion ─────────────────────────────────────────────────────────────

  group('centurion', () {
    test('unlocks when new ELO ≥ 1100', () {
      final elo = EloService.calculate(1090, true); // should push above 1100
      final result = AchievementService.checkNewUnlocks(
        round: _round(),
        eloResult: elo,
        alreadyUnlocked: {},
        gamesPlayed: 5,
        winStreak: 1,
      );
      expect(result, contains('centurion'));
    });

    test('does NOT unlock when new ELO < 1100', () {
      final elo = EloService.calculate(1000, true); // newRating = 1016
      final result = AchievementService.checkNewUnlocks(
        round: _round(),
        eloResult: elo,
        alreadyUnlocked: {},
        gamesPlayed: 5,
        winStreak: 1,
      );
      expect(result, isNot(contains('centurion')));
    });
  });

  // ── multiple unlocks in one game ──────────────────────────────────────────

  group('multiple unlocks', () {
    test('first_win + perfect_round + beat_hard can all trigger together', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(
          playerScore: 1500,
          botScore: 100,
          difficulty: 'hard',
          playerCorrect: List.filled(10, true),
        ),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {},
        gamesPlayed: 1,
        winStreak: 1,
      );
      expect(result, containsAll(['first_win', 'perfect_round', 'beat_hard']));
    });
  });

  // ── already-unlocked filtering ────────────────────────────────────────────

  group('already-unlocked filtering', () {
    test('previously unlocked IDs are excluded from results', () {
      final result = AchievementService.checkNewUnlocks(
        round: _round(
          playerCorrect: List.filled(10, true),
          difficulty: 'hard',
        ),
        eloResult: EloService.calculate(1000, true),
        alreadyUnlocked: {'first_win', 'perfect_round', 'beat_hard'},
        gamesPlayed: 1,
        winStreak: 1,
      );
      expect(result, isNot(contains('first_win')));
      expect(result, isNot(contains('perfect_round')));
      expect(result, isNot(contains('beat_hard')));
    });
  });
}
