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
  });
}
