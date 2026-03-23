import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:trivex/core/app_error.dart';
import 'package:trivex/core/result.dart';
import 'package:trivex/models/fetch_result.dart';
import 'package:trivex/services/question_service.dart';
import 'package:trivex/models/game_config.dart';

import 'question_service_test.mocks.dart';

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _buildQuestion(int index) => {
      'id': 'q$index',
      'question': 'What is $index + $index?',
      'options': ['${index * 2}', '${index + 1}', '${index * 3}', '0'],
      'correctIndex': 0,
      'explanation': 'Because $index + $index = ${index * 2}.',
      'timeLimit': 15,
    };

String _buildFixture({int count = 10, String language = 'en'}) {
  final questions = List.generate(count, (i) => _buildQuestion(i + 1));
  return jsonEncode({'questions': questions, 'language': language});
}

// ---------------------------------------------------------------------------
// Mock generation annotation
// ---------------------------------------------------------------------------

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;
  late QuestionService service;
  const config = GameConfig(topic: 'Math', difficulty: 'easy', count: 10);

  setUp(() {
    mockClient = MockClient();
    service = QuestionService(client: mockClient);
  });

  // ── happy path ────────────────────────────────────────────────────────────

  test('returns Result.ok with 10 questions on HTTP 200', () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(_buildFixture(), 200));

    final result = await service.fetchQuestions(config);

    expect(result, isA<Ok<FetchResult>>());
    final fetchResult = (result as Ok<FetchResult>).value;
    expect(fetchResult.questions.length, 10);
    expect(fetchResult.language, 'en');
    expect(fetchResult.questions.first.id, 'q1');
    expect(fetchResult.questions.first.question, 'What is 1 + 1?');
    expect(fetchResult.questions.first.options.length, 4);
    expect(fetchResult.questions.first.correctIndex, 0);
    expect(fetchResult.questions.first.explanation, isNotEmpty);
  });

  test('Question.fromJson parses all fields correctly from fixture', () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(_buildFixture(), 200));

    final result = await service.fetchQuestions(config);
    final questions = (result as Ok<FetchResult>).value.questions;
    final q = questions[4]; // 5th question

    expect(q.id, 'q5');
    expect(q.correctIndex, 0);
    expect(q.options, ['10', '6', '15', '0']);
  });

  // ── error path ────────────────────────────────────────────────────────────

  test('network error → Result.err(NetworkError) on non-200 with error body',
      () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(
          jsonEncode({'error': 'LLM API unavailable', 'retryable': true}),
          502,
        ));

    final result = await service.fetchQuestions(config);

    expect(result, isA<Err>());
    final error = (result as Err).error;
    expect(error, isA<NetworkError>());
    expect((error as NetworkError).message, 'LLM API unavailable');
  });

  test('network error → Result.err(NetworkError) with generic message when body is not JSON',
      () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response('Internal Server Error', 500));

    final result = await service.fetchQuestions(config);

    expect(result, isA<Err>());
    final error = (result as Err).error;
    expect(error, isA<NetworkError>());
    expect((error as NetworkError).message, contains('500'));
  });

  test('parse failure → Result.err(ParseError) on malformed JSON response',
      () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response('{"questions": "not-a-list"}', 200));

    final result = await service.fetchQuestions(config);

    expect(result, isA<Err>());
    final error = (result as Err).error;
    expect(error, isA<ParseError>());
  });

  // ── request shape ─────────────────────────────────────────────────────────

  test('sends Content-Type: application/json and correct body', () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(_buildFixture(), 200));

    await service.fetchQuestions(config);

    final captured = verify(mockClient.post(
      any,
      headers: captureAnyNamed('headers'),
      body: captureAnyNamed('body'),
    )).captured;

    final headers = captured[0] as Map<String, String>;
    final bodyStr = captured[1] as String;
    final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;

    expect(headers['Content-Type'], 'application/json');
    expect(bodyJson['topic'], 'Math');
    expect(bodyJson['difficulty'], 'easy');
    expect(bodyJson['count'], 10);
    expect(bodyJson.containsKey('language'), isFalse);
  });

  test('GameConfig(count: 5) — request body contains "count": 5', () async {
    const config5 = GameConfig(topic: 'Science', difficulty: 'hard', count: 5);

    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer(
      (_) async => http.Response(_buildFixture(count: 5), 200),
    );

    await service.fetchQuestions(config5);

    final captured = verify(mockClient.post(
      any,
      headers: captureAnyNamed('headers'),
      body: captureAnyNamed('body'),
    )).captured;

    final bodyStr = captured[1] as String;
    final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;

    expect(bodyJson['count'], 5);
  });

  // ── language auto-detection (UX-005) ──────────────────────────────────────

  test('request body does NOT contain language field', () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer(
      (_) async => http.Response(_buildFixture(count: 3), 200),
    );

    await service.fetchQuestions(config);

    final captured = verify(mockClient.post(
      any,
      headers: captureAnyNamed('headers'),
      body: captureAnyNamed('body'),
    )).captured;

    final bodyStr = captured[1] as String;
    final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;

    expect(bodyJson.containsKey('language'), isFalse);
  });

  test('response with language: "ar" → FetchResult.language is "ar"',
      () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer(
      (_) async => http.Response(_buildFixture(count: 3, language: 'ar'), 200),
    );

    const configAr = GameConfig(
      topic: 'تاريخ',
      difficulty: 'easy',
      count: 3,
    );
    final result = await service.fetchQuestions(configAr);

    expect(result, isA<Ok<FetchResult>>());
    final fetchResult = (result as Ok<FetchResult>).value;
    expect(fetchResult.language, 'ar');
    expect(fetchResult.questions.length, 3);
  });

  test('response with language: "en" → FetchResult.language is "en"',
      () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(_buildFixture(), 200));

    final result = await service.fetchQuestions(config);

    expect(result, isA<Ok<FetchResult>>());
    expect((result as Ok<FetchResult>).value.language, 'en');
  });

  test('response missing language field → defaults to "en"', () async {
    // Build a response without the language field.
    final questionsOnly = jsonEncode({
      'questions': List.generate(10, (i) => _buildQuestion(i + 1)),
    });

    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(questionsOnly, 200));

    final result = await service.fetchQuestions(config);

    expect(result, isA<Ok<FetchResult>>());
    expect((result as Ok<FetchResult>).value.language, 'en');
  });

  // ── excludeQuestions ──────────────────────────────────────────────────────

  test(
      'fetchQuestions with non-empty excludeQuestions — '
      'request body contains excludeQuestions array', () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(_buildFixture(), 200));

    await service.fetchQuestions(
      config,
      excludeQuestions: ['What is 1+1?', 'What is 2+2?'],
    );

    final captured = verify(mockClient.post(
      any,
      headers: captureAnyNamed('headers'),
      body: captureAnyNamed('body'),
    )).captured;

    final bodyStr = captured[1] as String;
    final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;

    expect(bodyJson['excludeQuestions'], ['What is 1+1?', 'What is 2+2?']);
  });

  test(
      'fetchQuestions with empty excludeQuestions — '
      'request body omits excludeQuestions key', () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(_buildFixture(), 200));

    await service.fetchQuestions(config, excludeQuestions: []);

    final captured = verify(mockClient.post(
      any,
      headers: captureAnyNamed('headers'),
      body: captureAnyNamed('body'),
    )).captured;

    final bodyStr = captured[1] as String;
    final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;

    expect(bodyJson.containsKey('excludeQuestions'), isFalse);
  });
}
