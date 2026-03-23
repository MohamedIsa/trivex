import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'achievement_repository.g.dart';

/// Persists unlocked achievement IDs via a Hive box named `'achievements'`.
///
/// The box must be opened before constructing this class — see `main()`.
/// Also stores auxiliary counters (win streak, games played) needed by
/// achievement condition checks.
class AchievementRepository {
  static const String boxName = 'achievements';
  static const String _unlockedKey = 'unlocked';
  static const String _winStreakKey = 'win_streak';
  static const String _gamesPlayedKey = 'games_played';

  Box get _box => Hive.box(boxName);

  // ── Unlocked set ──────────────────────────────────────────────────────────

  /// Returns the set of currently unlocked achievement IDs.
  Set<String> getUnlocked() {
    final raw = _box.get(_unlockedKey);
    if (raw == null) return {};
    return (raw as List).cast<String>().toSet();
  }

  /// Unlocks [id]. Idempotent — no-op if already unlocked.
  Future<void> unlock(String id) async {
    final current = getUnlocked();
    if (current.contains(id)) return;
    current.add(id);
    await _box.put(_unlockedKey, current.toList());
    await _box.put('date_$id', DateTime.now().toIso8601String());
  }

  /// Returns the [DateTime] when [id] was unlocked, or `null` if locked.
  DateTime? getUnlockDate(String id) {
    final raw = _box.get('date_$id') as String?;
    if (raw == null) return null;
    return DateTime.parse(raw);
  }

  // ── Win streak counter ────────────────────────────────────────────────────

  /// Returns the current consecutive-win count.
  int getWinStreak() => (_box.get(_winStreakKey) as int?) ?? 0;

  /// Persists [streak] as the new consecutive-win count.
  Future<void> setWinStreak(int streak) async {
    await _box.put(_winStreakKey, streak);
  }

  // ── Games-played counter ──────────────────────────────────────────────────

  /// Returns the total number of completed games.
  int getGamesPlayed() => (_box.get(_gamesPlayedKey) as int?) ?? 0;

  /// Increments the total completed-games counter by one.
  Future<void> incrementGamesPlayed() async {
    await _box.put(_gamesPlayedKey, getGamesPlayed() + 1);
  }
}

/// Riverpod provider for [AchievementRepository].
@Riverpod(keepAlive: true)
AchievementRepository achievementRepository(AchievementRepositoryRef ref) {
  return AchievementRepository();
}
