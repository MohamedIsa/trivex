import 'package:flutter_test/flutter_test.dart';
import 'package:trivex/services/score_service.dart';

void main() {
  group('ScoreService.calculatePoints', () {
    test('correct at 15s → 150 pts (100 base + 50 speed bonus)', () {
      expect(ScoreService.calculatePoints(true, 15.0), 150);
    });

    test('correct at 0s → 100 pts (100 base + 0 speed bonus)', () {
      expect(ScoreService.calculatePoints(true, 0.0), 100);
    });

    test('incorrect → 0 pts regardless of time', () {
      expect(ScoreService.calculatePoints(false, 15.0), 0);
      expect(ScoreService.calculatePoints(false, 7.5), 0);
      expect(ScoreService.calculatePoints(false, 0.0), 0);
    });

    test('correct at mid-time (7.5s) → 125 pts', () {
      expect(ScoreService.calculatePoints(true, 7.5), 125);
    });

    test('correct at 10s → 133 pts', () {
      // 100 + (10/15 * 50).round() = 100 + 33 = 133
      expect(ScoreService.calculatePoints(true, 10.0), 133);
    });

    test('correct at 7s — .round() yields 23 bonus, not .floor() 23', () {
      // 7/15 * 50 = 23.333…  → .round() = 23, .floor() = 23 (same here)
      // Use 8s where they diverge: 8/15*50 = 26.667 → .round() = 27
      expect(ScoreService.calculatePoints(true, 8.0), 127);
    });

    test('correct at 1s — .round() yields 3 bonus (not .floor() 3)', () {
      // 1/15 * 50 = 3.333… → .round() = 3
      expect(ScoreService.calculatePoints(true, 1.0), 103);
    });

    test('correct at 11s — .round() yields 37 bonus (diverges from .floor())', () {
      // 11/15 * 50 = 36.667 → .round() = 37, .floor() would be 36
      expect(ScoreService.calculatePoints(true, 11.0), 137);
    });

    test('correct at 15s with timeLimitSeconds: 30 → 125 pts', () {
      // 100 + (15/30 * 50).round() = 100 + 25 = 125
      expect(
        ScoreService.calculatePoints(true, 15.0, timeLimitSeconds: 30),
        125,
      );
    });
  });
}
