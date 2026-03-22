import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/question.dart';
import '../services/elo_service.dart';

part 'game_state.freezed.dart';

/// Immutable snapshot of all game state.
///
/// Mutated only through [GameStateNotifier] methods.
@freezed
class GameState with _$GameState {
  const GameState._();

  const factory GameState({
    required List<Question> questions,
    required String topic,
    required String difficulty,

    /// Language code for the current round: 'en' or 'ar'.
    @Default('en') String language,

    /// Index of the currently displayed question (0-based).
    required int currentIndex,
    required int playerScore,
    required int botScore,

    /// The option index the player tapped, or null if no selection has been made.
    int? selectedIndex,

    /// True while the answer reveal animation / panel is visible.
    required bool isRevealing,

    /// True after the last question has been answered / timed out.
    required bool isGameOver,

    /// Populated by [GameStateNotifier] when [isGameOver] becomes true.
    EloResult? eloResult,
  }) = _GameState;

  /// Convenience: the question currently on-screen.
  Question get currentQuestion => questions[currentIndex];

  /// Blank slate used before [GameStateNotifier.initGame] is called.
  static const empty = GameState(
    questions: [],
    topic: '',
    difficulty: 'medium',
    currentIndex: 0,
    playerScore: 0,
    botScore: 0,
    isRevealing: false,
    isGameOver: false,
  );
}
