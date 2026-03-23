import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../core/app_error.dart';
import '../core/env.dart';
import '../core/result.dart';
import '../models/fetch_result.dart';
import '../models/game_config.dart';
import '../models/question.dart';
import '../repositories/offline_question_cache.dart';

/// Fetches trivia questions from the Cloudflare Worker.
///
/// Depends on (Question / GameConfig models) and
/// (validation + error shape on the Worker side).
///
/// When an optional [OfflineQuestionCache] is provided, the service will:
/// - save fetched questions to the cache on every successful network response;
/// - attempt an offline fallback from cache when the network request fails.
class QuestionService {
  /// Allows injecting a custom [http.Client] in tests; defaults to a
  /// freshly created client for production use.
  final http.Client _client;

  /// Optional offline cache — when non-null, enables save-on-success and
  /// fallback-on-failure behaviour.
  final OfflineQuestionCache? _offlineCache;

  QuestionService({http.Client? client, OfflineQuestionCache? offlineCache})
    : _client = client ?? http.Client(),
      _offlineCache = offlineCache;

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
    // Pre-compute cache key for offline save/fallback.
    final detectedLanguage = RegExp(r'[\u0600-\u06FF]').hasMatch(config.topic)
        ? 'ar'
        : 'en';
    final cacheKey = OfflineQuestionCache.cacheKey(
      topic: config.topic,
      difficulty: config.difficulty,
      language: detectedLanguage,
    );

    final uri = Uri.parse('${Env.workerBaseUrl}/generate');
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
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(kFetchTimeout);
    } on TimeoutException {
      return _offlineFallback(
        cacheKey,
        detectedLanguage,
        const Result.err(AppError.timeout()),
      );
    } on Exception catch (e) {
      return _offlineFallback(
        cacheKey,
        detectedLanguage,
        Result.err(AppError.network(message: e.toString())),
      );
    }

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final questions = (data['questions'] as List<dynamic>)
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList();
        final language = (data['language'] as String?) ?? 'en';

        // Save to offline cache (best-effort).
        await _saveToOfflineCache(cacheKey, questions);

        return Result.ok(FetchResult(questions: questions, language: language));
      } catch (e) {
        return _offlineFallback(
          cacheKey,
          detectedLanguage,
          Result.err(AppError.parse(message: 'Failed to parse response: $e')),
        );
      }
    }

    // Non-200: parse the Worker's error shape { error, retryable }
    String errorMessage;
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage =
          errorData['error'] as String? ??
          'Request failed with status ${response.statusCode}';
    } catch (_) {
      errorMessage = 'Request failed with status ${response.statusCode}';
    }

    return _offlineFallback(
      cacheKey,
      detectedLanguage,
      Result.err(AppError.network(message: errorMessage)),
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  /// Attempts to serve cached questions when the network request failed.
  ///
  /// Returns shuffled cached questions wrapped in [Result.ok] with
  /// `isOffline: true`, or the original [fallback] error when no cache is
  /// available.
  Result<FetchResult> _offlineFallback(
    String key,
    String language,
    Result<FetchResult> fallback,
  ) {
    if (_offlineCache == null) return fallback;
    final cached = _offlineCache.get(key);
    if (cached == null) return fallback;

    // Shuffle a defensive copy — never mutate the cached list.
    final shuffled = List<Question>.from(cached)..shuffle();
    return Result.ok(
      FetchResult(questions: shuffled, language: language, isOffline: true),
    );
  }

  /// Best-effort save.  Failures are silently ignored so the main fetch
  /// flow is never disrupted.
  Future<void> _saveToOfflineCache(String key, List<Question> questions) async {
    try {
      await _offlineCache?.save(key, questions);
    } catch (_) {
      // Non-critical — cache save failure is acceptable.
    }
  }
}
