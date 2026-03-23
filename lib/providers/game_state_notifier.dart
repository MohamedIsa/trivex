import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/game_state.dart';
import '../models/question.dart';
import '../repositories/elo_repository.dart';
import '../services/bot_engine.dart';
import '../services/elo_service.dart';
import '../services/score_service.dart';

part 'game_state_notifier.g.dart';

/// Central game-state manager.
///
/// Consumed by the Game screen and Reveal screen.
/// The timer drives [timeExpired].
/// ELO calculation reads [state] after [isGameOver] becomes true.
@Riverpod(keepAlive: true)
class GameStateNotifier extends _$GameStateNotifier {
  @override
  GameState build() => GameState.empty;

  /// Access the ELO repository via the provider graph.
  EloRepository get _eloRepository => ref.read(eloRepositoryProvider);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Resets all state and loads [questions] ready for a fresh round.
  ///
  /// [difficulty] is stored so [BotEngine.didBotAnswer] can receive it.
  void initGame(
    List<Question> questions, {
    String topic = '',
    String difficulty = 'medium',
    String language = 'en',
  }) {
    assert(questions.isNotEmpty, 'questions must not be empty');
    state = GameState(
      questions: questions,
      topic: topic,
      difficulty: difficulty,
      language: language,
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
  /// [timeLeft] is the remaining seconds used for the speed bonus.
  void selectAnswer(int index, {required int timeLeft}) {
    // Guard: ignore taps after the answer is already locked in.
    if (state.isRevealing || state.isGameOver) return;

    final correct = state.currentQuestion.correctIndex;
    final playerCorrect = index == correct;

    final playerPoints = ScoreService.calculatePoints(
      playerCorrect,
      timeLeft.toDouble(),
      timeLimitSeconds: state.currentQuestion.timeLimit.toDouble(),
    );

    final botCorrect = BotEngine.didBotAnswer(state.difficulty);
    final botPoints = botCorrect ? 100 : 0;

    state = state.copyWith(
      selectedIndex: index,
      playerScore: state.playerScore + playerPoints,
      botScore: state.botScore + botPoints,
      isRevealing: true,
    );
  }

  /// Advances to the next question, or ends the game after the last question.
  ///
  /// When the game ends, the player's current persisted ELO is read from
  /// [EloRepository] and the delta is computed via [EloService].
  void nextQuestion() {
    if (state.currentIndex >= state.questions.length - 1) {
      // Last question was just revealed — game over.
      final playerRating = _eloRepository.getCurrentRating();
      final playerWon = state.playerScore > state.botScore;
      final elo = EloService.calculate(playerRating, playerWon);
      state = state.copyWith(isGameOver: true, eloResult: elo);
      return;
    }
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      selectedIndex: null,
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
