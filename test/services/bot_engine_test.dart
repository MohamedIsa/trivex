import 'package:flutter_test/flutter_test.dart';
import 'package:trivex/services/bot_engine.dart';
import 'package:trivex/constants/game_constants.dart';

void main() {
  // ── kBotElo constant ──────────────────────────────────────────────────────

  test('kBotElo is 1000', () {
    expect(kBotElo, 1000);
  });

  // ── statistical accuracy tests (1 000 samples each) ──────────────────────

  const trials = 1000;
  const tolerance = 0.05; // ±5 %

  group('BotEngine.didBotAnswer accuracy', () {
    int countCorrect(String difficulty) {
      var correct = 0;
      for (var i = 0; i < trials; i++) {
        if (BotEngine.didBotAnswer(difficulty)) correct++;
      }
      return correct;
    }

    test("easy: correct rate is within 5 % of 40 %", () {
      final rate = countCorrect('easy') / trials;
      expect(rate, closeTo(0.40, tolerance));
    });

    test("medium: correct rate is within 5 % of 65 %", () {
      final rate = countCorrect('medium') / trials;
      expect(rate, closeTo(0.65, tolerance));
    });

    test("hard: correct rate is within 5 % of 85 %", () {
      final rate = countCorrect('hard') / trials;
      expect(rate, closeTo(0.85, tolerance));
    });

    test("unknown difficulty falls back to hard rate (within 5 % of 85 %)", () {
      final rate = countCorrect('extreme') / trials;
      expect(rate, closeTo(0.85, tolerance));
    });
  });

  // ── return type ───────────────────────────────────────────────────────────

  test('didBotAnswer returns a bool', () {
    final result = BotEngine.didBotAnswer('easy');
    expect(result, isA<bool>());
  });
}
