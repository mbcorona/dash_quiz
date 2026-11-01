import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../domain/entities/answer_side.dart';
import '../../domain/logic/hold_selector.dart';
import '../../domain/logic/quiz_session.dart';
import '../../domain/repositories/question_repository.dart';
import '../../domain/services/tilt_source.dart';

enum QuizStatus { loading, answering, revealed, finished }

/// Which answer is being held and how far its timer has run (`0..1`).
typedef Hold = ({AnswerSide? side, double progress});

/// Drives the quiz screen: loads questions, turns leaning into answers and
/// moves between questions. Holds no widgets, so it can be unit-tested.
class QuizController extends ChangeNotifier {
  QuizController({
    required this._questions,
    required this._tilt,
    HoldSelector? selector,
    this._random,
    this.revealSeconds = 2.0,
  }) : _selector = selector ?? HoldSelector();

  /// How long the right answer stays on screen before the next question.
  final double revealSeconds;

  final QuestionRepository _questions;
  final TiltSource _tilt;
  final HoldSelector _selector;
  final Random? _random;

  /// Changes every frame while an answer is held, so it has its own notifier
  /// and only the progress rings repaint.
  final ValueNotifier<Hold> hold = ValueNotifier((side: null, progress: 0));

  QuizStatus _status = QuizStatus.loading;
  QuizSession? _session;
  AnswerSide? _selectedSide;
  bool? _answeredCorrectly;
  AnswerSide? _pressedSide;
  double _revealRemaining = 0;

  QuizStatus get status => _status;

  /// Only valid once [status] is past [QuizStatus.loading].
  QuizSession get session => _session!;

  /// The side the player picked for the question being revealed.
  AnswerSide? get selectedSide => _selectedSide;

  /// Whether the answer being revealed was right.
  bool? get answeredCorrectly => _answeredCorrectly;

  /// Current lean in `-1..1`; pressing an answer counts as a full lean.
  double get lean => switch (_pressedSide) {
    AnswerSide.left => -1,
    AnswerSide.right => 1,
    null => _tilt.lean,
  };

  Future<void> start() async {
    _tilt.start();
    _session = QuizSession(await _questions.getQuestions(), random: _random);
    _beginQuestion();
    notifyListeners();
  }

  Future<void> restart() => start();

  /// Pressing and holding an answer works like leaning toward it; pass null
  /// when the press ends.
  void press(AnswerSide? side) => _pressedSide = side;

  /// Advances the quiz by [dt] seconds. Call once per frame.
  void tick(double dt) {
    switch (_status) {
      case QuizStatus.answering:
        final chosen = _selector.update(lean, dt);
        hold.value = (side: _selector.side, progress: _selector.progress);
        if (chosen != null) _answer(chosen);
      case QuizStatus.revealed:
        _revealRemaining -= dt;
        if (_revealRemaining <= 0) _next();
      case QuizStatus.loading || QuizStatus.finished:
        break;
    }
  }

  @override
  void dispose() {
    _tilt.dispose();
    hold.dispose();
    super.dispose();
  }

  void _beginQuestion() {
    _status = QuizStatus.answering;
    _selectedSide = null;
    _answeredCorrectly = null;
    _selector.reset();
    hold.value = (side: null, progress: 0);
  }

  void _answer(AnswerSide side) {
    _selectedSide = side;
    _answeredCorrectly = session.answer(side);
    _status = QuizStatus.revealed;
    _revealRemaining = revealSeconds;
    notifyListeners();
  }

  void _next() {
    if (session.advance()) {
      _beginQuestion();
    } else {
      _status = QuizStatus.finished;
    }
    notifyListeners();
  }
}
