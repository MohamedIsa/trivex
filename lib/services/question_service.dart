import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../core/app_error.dart';
import '../core/result.dart';
import '../models/fetch_result.dart';
import '../models/game_config.dart';
import '../models/question.dart';

/// Fetches trivia questions from the Cloudflare Worker.
///
/// Depends on (Question / GameConfig models) and
/// (validation + error shape on the Worker side).
class QuestionService {
  /// Allows injecting a custom [http.Client] in tests; defaults to a
  /// freshly created client for production use.
  final http.Client _client;

  QuestionService({http.Client? client}) : _client = client ?? http.Client();

  /// Sends `POST /generate` to the Worker and returns a [Result] wrapping
  /// a [FetchResult] (questions + auto-detected language) on success,
  /// or an [AppError] on failure.
  ///
  /// When [excludeQuestions] is non-empty the list is included in the request
  /// body so the Worker instructs the LLM to avoid repeating them.
  Future<Result<FetchResult>> fetchQuestions(
    GameConfig config, {
    List<String> excludeQuestions = const [],
  }) async {
    final uri = Uri.parse('$kWorkerBaseUrl/generate');
    final bodyMap = <String, dynamic>{
      'topic': config.topic,
      'difficulty': config.difficulty,
      'count': config.count,
    };
    if (excludeQuestions.isNotEmpty) {
      bodyMap['excludeQuestions'] = excludeQuestions;
    }
    final body = jsonEncode(bodyMap);

    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(kFetchTimeout);
    } on TimeoutException {
      return const Result.err(AppError.timeout());
    } on Exception catch (e) {
      return Result.err(AppError.network(message: e.toString()));
    }

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final questions = (data['questions'] as List<dynamic>)
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList();
        final language = (data['language'] as String?) ?? 'en';
        return Result.ok(FetchResult(questions: questions, language: language));
      } catch (e) {
        return Result.err(
          AppError.parse(message: 'Failed to parse response: $e'),
        );
      }
    }

    // Non-200: parse the Worker's error shape { error, retryable }
    String errorMessage;
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = errorData['error'] as String? ??
          'Request failed with status ${response.statusCode}';
    } catch (_) {
      errorMessage = 'Request failed with status ${response.statusCode}';
    }

    return Result.err(AppError.network(message: errorMessage));
  }
}
