import 'dart:math';

/// Simulates a bot opponent that answers questions with difficulty-tuned accuracy.
///
/// Accuracy rates:
/// - 'easy'   → 85 %
/// - 'medium' → 65 %
/// - 'hard'   → 40 %
class BotEngine {
  BotEngine._(); // non-instantiable

  static final _random = Random();

  /// Returns `true` if the bot answered the current question correctly.
  ///
  /// [difficulty] must be one of `'easy'`, `'medium'`, or `'hard'`.
  /// Defaults to the hard rate (40 %) for any unrecognised value.
  static bool didBotAnswer(String difficulty) {
    final threshold = difficulty == 'easy'
        ? 0.85
        : difficulty == 'medium'
            ? 0.65
            : 0.40;
    return _random.nextDouble() < threshold;
  }
}
