import 'dart:math';

import '../entities/answer_side.dart';
import '../entities/question.dart';

/// One play-through of the quiz: question order, where the correct answer
/// sits, and the score.
class QuizSession {
  QuizSession(List<Question> questions, {Random? random})
    : assert(questions.isNotEmpty),
      _random = random ?? Random(),
      _questions = [...questions] {
    _questions.shuffle(_random);
    _correctSide = _pickSide();
  }

  final Random _random;
  final List<Question> _questions;
  int _index = 0;
  int _score = 0;
  late AnswerSide _correctSide;

  int get index => _index;
  int get length => _questions.length;
  int get score => _score;
  Question get question => _questions[_index];
  AnswerSide get correctSide => _correctSide;
  bool get isLastQuestion => _index == _questions.length - 1;

  /// The answer text shown on [side] for the current question.
  String optionOn(AnswerSide side) =>
      side == _correctSide ? question.correct : question.wrong;

  /// Records an answer to the current question. Returns whether it was right.
  bool answer(AnswerSide side) {
    final correct = side == _correctSide;
    if (correct) _score++;
    return correct;
  }

  /// Moves to the next question. Returns false when there are none left.
  bool advance() {
    if (isLastQuestion) return false;
    _index++;
    _correctSide = _pickSide();
    return true;
  }

  AnswerSide _pickSide() =>
      _random.nextBool() ? AnswerSide.left : AnswerSide.right;
}
