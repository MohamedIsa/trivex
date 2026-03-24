import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_service.g.dart';

/// Thin, typed wrapper around [FirebaseAnalytics].
///
/// Every public method maps to exactly one analytics event with strongly
/// typed parameters — no generic `logEvent` passthrough.
///
/// In [kDebugMode] all methods are **no-ops** so dev sessions never pollute
/// production analytics.
///
/// ## Firebase Setup (TODO — before first production build)
///
/// 1. Create a Firebase project at https://console.firebase.google.com
/// 2. Add an Android app → download `google-services.json` to
///    `android/app/google-services.json`
/// 3. Add an iOS app → download `GoogleService-Info.plist` to
///    `ios/Runner/GoogleService-Info.plist`
/// 4. Ensure `Firebase.initializeApp()` is called in `main()` before
///    `runApp()` (currently stubbed behind a `kReleaseMode` guard).
class AnalyticsService {
  /// Creates a service backed by the given [FirebaseAnalytics] instance.
  ///
  /// In production code the instance comes from
  /// `FirebaseAnalytics.instance`; in tests a mock can be injected.
  /// Pass `null` for a no-op stub (used when [kDebugMode] is `true`).
  const AnalyticsService(this._analytics);

  final FirebaseAnalytics? _analytics;

  // ── Events ──────────────────────────────────────────────────────────────

  /// Fired when a new game round starts.
  Future<void> logGameStarted({
    required String topic,
    required String difficulty,
    required String language,
    required int questionCount,
  }) async {
    if (kDebugMode) return;
    await _analytics?.logEvent(
      name: 'game_started',
      parameters: {
        'topic': topic,
        'difficulty': difficulty,
        'language': language,
        'question_count': questionCount,
      },
    );
  }

  /// Fired when the final question's reveal is dismissed (game finished).
  Future<void> logGameCompleted({
    required String topic,
    required String difficulty,
    required String language,
    required int playerScore,
    required int botScore,
    required String result,
  }) async {
    if (kDebugMode) return;
    await _analytics?.logEvent(
      name: 'game_completed',
      parameters: {
        'topic': topic,
        'difficulty': difficulty,
        'language': language,
        'player_score': playerScore,
        'bot_score': botScore,
        'result': result,
      },
    );
  }

  /// Fired each time the player answers a question (or the timer expires).
  Future<void> logQuestionAnswered({
    required bool correct,
    required int timeTakenMs,
    required int questionIndex,
  }) async {
    if (kDebugMode) return;
    await _analytics?.logEvent(
      name: 'question_answered',
      parameters: {
        'correct': correct,
        'time_taken_ms': timeTakenMs,
        'question_index': questionIndex,
      },
    );
  }

  /// Fired when an achievement is newly unlocked.
  Future<void> logAchievementUnlocked({
    required String achievementId,
  }) async {
    if (kDebugMode) return;
    await _analytics?.logEvent(
      name: 'achievement_unlocked',
      parameters: {
        'achievement_id': achievementId,
      },
    );
  }
}

/// Riverpod provider for [AnalyticsService].
///
/// In release builds this wraps `FirebaseAnalytics.instance`.
/// Tests override this provider with a mock or a no-op stub.
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(AnalyticsServiceRef ref) {
  if (kDebugMode) return const AnalyticsService(null);
  return AnalyticsService(FirebaseAnalytics.instance);
}
