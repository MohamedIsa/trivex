/// Immutable definition of a single achievement.
///
/// The 8 canonical achievements are listed in [kAchievements].
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.hint,
    required this.emoji,
  });

  final String id;
  final String name;
  final String hint;
  final String emoji;
}

/// All achievements in the game — order determines display order.
const List<Achievement> kAchievements = [
  Achievement(
    id: 'first_win',
    name: 'First Win',
    hint: 'Win a game for the first time',
    emoji: '🏆',
  ),
  Achievement(
    id: 'perfect_round',
    name: 'Perfect Round',
    hint: 'Answer all questions correctly in a single game',
    emoji: '💯',
  ),
  Achievement(
    id: 'hot_streak',
    name: 'Hot Streak',
    hint: 'Win 3 games in a row',
    emoji: '🔥',
  ),
  Achievement(
    id: 'beat_hard',
    name: 'Hard Crusher',
    hint: 'Beat the bot on Hard difficulty',
    emoji: '💪',
  ),
  Achievement(
    id: 'ten_games',
    name: 'Veteran',
    hint: 'Complete 10 games total',
    emoji: '⭐',
  ),
  Achievement(
    id: 'speed_demon',
    name: 'Speed Demon',
    hint: 'Answer 5 questions under 5 seconds each in one game',
    emoji: '⚡',
  ),
  Achievement(
    id: 'polyglot',
    name: 'Polyglot',
    hint: 'Complete a game in Arabic',
    emoji: '🌍',
  ),
  Achievement(
    id: 'centurion',
    name: 'Centurion',
    hint: 'Reach ELO ≥ 1100',
    emoji: '🎯',
  ),
];
