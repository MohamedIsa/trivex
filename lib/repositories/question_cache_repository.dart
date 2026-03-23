import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'question_cache_repository.g.dart';

/// Persists recently seen question texts per topic+difficulty+language key.
///
/// Stored in a Hive box named `'question_cache'`.
/// Each box entry maps a cache key (e.g. `"history-easy-en"`) to a
/// `List<String>` of question texts the player has already seen.
class QuestionCacheRepository {
  static const String boxName = 'question_cache';

  /// Maximum number of question texts retained per cache key.
  static const int maxQuestionsPerKey = 50;

  Box get _box => Hive.box(boxName);

  /// Returns previously seen question texts for the given [key],
  /// or an empty list when no history exists.
  List<String> getSeenQuestions(String key) {
    final raw = _box.get(key);
    if (raw == null) return <String>[];
    return List<String>.from(raw as List);
  }

  /// Appends [questions] to the cache under [key] and trims to
  /// [maxQuestionsPerKey] entries (oldest removed first).
  Future<void> save(String key, List<String> questions) async {
    final existing = getSeenQuestions(key);
    final merged = [...existing, ...questions];

    // Keep only the most recent entries when over the cap.
    final trimmed = merged.length > maxQuestionsPerKey
        ? merged.sublist(merged.length - maxQuestionsPerKey)
        : merged;

    await _box.put(key, trimmed);
  }

  /// Builds the standard cache key from topic, difficulty, and optional language.
  ///
  /// When [language] is omitted (pre-fetch, before the worker responds),
  /// the key is `'$topic-$difficulty'`.  When provided, the key is
  /// `'$topic-$difficulty-$language'`.
  static String cacheKey({
    required String topic,
    required String difficulty,
    String? language,
  }) =>
      language != null ? '$topic-$difficulty-$language' : '$topic-$difficulty';
}

/// Riverpod provider for [QuestionCacheRepository].
@Riverpod(keepAlive: true)
QuestionCacheRepository questionCacheRepository(
  QuestionCacheRepositoryRef ref,
) {
  return QuestionCacheRepository();
}
