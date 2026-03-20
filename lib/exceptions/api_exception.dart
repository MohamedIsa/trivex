/// Thrown by [QuestionService] when the Worker returns a non-200 response.
///
/// [message] is the `error` string from the Worker's JSON body.
/// [retryable] mirrors the Worker's `retryable` flag — the UI can use this
/// to decide whether to offer a retry button.
class ApiException implements Exception {
  final String message;
  final bool retryable;

  const ApiException({required this.message, required this.retryable});

  @override
  String toString() => 'ApiException(message: $message, retryable: $retryable)';
}
