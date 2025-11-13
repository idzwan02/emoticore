// In: lib/quiz_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PopQuizQuestion {
  final String id;
  final String questionText;
  final List<String> answers;
  final int correctIndex;

  PopQuizQuestion({
    required this.id,
    required this.questionText,
    required this.answers,
    required this.correctIndex,
  });

  // Factory constructor to create a question from a Firestore document
  factory PopQuizQuestion.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PopQuizQuestion(
      id: doc.id,
      questionText: data['questionText'] ?? 'No question text',
      answers: List<String>.from(data['answers'] ?? []),
      correctIndex: data['correctIndex'] as int? ?? 0,
    );
  }
}