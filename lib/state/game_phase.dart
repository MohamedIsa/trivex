import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/question.dart';
import '../services/elo_service.dart';

part 'game_phase.freezed.dart';

/// Immutable snapshot of shared round data available during active play.
///
/// Carried by [PlayingPhase], [RevealingPhase], and [FinishedPhase].
@freezed
class GameRound with _$GameRound {
  const GameRound._();

  const factory GameRound({
    required List<Question> questions,
    required String topic,
    required String difficulty,

    /// Language code for the current round: 'en' or 'ar'.
    @Default('en') String language,

    /// Index of the currently displayed question (0-based).
    required int currentIndex,
    required int playerScore,
    required int botScore,

    /// Per-question correctness — `true` if the player answered correctly.
    @Default(<bool>[]) List<bool> playerCorrect,

    /// Per-question answer time in seconds (timeLimit − timeLeft).
    @Default(<int>[]) List<int> answerTimesSeconds,
  }) = _GameRound;

  /// Convenience: the question currently on-screen.
  Question get currentQuestion => questions[currentIndex];
}

/// Sealed union representing the five distinct phases of a game.
///
/// Replaces the previous [isRevealing] / [isGameOver] boolean flags and
/// nullable [selectedIndex] / [eloResult] fields with explicit phase types.
@freezed
sealed class GamePhase with _$GamePhase {
  /// Before any game — initial state.
  const factory GamePhase.idle() = IdlePhase;

  /// Questions are being fetched.
  const factory GamePhase.loading({
    required String topic,
    required String difficulty,
  }) = LoadingPhase;

  /// Player is viewing a question and can select an answer.
  const factory GamePhase.playing({required GameRound round}) = PlayingPhase;

  /// Answer has been locked in (or timed out); reveal overlay is visible.
  const factory GamePhase.revealing({
    required GameRound round,

    /// The option index the player tapped, or `null` if the timer expired.
    int? selectedIndex,
  }) = RevealingPhase;

  /// Round complete — results screen is showing.
  const factory GamePhase.finished({
    required GameRound round,
    required EloResult eloResult,
  }) = FinishedPhase;
}
