import 'package:dash_quiz/domain/entities/answer_side.dart';
import 'package:dash_quiz/domain/logic/hold_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HoldSelector selector;

  setUp(() {
    selector = HoldSelector(holdSeconds: 3);
    selector.update(0, 0.1); // level once, so it is armed
  });

  test('selects a side after it is held for the full time', () {
    expect(selector.update(-1, 1), isNull);
    expect(selector.side, AnswerSide.left);
    expect(selector.progress, closeTo(1 / 3, 1e-9));
    expect(selector.update(-1, 1), isNull);
    expect(selector.update(-1, 1.01), AnswerSide.left);
  });

  test('returning to level clears the hold', () {
    selector.update(1, 2);
    selector.update(0, 0.1);
    expect(selector.side, isNull);
    expect(selector.progress, 0);
  });

  test('switching sides starts a fresh timer', () {
    selector.update(-1, 2);
    selector.update(1, 1);
    expect(selector.side, AnswerSide.right);
    expect(selector.progress, closeTo(1 / 3, 1e-9));
  });

  test('a hold survives dipping below the engage threshold', () {
    selector.update(0.6, 1);
    selector.update(0.4, 1);
    expect(selector.side, AnswerSide.right);
    expect(selector.progress, closeTo(2 / 3, 1e-9));
  });

  test('a lean below the engage threshold does not start a hold', () {
    selector.update(0.4, 1);
    expect(selector.side, isNull);
  });

  test('after reset, a lean is ignored until the device is level again', () {
    selector.reset();
    expect(selector.update(-1, 5), isNull);
    expect(selector.side, isNull);
    selector.update(0, 0.1);
    selector.update(-1, 1);
    expect(selector.side, AnswerSide.left);
  });
}
