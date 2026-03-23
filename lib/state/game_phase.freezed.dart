// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_phase.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$GameRound {
  List<Question> get questions => throw _privateConstructorUsedError;
  String get topic => throw _privateConstructorUsedError;
  String get difficulty => throw _privateConstructorUsedError;

  /// Language code for the current round: 'en' or 'ar'.
  String get language => throw _privateConstructorUsedError;

  /// Index of the currently displayed question (0-based).
  int get currentIndex => throw _privateConstructorUsedError;
  int get playerScore => throw _privateConstructorUsedError;
  int get botScore => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GameRoundCopyWith<GameRound> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameRoundCopyWith<$Res> {
  factory $GameRoundCopyWith(GameRound value, $Res Function(GameRound) then) =
      _$GameRoundCopyWithImpl<$Res, GameRound>;
  @useResult
  $Res call(
      {List<Question> questions,
      String topic,
      String difficulty,
      String language,
      int currentIndex,
      int playerScore,
      int botScore});
}

/// @nodoc
class _$GameRoundCopyWithImpl<$Res, $Val extends GameRound>
    implements $GameRoundCopyWith<$Res> {
  _$GameRoundCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questions = null,
    Object? topic = null,
    Object? difficulty = null,
    Object? language = null,
    Object? currentIndex = null,
    Object? playerScore = null,
    Object? botScore = null,
  }) {
    return _then(_value.copyWith(
      questions: null == questions
          ? _value.questions
          : questions // ignore: cast_nullable_to_non_nullable
              as List<Question>,
      topic: null == topic
          ? _value.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      playerScore: null == playerScore
          ? _value.playerScore
          : playerScore // ignore: cast_nullable_to_non_nullable
              as int,
      botScore: null == botScore
          ? _value.botScore
          : botScore // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameRoundImplCopyWith<$Res>
    implements $GameRoundCopyWith<$Res> {
  factory _$$GameRoundImplCopyWith(
          _$GameRoundImpl value, $Res Function(_$GameRoundImpl) then) =
      __$$GameRoundImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Question> questions,
      String topic,
      String difficulty,
      String language,
      int currentIndex,
      int playerScore,
      int botScore});
}

/// @nodoc
class __$$GameRoundImplCopyWithImpl<$Res>
    extends _$GameRoundCopyWithImpl<$Res, _$GameRoundImpl>
    implements _$$GameRoundImplCopyWith<$Res> {
  __$$GameRoundImplCopyWithImpl(
      _$GameRoundImpl _value, $Res Function(_$GameRoundImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questions = null,
    Object? topic = null,
    Object? difficulty = null,
    Object? language = null,
    Object? currentIndex = null,
    Object? playerScore = null,
    Object? botScore = null,
  }) {
    return _then(_$GameRoundImpl(
      questions: null == questions
          ? _value._questions
          : questions // ignore: cast_nullable_to_non_nullable
              as List<Question>,
      topic: null == topic
          ? _value.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      playerScore: null == playerScore
          ? _value.playerScore
          : playerScore // ignore: cast_nullable_to_non_nullable
              as int,
      botScore: null == botScore
          ? _value.botScore
          : botScore // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$GameRoundImpl extends _GameRound {
  const _$GameRoundImpl(
      {required final List<Question> questions,
      required this.topic,
      required this.difficulty,
      this.language = 'en',
      required this.currentIndex,
      required this.playerScore,
      required this.botScore})
      : _questions = questions,
        super._();

  final List<Question> _questions;
  @override
  List<Question> get questions {
    if (_questions is EqualUnmodifiableListView) return _questions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_questions);
  }

  @override
  final String topic;
  @override
  final String difficulty;

  /// Language code for the current round: 'en' or 'ar'.
  @override
  @JsonKey()
  final String language;

  /// Index of the currently displayed question (0-based).
  @override
  final int currentIndex;
  @override
  final int playerScore;
  @override
  final int botScore;

  @override
  String toString() {
    return 'GameRound(questions: $questions, topic: $topic, difficulty: $difficulty, language: $language, currentIndex: $currentIndex, playerScore: $playerScore, botScore: $botScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameRoundImpl &&
            const DeepCollectionEquality()
                .equals(other._questions, _questions) &&
            (identical(other.topic, topic) || other.topic == topic) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.playerScore, playerScore) ||
                other.playerScore == playerScore) &&
            (identical(other.botScore, botScore) ||
                other.botScore == botScore));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_questions),
      topic,
      difficulty,
      language,
      currentIndex,
      playerScore,
      botScore);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GameRoundImplCopyWith<_$GameRoundImpl> get copyWith =>
      __$$GameRoundImplCopyWithImpl<_$GameRoundImpl>(this, _$identity);
}

