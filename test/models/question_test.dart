import 'package:flutter_test/flutter_test.dart';
import 'package:trivex/models/question.dart';

void main() {
  group('Question.fromJson', () {
    final sampleJson = {
      'id': '1',
      'question': 'What is the capital of France?',
      'options': ['London', 'Paris', 'Berlin', 'Madrid'],
      'correctIndex': 1,
      'explanation': 'Paris is the capital and largest city of France.',
    };

    test('parses all fields correctly', () {
      final q = Question.fromJson(sampleJson);
      expect(q.id, '1');
      expect(q.question, 'What is the capital of France?');
      expect(q.options, ['London', 'Paris', 'Berlin', 'Madrid']);
      expect(q.options.length, 4);
      expect(q.correctIndex, 1);
      expect(q.explanation, 'Paris is the capital and largest city of France.');
    });

    test('correctIndex is an int', () {
      final q = Question.fromJson(sampleJson);
      expect(q.correctIndex, isA<int>());
    });

    test('handles numeric id as string', () {
      final jsonWithNumericId = {...sampleJson, 'id': 42};
      final q = Question.fromJson(jsonWithNumericId);
      expect(q.id, '42');
    });

    test('options list has exactly 4 items', () {
      final q = Question.fromJson(sampleJson);
      expect(q.options.length, 4);
    });
  });
}
