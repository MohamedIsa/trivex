import '../models/question.dart';
import '../services/elo_service.dart';

/// Immutable snapshot of all game state.
///
/// Mutated only through [GameStateNotifier.copyWith].
class GameState {
  final List<Question> questions;
  final String difficulty;

  /// Index of the currently displayed question (0–9).
  final int currentIndex;

  final int playerScore;
  final int botScore;

  /// The option index the player tapped, or null if no selection has been made.
  final int? selectedIndex;

  /// True while the answer reveal animation / panel is visible.
  final bool isRevealing;

  /// True after the 10th question has been answered / timed out.
  final bool isGameOver;

  /// Populated by [GameStateNotifier] when [isGameOver] becomes true.
  final EloResult? eloResult;

  const GameState({
    required this.questions,
    required this.difficulty,
    required this.currentIndex,
    required this.playerScore,
    required this.botScore,
    required this.selectedIndex,
    required this.isRevealing,
    required this.isGameOver,
    this.eloResult,
  });

  /// Returns a new [GameState] with the supplied fields overridden.
  GameState copyWith({
    List<Question>? questions,
    String? difficulty,
    int? currentIndex,
    int? playerScore,
    int? botScore,
    int? selectedIndex,
    bool? isRevealing,
    bool? isGameOver,
    EloResult? eloResult,
    bool clearSelectedIndex = false,
  }) {
    return GameState(
      questions: questions ?? this.questions,
      difficulty: difficulty ?? this.difficulty,
      currentIndex: currentIndex ?? this.currentIndex,
      playerScore: playerScore ?? this.playerScore,
      botScore: botScore ?? this.botScore,
      selectedIndex:
          clearSelectedIndex ? null : (selectedIndex ?? this.selectedIndex),
      isRevealing: isRevealing ?? this.isRevealing,
      isGameOver: isGameOver ?? this.isGameOver,
      eloResult: eloResult ?? this.eloResult,
    );
  }

  /// Convenience: the question currently on-screen.
  Question get currentQuestion => questions[currentIndex];

  /// Blank slate used before [GameStateNotifier.initGame] is called.
  static const empty = GameState(
    questions: [],
    difficulty: 'medium',
    currentIndex: 0,
    playerScore: 0,
    botScore: 0,
    selectedIndex: null,
    isRevealing: false,
    isGameOver: false,
  );
}