abstract class _GameRound extends GameRound {
  const factory _GameRound(
      {required final List<Question> questions,
      required final String topic,
      required final String difficulty,
      final String language,
      required final int currentIndex,
      required final int playerScore,
      required final int botScore}) = _$GameRoundImpl;
  const _GameRound._() : super._();

  @override
  List<Question> get questions;
  @override
  String get topic;
  @override
  String get difficulty;
  @override

  /// Language code for the current round: 'en' or 'ar'.
  String get language;
  @override

  /// Index of the currently displayed question (0-based).
  int get currentIndex;
  @override
  int get playerScore;
  @override
  int get botScore;
  @override
  @JsonKey(ignore: true)
  _$$GameRoundImplCopyWith<_$GameRoundImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$GamePhase {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String topic, String difficulty) loading,
    required TResult Function(GameRound round) playing,
    required TResult Function(GameRound round, int? selectedIndex) revealing,
    required TResult Function(GameRound round, EloResult eloResult) finished,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String topic, String difficulty)? loading,
    TResult? Function(GameRound round)? playing,
    TResult? Function(GameRound round, int? selectedIndex)? revealing,
    TResult? Function(GameRound round, EloResult eloResult)? finished,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String topic, String difficulty)? loading,
    TResult Function(GameRound round)? playing,
    TResult Function(GameRound round, int? selectedIndex)? revealing,
    TResult Function(GameRound round, EloResult eloResult)? finished,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(LoadingPhase value) loading,
    required TResult Function(PlayingPhase value) playing,
    required TResult Function(RevealingPhase value) revealing,
    required TResult Function(FinishedPhase value) finished,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(LoadingPhase value)? loading,
    TResult? Function(PlayingPhase value)? playing,
    TResult? Function(RevealingPhase value)? revealing,
    TResult? Function(FinishedPhase value)? finished,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(LoadingPhase value)? loading,
    TResult Function(PlayingPhase value)? playing,
    TResult Function(RevealingPhase value)? revealing,
    TResult Function(FinishedPhase value)? finished,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GamePhaseCopyWith<$Res> {
  factory $GamePhaseCopyWith(GamePhase value, $Res Function(GamePhase) then) =
      _$GamePhaseCopyWithImpl<$Res, GamePhase>;
}

