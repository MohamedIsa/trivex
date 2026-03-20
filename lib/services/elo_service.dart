import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../constants/game_constants.dart';

part 'elo_service.freezed.dart';

/// Result of an ELO recalculation after a round.
@freezed
class EloResult with _$EloResult {
  const factory EloResult({
    required int newRating,
    required int delta,
  }) = _EloResult;
}

/// Stateless service that computes ELO rating changes using the standard
/// chess formula with K = 32 and a fixed bot rating of [kBotElo].
class EloService {
  EloService._(); // non-instantiable

  static const int _k = 32;

  /// Returns the new rating and delta for the player.
  ///
  /// [playerRating] — current ELO rating.
  /// [playerWon] — `true` if `playerScore > botScore`.
  static EloResult calculate(int playerRating, bool playerWon) {
    final expected =
        1.0 / (1.0 + pow(10, (kBotElo - playerRating) / 400.0));
    final score = playerWon ? 1.0 : 0.0;
    final change = (_k * (score - expected)).round();
    return EloResult(
      newRating: playerRating + change,
      delta: change,
    );
  }
}
