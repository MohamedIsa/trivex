// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'elo_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EloResult {
  int get newRating => throw _privateConstructorUsedError;
  int get delta => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $EloResultCopyWith<EloResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EloResultCopyWith<$Res> {
  factory $EloResultCopyWith(EloResult value, $Res Function(EloResult) then) =
      _$EloResultCopyWithImpl<$Res, EloResult>;
  @useResult
  $Res call({int newRating, int delta});
}

/// @nodoc
class _$EloResultCopyWithImpl<$Res, $Val extends EloResult>
    implements $EloResultCopyWith<$Res> {
  _$EloResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? newRating = null,
    Object? delta = null,
  }) {
    return _then(_value.copyWith(
      newRating: null == newRating
          ? _value.newRating
          : newRating // ignore: cast_nullable_to_non_nullable
              as int,
      delta: null == delta
          ? _value.delta
          : delta // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EloResultImplCopyWith<$Res>
    implements $EloResultCopyWith<$Res> {
  factory _$$EloResultImplCopyWith(
          _$EloResultImpl value, $Res Function(_$EloResultImpl) then) =
      __$$EloResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int newRating, int delta});
}

/// @nodoc
class __$$EloResultImplCopyWithImpl<$Res>
    extends _$EloResultCopyWithImpl<$Res, _$EloResultImpl>
    implements _$$EloResultImplCopyWith<$Res> {
  __$$EloResultImplCopyWithImpl(
      _$EloResultImpl _value, $Res Function(_$EloResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? newRating = null,
    Object? delta = null,
  }) {
    return _then(_$EloResultImpl(
      newRating: null == newRating
          ? _value.newRating
          : newRating // ignore: cast_nullable_to_non_nullable
              as int,
      delta: null == delta
          ? _value.delta
          : delta // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$EloResultImpl implements _EloResult {
  const _$EloResultImpl({required this.newRating, required this.delta});

  @override
  final int newRating;
  @override
  final int delta;

  @override
  String toString() {
    return 'EloResult(newRating: $newRating, delta: $delta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EloResultImpl &&
            (identical(other.newRating, newRating) ||
                other.newRating == newRating) &&
            (identical(other.delta, delta) || other.delta == delta));
  }

  @override
  int get hashCode => Object.hash(runtimeType, newRating, delta);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EloResultImplCopyWith<_$EloResultImpl> get copyWith =>
      __$$EloResultImplCopyWithImpl<_$EloResultImpl>(this, _$identity);
}

abstract class _EloResult implements EloResult {
  const factory _EloResult(
      {required final int newRating,
      required final int delta}) = _$EloResultImpl;

  @override
  int get newRating;
  @override
  int get delta;
  @override
  @JsonKey(ignore: true)
  _$$EloResultImplCopyWith<_$EloResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
