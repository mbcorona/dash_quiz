import '../entities/answer_side.dart';

/// Turns a stream of lean readings into a deliberate choice: lean to one side
/// and hold it there until the timer completes.
class HoldSelector {
  HoldSelector({
    this.holdSeconds = 2,
    this.engageLean = 0.5,
    this.releaseLean = 0.33,
  }) : assert(holdSeconds > 0),
       assert(releaseLean <= engageLean);

  /// How long a side must be held to select it.
  final double holdSeconds;

  /// Lean needed to start a selection, and the smaller lean that keeps it
  /// going, so a hand hovering at the threshold does not restart the timer.
  final double engageLean;
  final double releaseLean;

  AnswerSide? _side;
  double _progress = 0;
  // The device has to pass through level before a selection can start, so a
  // lean left over from the previous question does not answer the next one.
  bool _armed = false;

  /// The side currently being held, if any.
  AnswerSide? get side => _side;

  /// How far the hold timer has run, `0..1`.
  double get progress => _progress;

  /// Forgets the current hold and requires the device to return to level.
  void reset() {
    _side = null;
    _progress = 0;
    _armed = false;
  }

  /// Feeds one reading ([lean] in `-1..1`, negative is left) covering [dt]
  /// seconds. Returns the chosen side at the moment the hold completes.
  AnswerSide? update(double lean, double dt) {
    final target = _sideFor(lean);
    if (!_armed) {
      if (target != null) return null;
      _armed = true;
    }

    if (target == null) {
      _side = null;
      _progress = 0;
      return null;
    }
    _progress = (target == _side ? _progress : 0) + dt / holdSeconds;
    _side = target;
    if (_progress < 1) return null;

    reset();
    return target;
  }

  AnswerSide? _sideFor(double lean) {
    if (lean <= -engageLean ||
        (_side == AnswerSide.left && lean <= -releaseLean)) {
      return AnswerSide.left;
    }
    if (lean >= engageLean ||
        (_side == AnswerSide.right && lean >= releaseLean)) {
      return AnswerSide.right;
    }
    return null;
  }
}
