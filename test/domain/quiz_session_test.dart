import 'dart:math';

import 'package:dash_quiz/domain/entities/question.dart';
import 'package:dash_quiz/domain/logic/quiz_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const questions = [
    Question('q1', correct: 'a1', wrong: 'b1'),
    Question('q2', correct: 'a2', wrong: 'b2'),
  ];

  test('places the correct answer on correctSide', () {
    final session = QuizSession(questions, random: Random(1));
    expect(session.optionOn(session.correctSide), session.question.correct);
    expect(
      session.optionOn(session.correctSide.opposite),
      session.question.wrong,
    );
  });

  test('scores only correct answers', () {
    final session = QuizSession(questions, random: Random(1));
    expect(session.answer(session.correctSide.opposite), isFalse);
    expect(session.score, 0);
    session.advance();
    expect(session.answer(session.correctSide), isTrue);
    expect(session.score, 1);
  });

  test('advance walks every question once, then stops', () {
    final session = QuizSession(questions, random: Random(1));
    final seen = {session.question.text};
    expect(session.advance(), isTrue);
    seen.add(session.question.text);
    expect(session.isLastQuestion, isTrue);
    expect(session.advance(), isFalse);
    expect(seen, {'q1', 'q2'});
  });
}
