import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;

/// Simulates a bot opponent that answers questions with difficulty-tuned accuracy.
///
/// Accuracy rates (from the player's perspective):
/// - 'easy'   → bot answers correctly ~40 % of the time (easy to beat)
/// - 'medium' → bot answers correctly ~65 % of the time
/// - 'hard'   → bot answers correctly ~85 % of the time (tough to beat)
class BotEngine {
  BotEngine._(); // non-instantiable

  static Random _random = Random();

  /// Overrides the RNG for deterministic unit tests.
  ///
  /// Reset to `null` in `tearDown` to restore the default [Random].
  @visibleForTesting
  static set debugRandom(Random? rng) => _random = rng ?? Random();

  /// Returns `true` if the bot answered the current question correctly.
  ///
  /// [difficulty] must be one of `'easy'`, `'medium'`, or `'hard'`.
  /// Defaults to the hard rate (85 %) for any unrecognised value.
  static bool didBotAnswer(String difficulty) {
    final threshold = difficulty == 'easy'
        ? 0.40
        : difficulty == 'medium'
            ? 0.65
            : 0.85;
    return _random.nextDouble() < threshold;
  }
}
