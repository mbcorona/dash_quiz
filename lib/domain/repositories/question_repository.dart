import '../entities/question.dart';

/// Where questions come from. Implemented in the data layer.
abstract interface class QuestionRepository {
  Future<List<Question>> getQuestions();
}
