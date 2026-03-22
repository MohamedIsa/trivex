import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_config.freezed.dart';

/// GameConfig — passed from the Topic screen through to the Loading/Game screens.
@Freezed(fromJson: false, toJson: false)
class GameConfig with _$GameConfig {
  const GameConfig._();

  const factory GameConfig({
    required String topic,

    /// One of: 'easy' | 'medium' | 'hard'
    required String difficulty,

    /// Number of questions per round.
    required int count,

    /// Language code: 'en' (English) or 'ar' (Arabic).
    @Default('en') String language,
  }) = _GameConfig;

  factory GameConfig.fromJson(Map<String, dynamic> json) => GameConfig(
        topic: json['topic'] as String,
        difficulty: json['difficulty'] as String,
        count: json['count'] as int? ?? 10,
        language: json['language'] as String? ?? 'en',
      );

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'difficulty': difficulty,
        'count': count,
        'language': language,
      };
}
