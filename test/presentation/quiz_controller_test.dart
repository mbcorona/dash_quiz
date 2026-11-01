import 'dart:math';

import 'package:dash_quiz/domain/entities/answer_side.dart';
import 'package:dash_quiz/domain/entities/question.dart';
import 'package:dash_quiz/domain/logic/hold_selector.dart';
import 'package:dash_quiz/domain/repositories/question_repository.dart';
import 'package:dash_quiz/domain/services/tilt_source.dart';
import 'package:dash_quiz/presentation/quiz/quiz_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuestions implements QuestionRepository {
  @override
  Future<List<Question>> getQuestions() async => const [
    Question('q1', correct: 'a1', wrong: 'b1'),
    Question('q2', correct: 'a2', wrong: 'b2'),
  ];
}

class _FakeTilt implements TiltSource {
  @override
  double lean = 0;

  @override
  void start() {}

  @override
  void dispose() {}
}

void main() {
  late _FakeTilt tilt;
  late QuizController controller;

  double leanFor(AnswerSide side) => side == AnswerSide.left ? -1 : 1;

  /// Levels the device, then holds [side] until it is selected.
  void hold(AnswerSide side) {
    tilt.lean = 0;
    controller.tick(0.1);
    tilt.lean = leanFor(side);
    controller.tick(1.6);
    controller.tick(1.6);
  }

  setUp(() async {
    tilt = _FakeTilt();
    controller = QuizController(
      questions: _FakeQuestions(),
      tilt: tilt,
      selector: HoldSelector(holdSeconds: 3),
      random: Random(3),
      revealSeconds: 2,
    );
    await controller.start();
  });

  tearDown(() => controller.dispose());

  test('starts on the first question', () {
    expect(controller.status, QuizStatus.answering);
    expect(controller.session.index, 0);
  });

  test('reports hold progress while leaning', () {
    controller.tick(0.1);
    tilt.lean = -1;
    controller.tick(1.5);
    expect(controller.hold.value.side, AnswerSide.left);
    expect(controller.hold.value.progress, closeTo(0.5, 1e-9));
  });

  test('holding the correct side reveals and scores', () {
    hold(controller.session.correctSide);
    expect(controller.status, QuizStatus.revealed);
    expect(controller.answeredCorrectly, isTrue);
    expect(controller.session.score, 1);
  });

  test('holding the wrong side reveals without scoring', () {
    final wrong = controller.session.correctSide.opposite;
    hold(wrong);
    expect(controller.answeredCorrectly, isFalse);
    expect(controller.selectedSide, wrong);
    expect(controller.session.score, 0);
  });

  test('moves to the next question after the reveal time', () {
    hold(controller.session.correctSide);
    controller.tick(1);
    expect(controller.status, QuizStatus.revealed);
    controller.tick(1.1);
    expect(controller.status, QuizStatus.answering);
    expect(controller.session.index, 1);
  });

  test('a lean left over from the last question does not answer the next', () {
    hold(controller.session.correctSide);
    controller.tick(2.1); // next question, device still leaning
    controller.tick(5);
    expect(controller.status, QuizStatus.answering);
    expect(controller.hold.value.side, isNull);
  });

  test('pressing an answer works like leaning toward it', () {
    controller.tick(0.1);
    controller.press(AnswerSide.right);
    controller.tick(1.6);
    controller.tick(1.6);
    expect(controller.selectedSide, AnswerSide.right);
  });

  test('finishes after the last question and can restart', () async {
    hold(controller.session.correctSide);
    controller.tick(2.1);
    hold(controller.session.correctSide);
    controller.tick(2.1);
    expect(controller.status, QuizStatus.finished);
    expect(controller.session.score, 2);

    await controller.restart();
    expect(controller.status, QuizStatus.answering);
    expect(controller.session.score, 0);
  });
}
