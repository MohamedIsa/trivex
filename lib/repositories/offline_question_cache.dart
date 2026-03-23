import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/question.dart';

part 'offline_question_cache.g.dart';

/// Persists full [Question] lists per topic+difficulty+language key for
/// offline play.
///
/// Stored in a Hive box named `'offline_questions'`.
/// Capped at [maxSets] entries using an LRU eviction policy — the least
/// recently saved set is removed when the cap is exceeded.
class OfflineQuestionCache {
  static const String boxName = 'offline_questions';

  /// Maximum number of question sets retained in the cache.
  static const int maxSets = 10;

  /// Internal key used to persist the LRU access-order list.
  static const String _lruKey = '_lru_order';

  Box get _box => Hive.box(boxName);

  /// Returns cached questions for [key], or `null` when no cache exists.
  List<Question>? get(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    return List<Question>.from(raw as List);
  }

  /// Saves [questions] under [key], evicting the oldest set when the cap
  /// is exceeded.
  Future<void> save(String key, List<Question> questions) async {
    final lruList = _getLruOrder();

    // Remove existing entry so it can be re-added at the tail (most recent).
    lruList.remove(key);
    lruList.add(key);

    // Evict oldest entries until within cap.
    while (lruList.length > maxSets) {
      final oldest = lruList.removeAt(0);
      await _box.delete(oldest);
    }

    await _box.put(key, questions);
    await _box.put(_lruKey, lruList);
  }

  /// Builds the standard cache key from topic, difficulty, and language.
  static String cacheKey({
    required String topic,
    required String difficulty,
    required String language,
  }) => '$topic-$difficulty-$language';

  // ── Private helpers ─────────────────────────────────────────────────────

  List<String> _getLruOrder() {
    final raw = _box.get(_lruKey);
    if (raw == null) return <String>[];
    return List<String>.from(raw as List);
  }
}

/// Riverpod provider for [OfflineQuestionCache].
@Riverpod(keepAlive: true)
OfflineQuestionCache offlineQuestionCache(OfflineQuestionCacheRef ref) {
  return OfflineQuestionCache();
}
