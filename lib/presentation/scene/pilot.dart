import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

enum PilotMood { flying, happy, sad }

/// Flies the player's character: steering, bobbing and reactions, plus each
/// character's own flourish (Dash flaps, La Calavera's hat sways). Attach to
/// the rig node that parents the models, and set [model] to the one shown.
class Pilot extends Component {
  /// Where the character should lean, `-1` (left) to `1` (right).
  double steer = 0;

  /// How far the character has climbed toward the answer being held, `0..1`.
  double lift = 0;

  final List<({Node node, vm.Quaternion rest, double sign})> _wings = [];
  ({Node node, vm.Quaternion rest, vm.Vector3 restPosition})? _hat;
  double _time = 0;
  double _x = 0;
  double _lift = 0;
  PilotMood _mood = PilotMood.flying;
  double _moodTime = 0;

  /// The model being flown; its wing and hat nodes are looked up by name.
  set model(Node model) {
    _wings.clear();
    for (final (name, sign) in [('WingPivot.L', 1.0), ('WingPivot.R', -1.0)]) {
      final wing = model.getChildByName(name);
      if (wing != null) {
        _wings.add((node: wing, rest: wing.rotation, sign: sign));
      }
    }
    final hat = model.getChildByName('Hat');
    _hat = hat == null
        ? null
        : (node: hat, rest: hat.rotation, restPosition: hat.position);
  }

  set mood(PilotMood mood) {
    if (mood == _mood) return;
    _mood = mood;
    _moodTime = 0;
  }

  @override
  void update(double deltaSeconds) {
    final dt = deltaSeconds;
    _time += dt;
    _moodTime += dt;

    // Ease toward the targets so the character glides rather than snaps.
    final ease = math.min(1.0, dt * 4);
    final targetX = steer * 0.8;
    _x += (targetX - _x) * ease;
    _lift += (lift - _lift) * ease;
    final lag = targetX - _x;

    var y = 1.5 + _lift * 0.7 + math.sin(_time * 2.2) * 0.12;
    var roll = -steer * 0.35 - lag * 0.3;
    var yaw = lag * 0.5;
    var pitch = 0.0;
    var flapSpeed = 14.0 + _lift * 8;
    var hatLift = 0.0;

    switch (_mood) {
      case PilotMood.flying:
        break;
      case PilotMood.happy:
        // A hop with a full spin, and a tip of the hat.
        final t = (_moodTime / 0.9).clamp(0.0, 1.0);
        y += math.sin(t * math.pi) * 0.9;
        yaw += t * math.pi * 2;
        flapSpeed = 24;
        hatLift = math.sin(t * math.pi) * 0.45;
      case PilotMood.sad:
        final t = (_moodTime / 0.4).clamp(0.0, 1.0);
        y -= t * 0.5;
        pitch = t * 0.35;
        roll +=
            math.sin(_moodTime * 18) *
            0.08 *
            (1 - (_moodTime / 1.2).clamp(0.0, 1.0));
        flapSpeed = 7;
    }

    node.position = vm.Vector3(_x, y, 0);
    node.rotation =
        vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), yaw) *
        vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), roll) *
        vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), pitch);

    final flap = math.sin(_time * flapSpeed) * 0.55;
    for (final wing in _wings) {
      wing.node.rotation =
          wing.rest *
          vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), flap * wing.sign);
    }

    if (_hat case final hat?) {
      // The hat sways with the bobbing and tips into turns.
      final sway = math.sin(_time * 2.2) * 0.05 - steer * 0.12;
      hat.node.rotation =
          hat.rest * vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), sway);
      hat.node.position = hat.restPosition + vm.Vector3(0, hatLift, 0);
    }
  }
}
