import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Size, Widget;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

enum _BoardState { hidden, flyingIn, idle, correct, wrongPick, wrongOther }

/// A floating board in the sky that shows one answer. Its face is a live
/// Flutter widget rendered onto a 3D surface.
class AnswerBoard extends Component {
  AnswerBoard._(this._sideSign, this._frame);

  /// Logical size the face widget is laid out at.
  static const Size faceSize = Size(260, 230);

  static const double _height = 1.6;
  static const double _restY = 4.2;
  static const double _restZ = 1.5;
  static const double _flyInSeconds = 0.9;

  static final vm.Vector4 _blue = vm.Vector4(0.02, 0.33, 0.69, 1);
  static final vm.Vector4 _green = vm.Vector4(0.10, 0.72, 0.32, 1);
  static final vm.Vector4 _red = vm.Vector4(0.86, 0.18, 0.18, 1);
  static final vm.Vector4 _gray = vm.Vector4(0.45, 0.52, 0.62, 1);

  /// Builds a board node for the left (`-1`) or right (`1`) side showing
  /// [face]. Returns the node to add to the scene and its controller.
  static (Node, AnswerBoard) create({
    required double sideSign,
    required Widget face,
  }) {
    final width = _height * faceSize.aspectRatio;
    final frame = PhysicallyBasedMaterial()
      ..baseColorFactor = _blue
      ..metallicFactor = 0
      ..roughnessFactor = 0.5;
    final board = AnswerBoard._(sideSign, frame);
    final node = Node()
      ..add(
        Node(
          mesh: Mesh(
            CuboidGeometry(vm.Vector3(width + 0.16, _height + 0.16, 0.16)),
            frame,
          ),
        ),
      )
      ..add(
        // Sits just proud of the frame, on the camera's side.
        Node()
          ..position = vm.Vector3(0, 0, -0.085)
          ..addComponent(
            WidgetComponent(
              child: face,
              size: faceSize,
              pixelRatio: 2,
              geometry: _faceQuad(width, _height),
              input: WidgetInput.manual,
            ),
          ),
      )
      ..addComponent(board);
    return (node, board);
  }

  /// A quad seen from -Z (where the camera is) with the texture the right
  /// way round. The component's built-in quad reads mirrored from this side.
  static Geometry _faceQuad(double width, double height) {
    final hw = width / 2;
    final hh = height / 2;
    return MeshGeometry.fromArrays(
      positions: Float32List.fromList([
        hw, -hh, 0, -hw, -hh, 0, -hw, hh, 0, hw, hh, 0, //
      ]),
      texCoords: Float32List.fromList([1, 1, 0, 1, 0, 0, 1, 0]),
      indices: [0, 1, 3, 3, 1, 2],
    );
  }

  final double _sideSign;
  final PhysicallyBasedMaterial _frame;

  /// Whether this board is the one being held, which pulls it forward.
  bool highlighted = false;

  _BoardState _state = _BoardState.hidden;
  double _stateTime = 0;
  double _time = 0;
  double _highlight = 0;

  /// Sends the board flying in from the distance for a new question.
  void present() => _enter(_BoardState.flyingIn, _blue);

  void showCorrect() => _enter(_BoardState.correct, _green);

  /// The player picked this board and it was wrong: it drops out of the sky.
  void showWrongPick() => _enter(_BoardState.wrongPick, _red);

  void showWrongOther() => _enter(_BoardState.wrongOther, _gray);

  void hide() => _enter(_BoardState.hidden, _blue);

  void _enter(_BoardState state, vm.Vector4 frameColor) {
    _state = state;
    _stateTime = 0;
    _frame.baseColorFactor = frameColor;
  }

  @override
  void update(double deltaSeconds) {
    _time += deltaSeconds;
    _stateTime += deltaSeconds;
    _highlight +=
        ((highlighted ? 1.0 : 0.0) - _highlight) *
        math.min(1.0, deltaSeconds * 8);

    if (_state == _BoardState.flyingIn && _stateTime >= _flyInSeconds) {
      _state = _BoardState.idle;
    }

    final phase = _sideSign * 0.9;
    var x = _sideSign * 1.03;
    var y = _restY + math.sin(_time * 1.6 + phase) * 0.07;
    var z = _restZ - _highlight * 0.6;
    var scale = 1.0 + _highlight * 0.06;
    // Angled slightly toward the middle, with a slow sway.
    var yaw = _sideSign * 0.16 + math.sin(_time * 0.9 + phase) * 0.07;
    var roll = math.sin(_time * 1.1 + phase) * 0.03;

    switch (_state) {
      case _BoardState.hidden:
        y = -200;
      case _BoardState.flyingIn:
        final t = 1 - math.pow(1 - _stateTime / _flyInSeconds, 3).toDouble();
        z += (1 - t) * 60;
        y += (1 - t) * 5;
        x += (1 - t) * _sideSign * 4;
      case _BoardState.correct:
        final t = (_stateTime / 0.45).clamp(0.0, 1.0);
        scale += math.sin(t * math.pi) * 0.14;
      case _BoardState.wrongPick:
        y -= 7 * _stateTime * _stateTime;
        roll += _sideSign * _stateTime * 1.6;
        yaw += _stateTime * 0.8;
      case _BoardState.idle || _BoardState.wrongOther:
        break;
    }

    node.position = vm.Vector3(x, y, z);
    node.scale = vm.Vector3.all(scale);
    node.rotation =
        vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), yaw) *
        vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), roll);
  }
}
