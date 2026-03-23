import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

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

/// Hive [TypeAdapter] for [Question] (typeId: 1).
///
/// Serialises all six fields so full Question objects can be persisted
/// in the offline-questions cache box.
class QuestionAdapter extends TypeAdapter<Question> {
  @override
  final int typeId = 1;

  @override
  Question read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Question(
      id: fields[0] as String,
      question: fields[1] as String,
      options: List<String>.from(fields[2] as List),
      correctIndex: fields[3] as int,
      explanation: fields[4] as String,
      timeLimit: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.question)
      ..writeByte(2)
      ..write(obj.options)
      ..writeByte(3)
      ..write(obj.correctIndex)
      ..writeByte(4)
      ..write(obj.explanation)
      ..writeByte(5)
      ..write(obj.timeLimit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
