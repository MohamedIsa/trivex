import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:trivex/repositories/question_cache_repository.dart';

void main() {
  late QuestionCacheRepository repo;

  setUp(() async {
    // Use a temp directory so each test starts with a fresh Hive instance.
    final dir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(dir.path);
    await Hive.openBox(QuestionCacheRepository.boxName);
    repo = QuestionCacheRepository();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  // ── save + get ────────────────────────────────────────────────────────────

  test('save() then getSeenQuestions() returns the same texts', () async {
    const key = 'history-easy-en';
    final questions = ['What year did WW2 end?', 'Who was the first president?'];

    await repo.save(key, questions);
    final result = repo.getSeenQuestions(key);

    expect(result, questions);
  });

  test('getSeenQuestions returns empty list for unknown key', () {
    expect(repo.getSeenQuestions('unknown-key'), isEmpty);
  });

  test('save() merges with existing entries', () async {
    const key = 'science-medium-en';
    await repo.save(key, ['Q1', 'Q2']);
    await repo.save(key, ['Q3']);

    expect(repo.getSeenQuestions(key), ['Q1', 'Q2', 'Q3']);
  });

  // ── cap at 50 ─────────────────────────────────────────────────────────────

  test('save() caps at 50 — oldest entries are trimmed', () async {
    const key = 'math-hard-en';

    // Save 45 questions first.
    final first45 = List.generate(45, (i) => 'Q${i + 1}');
    await repo.save(key, first45);

    // Save 15 more — total would be 60, should be trimmed to 50.
    final next15 = List.generate(15, (i) => 'Q${i + 46}');
    await repo.save(key, next15);

    final result = repo.getSeenQuestions(key);
    expect(result.length, QuestionCacheRepository.maxQuestionsPerKey);
    // Oldest 10 (Q1–Q10) should be gone; Q11 is the first remaining.
    expect(result.first, 'Q11');
    expect(result.last, 'Q60');
  });

  // ── cacheKey ──────────────────────────────────────────────────────────────

  test('cacheKey builds correct format with language', () {
    expect(
      QuestionCacheRepository.cacheKey(
        topic: 'history',
        difficulty: 'easy',
        language: 'en',
      ),
      'history-easy-en',
    );
    expect(
      QuestionCacheRepository.cacheKey(
        topic: 'تاريخ',
        difficulty: 'hard',
        language: 'ar',
      ),
      'تاريخ-hard-ar',
    );
  });

  // ── pre-fetch / post-game key parity (UX-005 fix) ─────────────────────

  test('English topic → pre-fetch key matches post-game save key', () {
    const topic = 'Science';
    const difficulty = 'medium';
    // Client-side prediction (same regex as loading_screen / worker)
    final predictedLang =
        RegExp(r'[\u0600-\u06FF]').hasMatch(topic) ? 'ar' : 'en';

    final preFetchKey = QuestionCacheRepository.cacheKey(
      topic: topic,
      difficulty: difficulty,
      language: predictedLang,
    );
    // result_screen saves with the worker-detected language
    final postGameKey = QuestionCacheRepository.cacheKey(
      topic: topic,
      difficulty: difficulty,
      language: 'en', // worker detects 'en' for English topic
    );

    expect(preFetchKey, postGameKey);
    expect(preFetchKey, 'Science-medium-en');
  });

  test('Arabic topic → pre-fetch key matches post-game save key', () {
    const topic = 'تاريخ';
    const difficulty = 'hard';
    final predictedLang =
        RegExp(r'[\u0600-\u06FF]').hasMatch(topic) ? 'ar' : 'en';

    final preFetchKey = QuestionCacheRepository.cacheKey(
      topic: topic,
      difficulty: difficulty,
      language: predictedLang,
    );
    final postGameKey = QuestionCacheRepository.cacheKey(
      topic: topic,
      difficulty: difficulty,
      language: 'ar', // worker detects 'ar' for Arabic topic
    );

    expect(preFetchKey, postGameKey);
    expect(preFetchKey, 'تاريخ-hard-ar');
  });
}
