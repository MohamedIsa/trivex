// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'round_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RoundResult {
  int get playerScore => throw _privateConstructorUsedError;
  int get botScore => throw _privateConstructorUsedError;
  int get eloChange => throw _privateConstructorUsedError;
  int get newElo => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RoundResultCopyWith<RoundResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoundResultCopyWith<$Res> {
  factory $RoundResultCopyWith(
          RoundResult value, $Res Function(RoundResult) then) =
      _$RoundResultCopyWithImpl<$Res, RoundResult>;
  @useResult
  $Res call({int playerScore, int botScore, int eloChange, int newElo});
}

/// @nodoc
class _$RoundResultCopyWithImpl<$Res, $Val extends RoundResult>
    implements $RoundResultCopyWith<$Res> {
  _$RoundResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerScore = null,
    Object? botScore = null,
    Object? eloChange = null,
    Object? newElo = null,
  }) {
    return _then(_value.copyWith(
      playerScore: null == playerScore
          ? _value.playerScore
          : playerScore // ignore: cast_nullable_to_non_nullable
              as int,
      botScore: null == botScore
          ? _value.botScore
          : botScore // ignore: cast_nullable_to_non_nullable
              as int,
      eloChange: null == eloChange
          ? _value.eloChange
          : eloChange // ignore: cast_nullable_to_non_nullable
              as int,
      newElo: null == newElo
          ? _value.newElo
          : newElo // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoundResultImplCopyWith<$Res>
    implements $RoundResultCopyWith<$Res> {
  factory _$$RoundResultImplCopyWith(
          _$RoundResultImpl value, $Res Function(_$RoundResultImpl) then) =
      __$$RoundResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int playerScore, int botScore, int eloChange, int newElo});
}

/// @nodoc
class __$$RoundResultImplCopyWithImpl<$Res>
    extends _$RoundResultCopyWithImpl<$Res, _$RoundResultImpl>
    implements _$$RoundResultImplCopyWith<$Res> {
  __$$RoundResultImplCopyWithImpl(
      _$RoundResultImpl _value, $Res Function(_$RoundResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerScore = null,
    Object? botScore = null,
    Object? eloChange = null,
    Object? newElo = null,
  }) {
    return _then(_$RoundResultImpl(
      playerScore: null == playerScore
          ? _value.playerScore
          : playerScore // ignore: cast_nullable_to_non_nullable
              as int,
      botScore: null == botScore
          ? _value.botScore
          : botScore // ignore: cast_nullable_to_non_nullable
              as int,
      eloChange: null == eloChange
          ? _value.eloChange
          : eloChange // ignore: cast_nullable_to_non_nullable
              as int,
      newElo: null == newElo
          ? _value.newElo
          : newElo // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$RoundResultImpl extends _RoundResult {
  const _$RoundResultImpl(
      {required this.playerScore,
      required this.botScore,
      required this.eloChange,
      required this.newElo})
      : super._();

  @override
  final int playerScore;
  @override
  final int botScore;
  @override
  final int eloChange;
  @override
  final int newElo;

  @override
  String toString() {
    return 'RoundResult(playerScore: $playerScore, botScore: $botScore, eloChange: $eloChange, newElo: $newElo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoundResultImpl &&
            (identical(other.playerScore, playerScore) ||
                other.playerScore == playerScore) &&
            (identical(other.botScore, botScore) ||
                other.botScore == botScore) &&
            (identical(other.eloChange, eloChange) ||
                other.eloChange == eloChange) &&
            (identical(other.newElo, newElo) || other.newElo == newElo));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, playerScore, botScore, eloChange, newElo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoundResultImplCopyWith<_$RoundResultImpl> get copyWith =>
      __$$RoundResultImplCopyWithImpl<_$RoundResultImpl>(this, _$identity);
}

abstract class _RoundResult extends RoundResult {
  const factory _RoundResult(
      {required final int playerScore,
      required final int botScore,
      required final int eloChange,
      required final int newElo}) = _$RoundResultImpl;
  const _RoundResult._() : super._();

  @override
  int get playerScore;
  @override
  int get botScore;
  @override
  int get eloChange;
  @override
  int get newElo;
  @override
  @JsonKey(ignore: true)
  _$$RoundResultImplCopyWith<_$RoundResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
