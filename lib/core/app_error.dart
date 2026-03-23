import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

/// Typed error union for network-layer failures.
///
/// Every variant carries just enough context for the UI to display a
/// meaningful message and decide whether to offer a retry.
@freezed
sealed class AppError with _$AppError {
  const factory AppError.network({required String message}) = NetworkError;
  const factory AppError.parse({required String message}) = ParseError;
  const factory AppError.timeout() = TimeoutError;
  const factory AppError.unknown({required String message}) = UnknownError;
}