/// @nodoc
class _$GamePhaseCopyWithImpl<$Res, $Val extends GamePhase>
    implements $GamePhaseCopyWith<$Res> {
  _$GamePhaseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$IdlePhaseImplCopyWith<$Res> {
  factory _$$IdlePhaseImplCopyWith(
          _$IdlePhaseImpl value, $Res Function(_$IdlePhaseImpl) then) =
      __$$IdlePhaseImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$IdlePhaseImplCopyWithImpl<$Res>
    extends _$GamePhaseCopyWithImpl<$Res, _$IdlePhaseImpl>
    implements _$$IdlePhaseImplCopyWith<$Res> {
  __$$IdlePhaseImplCopyWithImpl(
      _$IdlePhaseImpl _value, $Res Function(_$IdlePhaseImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$IdlePhaseImpl implements IdlePhase {
  const _$IdlePhaseImpl();

  @override
  String toString() {
    return 'GamePhase.idle()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$IdlePhaseImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String topic, String difficulty) loading,
    required TResult Function(GameRound round) playing,
    required TResult Function(GameRound round, int? selectedIndex) revealing,
    required TResult Function(GameRound round, EloResult eloResult) finished,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String topic, String difficulty)? loading,
    TResult? Function(GameRound round)? playing,
    TResult? Function(GameRound round, int? selectedIndex)? revealing,
    TResult? Function(GameRound round, EloResult eloResult)? finished,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String topic, String difficulty)? loading,
    TResult Function(GameRound round)? playing,
    TResult Function(GameRound round, int? selectedIndex)? revealing,
    TResult Function(GameRound round, EloResult eloResult)? finished,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(LoadingPhase value) loading,
    required TResult Function(PlayingPhase value) playing,
    required TResult Function(RevealingPhase value) revealing,
    required TResult Function(FinishedPhase value) finished,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(LoadingPhase value)? loading,
    TResult? Function(PlayingPhase value)? playing,
    TResult? Function(RevealingPhase value)? revealing,
    TResult? Function(FinishedPhase value)? finished,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(LoadingPhase value)? loading,
    TResult Function(PlayingPhase value)? playing,
    TResult Function(RevealingPhase value)? revealing,
    TResult Function(FinishedPhase value)? finished,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class IdlePhase implements GamePhase {
  const factory IdlePhase() = _$IdlePhaseImpl;
}

/// @nodoc
abstract class _$$LoadingPhaseImplCopyWith<$Res> {
  factory _$$LoadingPhaseImplCopyWith(
          _$LoadingPhaseImpl value, $Res Function(_$LoadingPhaseImpl) then) =
      __$$LoadingPhaseImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String topic, String difficulty});
}

/// @nodoc
class __$$LoadingPhaseImplCopyWithImpl<$Res>
    extends _$GamePhaseCopyWithImpl<$Res, _$LoadingPhaseImpl>
    implements _$$LoadingPhaseImplCopyWith<$Res> {
  __$$LoadingPhaseImplCopyWithImpl(
      _$LoadingPhaseImpl _value, $Res Function(_$LoadingPhaseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? topic = null,
    Object? difficulty = null,
  }) {
    return _then(_$LoadingPhaseImpl(
      topic: null == topic
          ? _value.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$LoadingPhaseImpl implements LoadingPhase {
  const _$LoadingPhaseImpl({required this.topic, required this.difficulty});

  @override
  final String topic;
  @override
  final String difficulty;

  @override
  String toString() {
    return 'GamePhase.loading(topic: $topic, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadingPhaseImpl &&
            (identical(other.topic, topic) || other.topic == topic) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty));
  }

  @override
  int get hashCode => Object.hash(runtimeType, topic, difficulty);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadingPhaseImplCopyWith<_$LoadingPhaseImpl> get copyWith =>
      __$$LoadingPhaseImplCopyWithImpl<_$LoadingPhaseImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String topic, String difficulty) loading,
    required TResult Function(GameRound round) playing,
    required TResult Function(GameRound round, int? selectedIndex) revealing,
    required TResult Function(GameRound round, EloResult eloResult) finished,
  }) {
    return loading(topic, difficulty);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String topic, String difficulty)? loading,
    TResult? Function(GameRound round)? playing,
    TResult? Function(GameRound round, int? selectedIndex)? revealing,
    TResult? Function(GameRound round, EloResult eloResult)? finished,
  }) {
    return loading?.call(topic, difficulty);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String topic, String difficulty)? loading,
    TResult Function(GameRound round)? playing,
    TResult Function(GameRound round, int? selectedIndex)? revealing,
    TResult Function(GameRound round, EloResult eloResult)? finished,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(topic, difficulty);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(LoadingPhase value) loading,
    required TResult Function(PlayingPhase value) playing,
    required TResult Function(RevealingPhase value) revealing,
    required TResult Function(FinishedPhase value) finished,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(LoadingPhase value)? loading,
    TResult? Function(PlayingPhase value)? playing,
    TResult? Function(RevealingPhase value)? revealing,
    TResult? Function(FinishedPhase value)? finished,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(LoadingPhase value)? loading,
    TResult Function(PlayingPhase value)? playing,
    TResult Function(RevealingPhase value)? revealing,
    TResult Function(FinishedPhase value)? finished,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class LoadingPhase implements GamePhase {
  const factory LoadingPhase(
      {required final String topic,
      required final String difficulty}) = _$LoadingPhaseImpl;

  String get topic;
  String get difficulty;
  @JsonKey(ignore: true)
  _$$LoadingPhaseImplCopyWith<_$LoadingPhaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PlayingPhaseImplCopyWith<$Res> {
  factory _$$PlayingPhaseImplCopyWith(
          _$PlayingPhaseImpl value, $Res Function(_$PlayingPhaseImpl) then) =
      __$$PlayingPhaseImplCopyWithImpl<$Res>;
  @useResult
  $Res call({GameRound round});

  $GameRoundCopyWith<$Res> get round;
}

/// @nodoc
class __$$PlayingPhaseImplCopyWithImpl<$Res>
    extends _$GamePhaseCopyWithImpl<$Res, _$PlayingPhaseImpl>
    implements _$$PlayingPhaseImplCopyWith<$Res> {
  __$$PlayingPhaseImplCopyWithImpl(
      _$PlayingPhaseImpl _value, $Res Function(_$PlayingPhaseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? round = null,
  }) {
    return _then(_$PlayingPhaseImpl(
      round: null == round
          ? _value.round
          : round // ignore: cast_nullable_to_non_nullable
              as GameRound,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $GameRoundCopyWith<$Res> get round {
    return $GameRoundCopyWith<$Res>(_value.round, (value) {
      return _then(_value.copyWith(round: value));
    });
  }
}

/// @nodoc

class _$PlayingPhaseImpl implements PlayingPhase {
  const _$PlayingPhaseImpl({required this.round});

  @override
  final GameRound round;

  @override
  String toString() {
    return 'GamePhase.playing(round: $round)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayingPhaseImpl &&
            (identical(other.round, round) || other.round == round));
  }

  @override
  int get hashCode => Object.hash(runtimeType, round);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayingPhaseImplCopyWith<_$PlayingPhaseImpl> get copyWith =>
      __$$PlayingPhaseImplCopyWithImpl<_$PlayingPhaseImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String topic, String difficulty) loading,
    required TResult Function(GameRound round) playing,
    required TResult Function(GameRound round, int? selectedIndex) revealing,
    required TResult Function(GameRound round, EloResult eloResult) finished,
  }) {
    return playing(round);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String topic, String difficulty)? loading,
    TResult? Function(GameRound round)? playing,
    TResult? Function(GameRound round, int? selectedIndex)? revealing,
    TResult? Function(GameRound round, EloResult eloResult)? finished,
  }) {
    return playing?.call(round);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String topic, String difficulty)? loading,
    TResult Function(GameRound round)? playing,
    TResult Function(GameRound round, int? selectedIndex)? revealing,
    TResult Function(GameRound round, EloResult eloResult)? finished,
    required TResult orElse(),
  }) {
    if (playing != null) {
      return playing(round);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(LoadingPhase value) loading,
    required TResult Function(PlayingPhase value) playing,
    required TResult Function(RevealingPhase value) revealing,
    required TResult Function(FinishedPhase value) finished,
  }) {
    return playing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(LoadingPhase value)? loading,
    TResult? Function(PlayingPhase value)? playing,
    TResult? Function(RevealingPhase value)? revealing,
    TResult? Function(FinishedPhase value)? finished,
  }) {
    return playing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(LoadingPhase value)? loading,
    TResult Function(PlayingPhase value)? playing,
    TResult Function(RevealingPhase value)? revealing,
    TResult Function(FinishedPhase value)? finished,
    required TResult orElse(),
  }) {
    if (playing != null) {
      return playing(this);
    }
    return orElse();
  }
}

