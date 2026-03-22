import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../exceptions/api_exception.dart';
import '../models/game_config.dart';
import '../models/question.dart';

/// Fetches trivia questions from the Cloudflare Worker.
///
/// Depends on SETUP-002 (Question / GameConfig models) and WORKER-003
/// (validation + error shape on the Worker side).
class QuestionService {
  /// Allows injecting a custom [http.Client] in tests; defaults to a
  /// freshly created client for production use.
  final http.Client _client;

  QuestionService({http.Client? client}) : _client = client ?? http.Client();

  /// Sends `POST /generate` to the Worker and returns exactly 10 [Question]s.
  ///
  /// Throws:
  /// - [TimeoutException] if the Worker does not respond within 5 seconds.
  /// - [ApiException] for any non-200 HTTP response.
  Future<List<Question>> fetchQuestions(GameConfig config) async {
    final uri = Uri.parse('$kWorkerBaseUrl/generate');
    final body = jsonEncode({
      'topic': config.topic,
      'difficulty': config.difficulty,
      'count': config.count,
      'language': config.language,
    });

    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final questions = (data['questions'] as List<dynamic>)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();
      return questions;
    }

    // Non-200: parse the Worker's error shape { error, retryable }
    Map<String, dynamic>? errorData;
    try {
      errorData = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // Body wasn't JSON — fall through to a generic message
    }

    throw ApiException(
      message: errorData?['error'] as String? ??
          'Request failed with status ${response.statusCode}',
      retryable: errorData?['retryable'] as bool? ?? false,
    );
  }
}
