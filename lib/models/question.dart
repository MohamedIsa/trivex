/// Question model — deserialized from the Worker API response.
class Question {
  final String id;
  final String question;
  final List<String> options; // always length 4
  final int correctIndex; // 0–3
  final String explanation;

  const Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>;
    return Question(
      id: json['id'].toString(),
      question: json['question'] as String,
      options: rawOptions.map((o) => o.toString()).toList(),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      };
}
