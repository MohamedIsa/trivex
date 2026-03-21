import 'package:freezed_annotation/freezed_annotation.dart';

part 'question.freezed.dart';

/// Question model — deserialized from the Worker API response.
@Freezed(fromJson: false, toJson: false)
class Question with _$Question {
  const Question._();

  const factory Question({
    required String id,
    required String question,
    required List<String> options, // always length 4
    required int correctIndex, // 0–3
    required String explanation,
    required int timeLimit, // seconds, 10–30 (default 15)
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>;
    return Question(
      id: json['id'].toString(),
      question: json['question'] as String,
      options: rawOptions.map((o) => o.toString()).toList(),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
      timeLimit: (json['timeLimit'] as int?) ?? 15,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'timeLimit': timeLimit,
      };
}
