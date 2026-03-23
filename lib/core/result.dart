import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_error.dart';

part 'result.freezed.dart';

/// A lightweight Result type — every fallible operation returns [Result]
/// instead of throwing, so the compiler forces callers to handle both paths.
@Freezed(genericArgumentFactories: true)
sealed class Result<T> with _$Result<T> {
  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(AppError error) = Err<T>;
}
