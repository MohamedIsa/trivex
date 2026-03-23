import 'question.dart';

/// Lightweight value type returned by [QuestionService.fetchQuestions].
///
/// Carries both the parsed questions **and** the language auto-detected by
class FetchResult {
  const FetchResult({required this.questions, required this.language});

  /// The list of trivia questions returned by the worker.
  final List<Question> questions;

  /// Language code auto-detected from the topic text: `'en'` or `'ar'`.
  final String language;
}
