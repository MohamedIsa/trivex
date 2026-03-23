import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/question.dart';
import '../repositories/elo_repository.dart';
import '../services/bot_engine.dart';
import '../services/elo_service.dart';
import '../services/score_service.dart';
import '../state/game_phase.dart';

part 'game_state_notifier.g.dart';

/// Central game-state manager backed by the [GamePhase] sealed union.
///
/// Consumed by the Game screen, Reveal sheet, Result screen, and Loading
/// screen.  The timer drives [timeExpired].
/// ELO calculation runs inside [nextQuestion] when the last question is
/// revealed.
@Riverpod(keepAlive: true)
class GameStateNotifier extends _$GameStateNotifier {
  @override
  GamePhase build() => const GamePhase.idle();

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
    state = GamePhase.playing(
      round: GameRound(
        questions: questions,
        topic: topic,
        difficulty: difficulty,
        language: language,
        currentIndex: 0,
        playerScore: 0,
        botScore: 0,
      ),
    );
  }

  /// Records the player's answer, runs the bot, and transitions to
  /// [RevealingPhase].
  ///
  /// [index] is the option the player tapped (0–3).
  /// [timeLeft] is the remaining seconds used for the speed bonus.
  void selectAnswer(int index, {required int timeLeft}) {
    // Guard: only valid during PlayingPhase.
    final current = state;
    if (current is! PlayingPhase) return;

    final round = current.round;
    final correct = round.currentQuestion.correctIndex;
    final playerCorrect = index == correct;

    final playerPoints = ScoreService.calculatePoints(
      playerCorrect,
      timeLeft.toDouble(),
      timeLimitSeconds: round.currentQuestion.timeLimit.toDouble(),
    );

    final botCorrect = BotEngine.didBotAnswer(round.difficulty);
    final botPoints = botCorrect ? 100 : 0;

    state = GamePhase.revealing(
      round: round.copyWith(
        playerScore: round.playerScore + playerPoints,
        botScore: round.botScore + botPoints,
        playerCorrect: [...round.playerCorrect, playerCorrect],
        answerTimesSeconds: [
          ...round.answerTimesSeconds,
          round.currentQuestion.timeLimit - timeLeft,
        ],
      ),
      selectedIndex: index,
    );
  }

  /// Advances to the next question, or ends the game after the last question.
  ///
  /// When the game ends, the player's current persisted ELO is read from
  /// [EloRepository] and the delta is computed via [EloService].
  void nextQuestion() {
    final current = state;
    if (current is! RevealingPhase) return;

    final round = current.round;

    if (round.currentIndex >= round.questions.length - 1) {
      // Last question was just revealed — game over.
      final playerRating = _eloRepository.getCurrentRating();
      final playerWon = round.playerScore > round.botScore;
      final elo = EloService.calculate(playerRating, playerWon);
      state = GamePhase.finished(round: round, eloResult: elo);
      return;
    }

    state = GamePhase.playing(
      round: round.copyWith(currentIndex: round.currentIndex + 1),
    );
  }

  /// Called by the timer when the countdown reaches zero.
  ///
  /// No player points are awarded; the bot still gets a chance to answer.
  void timeExpired() {
    // Guard: only valid during PlayingPhase.
    final current = state;
    if (current is! PlayingPhase) return;

    final round = current.round;
    final botCorrect = BotEngine.didBotAnswer(round.difficulty);
    final botPoints = botCorrect ? 100 : 0;

    state = GamePhase.revealing(
      round: round.copyWith(
        botScore: round.botScore + botPoints,
        playerCorrect: [...round.playerCorrect, false],
        answerTimesSeconds: [
          ...round.answerTimesSeconds,
          round.currentQuestion.timeLimit,
        ],
      ),
      // selectedIndex stays null — no player selection.
    );
  }
}