abstract class PlayingPhase implements GamePhase {
  const factory PlayingPhase({required final GameRound round}) =
      _$PlayingPhaseImpl;

  GameRound get round;
  @JsonKey(ignore: true)
  _$$PlayingPhaseImplCopyWith<_$PlayingPhaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RevealingPhaseImplCopyWith<$Res> {
  factory _$$RevealingPhaseImplCopyWith(_$RevealingPhaseImpl value,
          $Res Function(_$RevealingPhaseImpl) then) =
      __$$RevealingPhaseImplCopyWithImpl<$Res>;
  @useResult
  $Res call({GameRound round, int? selectedIndex});

  $GameRoundCopyWith<$Res> get round;
}

/// @nodoc
class __$$RevealingPhaseImplCopyWithImpl<$Res>
    extends _$GamePhaseCopyWithImpl<$Res, _$RevealingPhaseImpl>
    implements _$$RevealingPhaseImplCopyWith<$Res> {
  __$$RevealingPhaseImplCopyWithImpl(
      _$RevealingPhaseImpl _value, $Res Function(_$RevealingPhaseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? round = null,
    Object? selectedIndex = freezed,
  }) {
    return _then(_$RevealingPhaseImpl(
      round: null == round
          ? _value.round
          : round // ignore: cast_nullable_to_non_nullable
              as GameRound,
      selectedIndex: freezed == selectedIndex
          ? _value.selectedIndex
          : selectedIndex // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $GameRoundCopyWith<$Res> get round {
    return $GameRoundCopyWith<$Res>(_value.round, (value) {
      return _then(_value.copyWith(round: value));
    });
  }
}

/// @nodoc

class _$RevealingPhaseImpl implements RevealingPhase {
  const _$RevealingPhaseImpl({required this.round, this.selectedIndex});

  @override
  final GameRound round;

  /// The option index the player tapped, or `null` if the timer expired.
  @override
  final int? selectedIndex;

  @override
  String toString() {
    return 'GamePhase.revealing(round: $round, selectedIndex: $selectedIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RevealingPhaseImpl &&
            (identical(other.round, round) || other.round == round) &&
            (identical(other.selectedIndex, selectedIndex) ||
                other.selectedIndex == selectedIndex));
  }

  @override
  int get hashCode => Object.hash(runtimeType, round, selectedIndex);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RevealingPhaseImplCopyWith<_$RevealingPhaseImpl> get copyWith =>
      __$$RevealingPhaseImplCopyWithImpl<_$RevealingPhaseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String topic, String difficulty) loading,
    required TResult Function(GameRound round) playing,
    required TResult Function(GameRound round, int? selectedIndex) revealing,
    required TResult Function(GameRound round, EloResult eloResult) finished,
  }) {
    return revealing(round, selectedIndex);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String topic, String difficulty)? loading,
    TResult? Function(GameRound round)? playing,
    TResult? Function(GameRound round, int? selectedIndex)? revealing,
    TResult? Function(GameRound round, EloResult eloResult)? finished,
  }) {
    return revealing?.call(round, selectedIndex);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String topic, String difficulty)? loading,
    TResult Function(GameRound round)? playing,
    TResult Function(GameRound round, int? selectedIndex)? revealing,
    TResult Function(GameRound round, EloResult eloResult)? finished,
    required TResult orElse(),
  }) {
    if (revealing != null) {
      return revealing(round, selectedIndex);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(LoadingPhase value) loading,
    required TResult Function(PlayingPhase value) playing,
    required TResult Function(RevealingPhase value) revealing,
    required TResult Function(FinishedPhase value) finished,
  }) {
    return revealing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(LoadingPhase value)? loading,
    TResult? Function(PlayingPhase value)? playing,
    TResult? Function(RevealingPhase value)? revealing,
    TResult? Function(FinishedPhase value)? finished,
  }) {
    return revealing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(LoadingPhase value)? loading,
    TResult Function(PlayingPhase value)? playing,
    TResult Function(RevealingPhase value)? revealing,
    TResult Function(FinishedPhase value)? finished,
    required TResult orElse(),
  }) {
    if (revealing != null) {
      return revealing(this);
    }
    return orElse();
  }
}

