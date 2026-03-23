import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:trivex/repositories/achievement_repository.dart';

void main() {
  late AchievementRepository repo;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('hive_test_achieve_');
    Hive.init(dir.path);
    await Hive.openBox(AchievementRepository.boxName);
    repo = AchievementRepository();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  // ── unlock + getUnlocked ──────────────────────────────────────────────────

  group('unlock / getUnlocked', () {
    test('starts empty', () {
      expect(repo.getUnlocked(), isEmpty);
    });

    test('unlock() persists an ID that getUnlocked() returns', () async {
      await repo.unlock('first_win');
      expect(repo.getUnlocked(), {'first_win'});
    });

    test('unlock() is idempotent — no duplicate entries', () async {
      await repo.unlock('first_win');
      await repo.unlock('first_win');
      expect(repo.getUnlocked(), {'first_win'});
    });

    test('multiple different IDs are all returned', () async {
      await repo.unlock('first_win');
      await repo.unlock('hot_streak');
      await repo.unlock('centurion');
      expect(repo.getUnlocked(), {'first_win', 'hot_streak', 'centurion'});
    });
  });

  // ── getUnlockDate ─────────────────────────────────────────────────────────

  group('getUnlockDate', () {
    test('returns null for a locked achievement', () {
      expect(repo.getUnlockDate('first_win'), isNull);
    });

    test('returns a DateTime after unlock()', () async {
      final before = DateTime.now();
      await repo.unlock('first_win');
      final date = repo.getUnlockDate('first_win');

      expect(date, isNotNull);
      expect(date!.isAfter(before.subtract(const Duration(seconds: 1))), true);
    });
  });

  // ── win streak ────────────────────────────────────────────────────────────

  group('win streak', () {
    test('defaults to 0', () {
      expect(repo.getWinStreak(), 0);
    });

    test('setWinStreak() persists the value', () async {
      await repo.setWinStreak(3);
      expect(repo.getWinStreak(), 3);
    });

    test('can be reset to 0', () async {
      await repo.setWinStreak(5);
      await repo.setWinStreak(0);
      expect(repo.getWinStreak(), 0);
    });
  });

  // ── games played ──────────────────────────────────────────────────────────

  group('games played', () {
    test('defaults to 0', () {
      expect(repo.getGamesPlayed(), 0);
    });

    test('incrementGamesPlayed() increments by 1 each call', () async {
      await repo.incrementGamesPlayed();
      await repo.incrementGamesPlayed();
      await repo.incrementGamesPlayed();
      expect(repo.getGamesPlayed(), 3);
    });
  });
}
