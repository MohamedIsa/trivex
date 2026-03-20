/// GameConfig — passed from the Topic screen through to the Loading/Game screens.
class GameConfig {
  final String topic;

  /// One of: 'easy' | 'medium' | 'hard'
  final String difficulty;

  const GameConfig({required this.topic, required this.difficulty});

  factory GameConfig.fromJson(Map<String, dynamic> json) => GameConfig(
        topic: json['topic'] as String,
        difficulty: json['difficulty'] as String,
      );

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'difficulty': difficulty,
      };
}
