import '../services/elo_service.dart';
import '../state/game_phase.dart';

/// Pure, stateless achievement-condition checker.
///
/// Returns the list of achievement IDs that should be newly unlocked for
/// the just-completed game.  Callers are responsible for persisting via
/// [AchievementRepository.unlock].
class AchievementService {
  AchievementService._(); // non-instantiable

  /// Minimum number of fast answers required for **speed_demon**.
  static const int kSpeedDemonCount = 5;

  /// Maximum seconds per answer to qualify as "fast" for **speed_demon**.
  static const int kSpeedDemonThreshold = 5;

  /// Minimum ELO for the **centurion** achievement.
  static const int kCenturionElo = 1100;

  /// Minimum consecutive wins for the **hot_streak** achievement.
  static const int kHotStreakWins = 3;

  /// Minimum total games for the **ten_games** achievement.
  static const int kVeteranGames = 10;

  /// Returns IDs of achievements that should be unlocked for the
  /// just-finished game.
  ///
  /// [round] — the completed [GameRound] with per-question tracking.
  /// [eloResult] — the ELO calculation result for this game.
  /// [alreadyUnlocked] — achievement IDs already persisted.
  /// [gamesPlayed] — total games completed **including** this one.
  /// [winStreak] — consecutive wins **including** this game (0 if loss/tie).
  static List<String> checkNewUnlocks({
    required GameRound round,
    required EloResult eloResult,
    required Set<String> alreadyUnlocked,
    required int gamesPlayed,
    required int winStreak,
  }) {
    final newUnlocks = <String>[];
    final isWin = round.playerScore > round.botScore;

    // first_win — Win a game for the first time.
    if (isWin && !alreadyUnlocked.contains('first_win')) {
      newUnlocks.add('first_win');
    }

    // perfect_round — All answers correct in one game.
    if (round.playerCorrect.isNotEmpty &&
        round.playerCorrect.every((c) => c) &&
        !alreadyUnlocked.contains('perfect_round')) {
      newUnlocks.add('perfect_round');
    }

    // hot_streak — Win 3 games in a row.
    if (winStreak >= kHotStreakWins &&
        !alreadyUnlocked.contains('hot_streak')) {
      newUnlocks.add('hot_streak');
    }

    // beat_hard — Beat the bot on Hard difficulty.
    if (isWin &&
        round.difficulty == 'hard' &&
        !alreadyUnlocked.contains('beat_hard')) {
      newUnlocks.add('beat_hard');
    }

    // ten_games — Complete 10 games total.
    if (gamesPlayed >= kVeteranGames &&
        !alreadyUnlocked.contains('ten_games')) {
      newUnlocks.add('ten_games');
    }

    // speed_demon — 5+ answers under 5 seconds each in one game.
    if (round.answerTimesSeconds
                .where((t) => t < kSpeedDemonThreshold)
                .length >=
            kSpeedDemonCount &&
        !alreadyUnlocked.contains('speed_demon')) {
      newUnlocks.add('speed_demon');
    }

    // polyglot — Game language detected as "ar".
    if (round.language == 'ar' &&
        !alreadyUnlocked.contains('polyglot')) {
      newUnlocks.add('polyglot');
    }

    // centurion — New ELO ≥ 1100.
    if (eloResult.newRating >= kCenturionElo &&
        !alreadyUnlocked.contains('centurion')) {
      newUnlocks.add('centurion');
    }

    return newUnlocks;
  }
}
