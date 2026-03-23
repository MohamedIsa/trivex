import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:trivex/models/question.dart';
import 'package:trivex/repositories/offline_question_cache.dart';

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

Question _question(int index) => Question(
  id: 'q$index',
  question: 'What is $index + $index?',
  options: ['${index * 2}', '${index + 1}', '${index * 3}', '0'],
  correctIndex: 0,
  explanation: 'Because $index + $index = ${index * 2}.',
  timeLimit: 15,
);

List<Question> _questionSet(int count, {int startAt = 1}) =>
    List.generate(count, (i) => _question(startAt + i));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late OfflineQuestionCache cache;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('hive_offline_test_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(QuestionAdapter());
    }
    await Hive.openBox(OfflineQuestionCache.boxName);
    cache = OfflineQuestionCache();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  // ── basic get / save ────────────────────────────────────────────────────

  test('get returns null for unknown key', () {
    expect(cache.get('unknown-key'), isNull);
  });

  test('save then get returns the same questions', () async {
    const key = 'history-easy-en';
    final questions = _questionSet(5);

    await cache.save(key, questions);
    final result = cache.get(key);

    expect(result, isNotNull);
    expect(result!.length, 5);
    expect(result.first.id, questions.first.id);
    expect(result.last.question, questions.last.question);
  });

  test('save overwrites existing entry for the same key', () async {
    const key = 'math-hard-en';
    await cache.save(key, _questionSet(3));
    await cache.save(key, _questionSet(7, startAt: 10));

    final result = cache.get(key);
    expect(result!.length, 7);
    expect(result.first.id, 'q10');
  });

  // ── LRU cap ─────────────────────────────────────────────────────────────

  test('cache cap — 11th set evicts the oldest entry', () async {
    // Save 10 sets (the maximum).
    for (var i = 1; i <= 10; i++) {
      await cache.save('topic$i-easy-en', _questionSet(2, startAt: i * 10));
    }

    // All 10 should be present.
    expect(cache.get('topic1-easy-en'), isNotNull);
    expect(cache.get('topic10-easy-en'), isNotNull);

    // Save an 11th set — should evict 'topic1-easy-en' (the oldest).
    await cache.save('topic11-easy-en', _questionSet(2, startAt: 110));

    expect(cache.get('topic1-easy-en'), isNull, reason: 'oldest set evicted');
    expect(cache.get('topic2-easy-en'), isNotNull, reason: 'second set kept');
    expect(cache.get('topic11-easy-en'), isNotNull, reason: 'new set stored');
  });

  test(
    're-saving an existing key moves it to the tail (not evicted early)',
    () async {
      // Fill 10 slots.
      for (var i = 1; i <= 10; i++) {
        await cache.save('topic$i-easy-en', _questionSet(2, startAt: i * 10));
      }

      // Re-save topic1 to move it to the tail.
      await cache.save('topic1-easy-en', _questionSet(2, startAt: 100));

      // Adding an 11th should now evict topic2 (the new oldest).
      await cache.save('topic11-easy-en', _questionSet(2, startAt: 110));

      expect(cache.get('topic1-easy-en'), isNotNull, reason: 'moved to tail');
      expect(cache.get('topic2-easy-en'), isNull, reason: 'now the oldest');
      expect(cache.get('topic11-easy-en'), isNotNull);
    },
  );

  // ── cacheKey ────────────────────────────────────────────────────────────

  test('cacheKey builds correct format', () {
    expect(
      OfflineQuestionCache.cacheKey(
        topic: 'Science',
        difficulty: 'medium',
        language: 'en',
      ),
      'Science-medium-en',
    );
    expect(
      OfflineQuestionCache.cacheKey(
        topic: 'تاريخ',
        difficulty: 'hard',
        language: 'ar',
      ),
      'تاريخ-hard-ar',
    );
  });
}
