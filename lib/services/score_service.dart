/// Pure scoring logic — extracted from [GameStateNotifier.selectAnswer].
///
/// Base: 100 pts for a correct answer.
/// Speed bonus: up to 50 pts, proportional to remaining time.
class ScoreService {
  /// Returns the points earned for a single question.
  ///
  /// [isCorrect] — whether the player chose the right option.
  /// [timeRemainingSeconds] — seconds left on the timer (0–[timeLimitSeconds]).
  /// [timeLimitSeconds] — the question's time limit (default 15).
  ///
  /// Formula: `100 + (timeRemainingSeconds / timeLimitSeconds * 50).round()`
  /// if correct, else `0`.
  static int calculatePoints(
    bool isCorrect,
    double timeRemainingSeconds, {
    double timeLimitSeconds = 15,
  }) {
    if (!isCorrect) return 0;
    return 100 + (timeRemainingSeconds / timeLimitSeconds * 50).round();
  }
}
