import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:trivex/services/question_service.dart';
import 'package:trivex/models/game_config.dart';
import 'package:trivex/exceptions/api_exception.dart';

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

String _buildFixture({int count = 10}) {
  final questions = List.generate(count, (i) => _buildQuestion(i + 1));
  return jsonEncode({'questions': questions});
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

  test('returns List<Question> with 10 items on HTTP 200', () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(_buildFixture(), 200));

    final result = await service.fetchQuestions(config);

    expect(result.length, 10);
    expect(result.first.id, 'q1');
    expect(result.first.question, 'What is 1 + 1?');
    expect(result.first.options.length, 4);
    expect(result.first.correctIndex, 0);
    expect(result.first.explanation, isNotEmpty);
  });

  test('Question.fromJson parses all fields correctly from fixture', () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(_buildFixture(), 200));

    final result = await service.fetchQuestions(config);
    final q = result[4]; // 5th question

    expect(q.id, 'q5');
    expect(q.correctIndex, 0);
    expect(q.options, ['10', '6', '15', '0']);
  });

  // ── error path ────────────────────────────────────────────────────────────

  test('throws ApiException on non-200 response with error body', () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(
          jsonEncode({'error': 'LLM API unavailable', 'retryable': true}),
          502,
        ));

    expect(
      () => service.fetchQuestions(config),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'LLM API unavailable')
            .having((e) => e.retryable, 'retryable', isTrue),
      ),
    );
  });

  test('throws ApiException with generic message when body is not JSON', () async {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response('Internal Server Error', 500));

    expect(
      () => service.fetchQuestions(config),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', contains('500'))
            .having((e) => e.retryable, 'retryable', isFalse),
      ),
    );
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
}
