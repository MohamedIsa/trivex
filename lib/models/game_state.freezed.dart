// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$GameState {
  List<Question> get questions => throw _privateConstructorUsedError;
  String get topic => throw _privateConstructorUsedError;
  String get difficulty => throw _privateConstructorUsedError;

  /// Index of the currently displayed question (0–9).
  int get currentIndex => throw _privateConstructorUsedError;
  int get playerScore => throw _privateConstructorUsedError;
  int get botScore => throw _privateConstructorUsedError;

  /// The option index the player tapped, or null if no selection has been made.
  int? get selectedIndex => throw _privateConstructorUsedError;

  /// True while the answer reveal animation / panel is visible.
  bool get isRevealing => throw _privateConstructorUsedError;

  /// True after the 10th question has been answered / timed out.
  bool get isGameOver => throw _privateConstructorUsedError;

  /// Populated by [GameStateNotifier] when [isGameOver] becomes true.
  EloResult? get eloResult => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GameStateCopyWith<GameState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateCopyWith<$Res> {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) then) =
      _$GameStateCopyWithImpl<$Res, GameState>;
  @useResult
  $Res call(
      {List<Question> questions,
      String topic,
      String difficulty,
      int currentIndex,
      int playerScore,
      int botScore,
      int? selectedIndex,
      bool isRevealing,
      bool isGameOver,
      EloResult? eloResult});

  $EloResultCopyWith<$Res>? get eloResult;
}

/// @nodoc
class _$GameStateCopyWithImpl<$Res, $Val extends GameState>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._value, this._then);

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
    Object? currentIndex = null,
    Object? playerScore = null,
    Object? botScore = null,
    Object? selectedIndex = freezed,
    Object? isRevealing = null,
    Object? isGameOver = null,
    Object? eloResult = freezed,
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
      selectedIndex: freezed == selectedIndex
          ? _value.selectedIndex
          : selectedIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      isRevealing: null == isRevealing
          ? _value.isRevealing
          : isRevealing // ignore: cast_nullable_to_non_nullable
              as bool,
      isGameOver: null == isGameOver
          ? _value.isGameOver
          : isGameOver // ignore: cast_nullable_to_non_nullable
              as bool,
      eloResult: freezed == eloResult
          ? _value.eloResult
          : eloResult // ignore: cast_nullable_to_non_nullable
              as EloResult?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $EloResultCopyWith<$Res>? get eloResult {
    if (_value.eloResult == null) {
      return null;
    }

    return $EloResultCopyWith<$Res>(_value.eloResult!, (value) {
      return _then(_value.copyWith(eloResult: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GameStateImplCopyWith<$Res>
    implements $GameStateCopyWith<$Res> {
  factory _$$GameStateImplCopyWith(
          _$GameStateImpl value, $Res Function(_$GameStateImpl) then) =
      __$$GameStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Question> questions,
      String topic,
      String difficulty,
      int currentIndex,
      int playerScore,
      int botScore,
      int? selectedIndex,
      bool isRevealing,
      bool isGameOver,
      EloResult? eloResult});

  @override
  $EloResultCopyWith<$Res>? get eloResult;
}

/// @nodoc
class __$$GameStateImplCopyWithImpl<$Res>
    extends _$GameStateCopyWithImpl<$Res, _$GameStateImpl>
    implements _$$GameStateImplCopyWith<$Res> {
  __$$GameStateImplCopyWithImpl(
      _$GameStateImpl _value, $Res Function(_$GameStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questions = null,
    Object? topic = null,
    Object? difficulty = null,
    Object? currentIndex = null,
    Object? playerScore = null,
    Object? botScore = null,
    Object? selectedIndex = freezed,
    Object? isRevealing = null,
    Object? isGameOver = null,
    Object? eloResult = freezed,
  }) {
    return _then(_$GameStateImpl(
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
      selectedIndex: freezed == selectedIndex
          ? _value.selectedIndex
          : selectedIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      isRevealing: null == isRevealing
          ? _value.isRevealing
          : isRevealing // ignore: cast_nullable_to_non_nullable
              as bool,
      isGameOver: null == isGameOver
          ? _value.isGameOver
          : isGameOver // ignore: cast_nullable_to_non_nullable
              as bool,
      eloResult: freezed == eloResult
          ? _value.eloResult
          : eloResult // ignore: cast_nullable_to_non_nullable
              as EloResult?,
    ));
  }
}

/// @nodoc

class _$GameStateImpl extends _GameState {
  const _$GameStateImpl(
      {required final List<Question> questions,
      required this.topic,
      required this.difficulty,
      required this.currentIndex,
      required this.playerScore,
      required this.botScore,
      this.selectedIndex,
      required this.isRevealing,
      required this.isGameOver,
      this.eloResult})
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

  /// Index of the currently displayed question (0–9).
  @override
  final int currentIndex;
  @override
  final int playerScore;
  @override
  final int botScore;

  /// The option index the player tapped, or null if no selection has been made.
  @override
  final int? selectedIndex;

  /// True while the answer reveal animation / panel is visible.
  @override
  final bool isRevealing;

  /// True after the 10th question has been answered / timed out.
  @override
  final bool isGameOver;

  /// Populated by [GameStateNotifier] when [isGameOver] becomes true.
  @override
  final EloResult? eloResult;

  @override
  String toString() {
    return 'GameState(questions: $questions, topic: $topic, difficulty: $difficulty, currentIndex: $currentIndex, playerScore: $playerScore, botScore: $botScore, selectedIndex: $selectedIndex, isRevealing: $isRevealing, isGameOver: $isGameOver, eloResult: $eloResult)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateImpl &&
            const DeepCollectionEquality()
                .equals(other._questions, _questions) &&
            (identical(other.topic, topic) || other.topic == topic) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.playerScore, playerScore) ||
                other.playerScore == playerScore) &&
            (identical(other.botScore, botScore) ||
                other.botScore == botScore) &&
            (identical(other.selectedIndex, selectedIndex) ||
                other.selectedIndex == selectedIndex) &&
            (identical(other.isRevealing, isRevealing) ||
                other.isRevealing == isRevealing) &&
            (identical(other.isGameOver, isGameOver) ||
                other.isGameOver == isGameOver) &&
            (identical(other.eloResult, eloResult) ||
                other.eloResult == eloResult));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_questions),
      topic,
      difficulty,
      currentIndex,
      playerScore,
      botScore,
      selectedIndex,
      isRevealing,
      isGameOver,
      eloResult);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      __$$GameStateImplCopyWithImpl<_$GameStateImpl>(this, _$identity);
}

abstract class _GameState extends GameState {
  const factory _GameState(
      {required final List<Question> questions,
      required final String topic,
      required final String difficulty,
      required final int currentIndex,
      required final int playerScore,
      required final int botScore,
      final int? selectedIndex,
      required final bool isRevealing,
      required final bool isGameOver,
      final EloResult? eloResult}) = _$GameStateImpl;
  const _GameState._() : super._();

  @override
  List<Question> get questions;
  @override
  String get topic;
  @override
  String get difficulty;
  @override

  /// Index of the currently displayed question (0–9).
  int get currentIndex;
  @override
  int get playerScore;
  @override
  int get botScore;
  @override

  /// The option index the player tapped, or null if no selection has been made.
  int? get selectedIndex;
  @override

  /// True while the answer reveal animation / panel is visible.
  bool get isRevealing;
  @override

  /// True after the 10th question has been answered / timed out.
  bool get isGameOver;
  @override

  /// Populated by [GameStateNotifier] when [isGameOver] becomes true.
  EloResult? get eloResult;
  @override
  @JsonKey(ignore: true)
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
