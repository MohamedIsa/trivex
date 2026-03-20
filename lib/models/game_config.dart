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
  }) = _GameConfig;

  factory GameConfig.fromJson(Map<String, dynamic> json) => GameConfig(
        topic: json['topic'] as String,
        difficulty: json['difficulty'] as String,
      );

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'difficulty': difficulty,
      };
}
