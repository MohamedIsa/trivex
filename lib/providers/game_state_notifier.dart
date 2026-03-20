import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../models/question.dart';
import '../repositories/elo_repository.dart';
import '../services/bot_engine.dart';
import '../services/elo_service.dart';

/// Central game-state manager.
///
/// Consumed by the Game screen (UI-004) and Reveal screen (UI-005).
/// The timer (GAME-003) drives [timeExpired].
/// ELO calculation (ELO-001) reads [state] after [isGameOver] becomes true.
class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier(this._eloRepository) : super(GameState.empty);

  final EloRepository _eloRepository;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Resets all state and loads [questions] ready for a fresh round.
  ///
  /// [difficulty] is stored so [BotEngine.didBotAnswer] can receive it.
  void initGame(List<Question> questions, {String difficulty = 'medium'}) {
    assert(questions.isNotEmpty, 'questions must not be empty');
    state = GameState(
      questions: questions,
      difficulty: difficulty,
      currentIndex: 0,
      playerScore: 0,
      botScore: 0,
      selectedIndex: null,
      isRevealing: false,
      isGameOver: false,
    );
  }

  /// Records the player's answer, runs the bot, and transitions to revealing.
  ///
  /// [index] is the option the player tapped (0–3).
  /// [timeLeft] is the remaining seconds (0–15) used for the speed bonus.
  /// Speed bonus = (timeLeft / 15 * 50).floor(), max 50 pts.
  void selectAnswer(int index, {required int timeLeft}) {
    // Guard: ignore taps after the answer is already locked in.
    if (state.isRevealing || state.isGameOver) return;

    final correct = state.currentQuestion.correctIndex;
    final playerCorrect = index == correct;

    final speedBonus = playerCorrect ? (timeLeft / 15 * 50).floor() : 0;
    final playerPoints = playerCorrect ? 100 + speedBonus : 0;

    final botCorrect = BotEngine.didBotAnswer(state.difficulty);
    final botPoints = botCorrect ? 100 : 0;

    state = state.copyWith(
      selectedIndex: index,
      playerScore: state.playerScore + playerPoints,
      botScore: state.botScore + botPoints,
      isRevealing: true,
    );
  }

  /// Advances to the next question, or ends the game after Q10.
  ///
  /// When the game ends, the player's current persisted ELO is read from
  /// [EloRepository] and the delta is computed via [EloService].
  void nextQuestion() {
    if (state.currentIndex >= 9) {
      // Last question was just revealed — game over.
      final playerRating = _eloRepository.getCurrentRating();
      final playerWon = state.playerScore > state.botScore;
      final elo = EloService.calculate(playerRating, playerWon);
      state = state.copyWith(isGameOver: true, eloResult: elo);
      return;
    }
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      clearSelectedIndex: true,
      isRevealing: false,
    );
  }

  /// Called by the timer when the countdown reaches zero.
  ///
  /// No player points are awarded; the bot still gets a chance to answer.
  void timeExpired() {
    if (state.isRevealing || state.isGameOver) return;

    final botCorrect = BotEngine.didBotAnswer(state.difficulty);
    final botPoints = botCorrect ? 100 : 0;

    state = state.copyWith(
      // selectedIndex stays null — no player selection
      botScore: state.botScore + botPoints,
      isRevealing: true,
    );
  }
}

/// The single game-state provider consumed by all game UI widgets.
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  final eloRepo = ref.watch(eloRepositoryProvider);
  return GameStateNotifier(eloRepo);
});
