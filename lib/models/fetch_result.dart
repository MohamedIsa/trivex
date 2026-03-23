import 'question.dart';

/// Lightweight value type returned by [QuestionService.fetchQuestions].
///
/// Carries both the parsed questions **and** the language auto-detected by
/// the worker.  When the result came from the offline cache instead of the
/// network, [isOffline] is `true`.
class FetchResult {
  const FetchResult({
    required this.questions,
    required this.language,
    this.isOffline = false,
  });

  /// The list of trivia questions returned by the worker.
  final List<Question> questions;

  /// Language code auto-detected from the topic text: `'en'` or `'ar'`.
  final String language;

  /// `true` when the questions were served from the offline cache because
  /// the network request failed.
  final bool isOffline;
}