abstract class RevealingPhase implements GamePhase {
  const factory RevealingPhase(
      {required final GameRound round,
      final int? selectedIndex}) = _$RevealingPhaseImpl;

  GameRound get round;

  /// The option index the player tapped, or `null` if the timer expired.
  int? get selectedIndex;
  @JsonKey(ignore: true)
  _$$RevealingPhaseImplCopyWith<_$RevealingPhaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FinishedPhaseImplCopyWith<$Res> {
  factory _$$FinishedPhaseImplCopyWith(
          _$FinishedPhaseImpl value, $Res Function(_$FinishedPhaseImpl) then) =
      __$$FinishedPhaseImplCopyWithImpl<$Res>;
  @useResult
  $Res call({GameRound round, EloResult eloResult});

  $GameRoundCopyWith<$Res> get round;
  $EloResultCopyWith<$Res> get eloResult;
}

/// @nodoc
class __$$FinishedPhaseImplCopyWithImpl<$Res>
    extends _$GamePhaseCopyWithImpl<$Res, _$FinishedPhaseImpl>
    implements _$$FinishedPhaseImplCopyWith<$Res> {
  __$$FinishedPhaseImplCopyWithImpl(
      _$FinishedPhaseImpl _value, $Res Function(_$FinishedPhaseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? round = null,
    Object? eloResult = null,
  }) {
    return _then(_$FinishedPhaseImpl(
      round: null == round
          ? _value.round
          : round // ignore: cast_nullable_to_non_nullable
              as GameRound,
      eloResult: null == eloResult
          ? _value.eloResult
          : eloResult // ignore: cast_nullable_to_non_nullable
              as EloResult,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $GameRoundCopyWith<$Res> get round {
    return $GameRoundCopyWith<$Res>(_value.round, (value) {
      return _then(_value.copyWith(round: value));
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $EloResultCopyWith<$Res> get eloResult {
    return $EloResultCopyWith<$Res>(_value.eloResult, (value) {
      return _then(_value.copyWith(eloResult: value));
    });
  }
}

/// @nodoc

class _$FinishedPhaseImpl implements FinishedPhase {
  const _$FinishedPhaseImpl({required this.round, required this.eloResult});

  @override
  final GameRound round;
  @override
  final EloResult eloResult;

  @override
  String toString() {
    return 'GamePhase.finished(round: $round, eloResult: $eloResult)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FinishedPhaseImpl &&
            (identical(other.round, round) || other.round == round) &&
            (identical(other.eloResult, eloResult) ||
                other.eloResult == eloResult));
  }

  @override
  int get hashCode => Object.hash(runtimeType, round, eloResult);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FinishedPhaseImplCopyWith<_$FinishedPhaseImpl> get copyWith =>
      __$$FinishedPhaseImplCopyWithImpl<_$FinishedPhaseImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String topic, String difficulty) loading,
    required TResult Function(GameRound round) playing,
    required TResult Function(GameRound round, int? selectedIndex) revealing,
    required TResult Function(GameRound round, EloResult eloResult) finished,
  }) {
    return finished(round, eloResult);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String topic, String difficulty)? loading,
    TResult? Function(GameRound round)? playing,
    TResult? Function(GameRound round, int? selectedIndex)? revealing,
    TResult? Function(GameRound round, EloResult eloResult)? finished,
  }) {
    return finished?.call(round, eloResult);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String topic, String difficulty)? loading,
    TResult Function(GameRound round)? playing,
    TResult Function(GameRound round, int? selectedIndex)? revealing,
    TResult Function(GameRound round, EloResult eloResult)? finished,
    required TResult orElse(),
  }) {
    if (finished != null) {
      return finished(round, eloResult);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(LoadingPhase value) loading,
    required TResult Function(PlayingPhase value) playing,
    required TResult Function(RevealingPhase value) revealing,
    required TResult Function(FinishedPhase value) finished,
  }) {
    return finished(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(LoadingPhase value)? loading,
    TResult? Function(PlayingPhase value)? playing,
    TResult? Function(RevealingPhase value)? revealing,
    TResult? Function(FinishedPhase value)? finished,
  }) {
    return finished?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(LoadingPhase value)? loading,
    TResult Function(PlayingPhase value)? playing,
    TResult Function(RevealingPhase value)? revealing,
    TResult Function(FinishedPhase value)? finished,
    required TResult orElse(),
  }) {
    if (finished != null) {
      return finished(this);
    }
    return orElse();
  }
}

abstract class FinishedPhase implements GamePhase {
  const factory FinishedPhase(
      {required final GameRound round,
      required final EloResult eloResult}) = _$FinishedPhaseImpl;

  GameRound get round;
  EloResult get eloResult;
  @JsonKey(ignore: true)
  _$$FinishedPhaseImplCopyWith<_$FinishedPhaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
