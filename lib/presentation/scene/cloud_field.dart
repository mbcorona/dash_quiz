import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// A layer of clouds streaming past, which is what makes Dash look like
/// they are flying. Attach to an empty node.
class CloudField extends Component {
  CloudField({this.count = 20, this.speed = 9});

  final int count;
  final double speed;

  static const double _farZ = 70;
  static const double _nearZ = -14;

  final math.Random _random = math.Random(7);
  final List<Node> _clouds = [];
  final PhysicallyBasedMaterial _material = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(1, 1, 1, 1)
    ..metallicFactor = 0
    ..roughnessFactor = 1;

  /// Self-glow of the clouds, which sets their color under the current sky.
  set tint((double, double, double) tint) =>
      _material.emissiveFactor = vm.Vector4(tint.$1, tint.$2, tint.$3, 1);

  @override
  void onMount() {
    if (_clouds.isNotEmpty) return;
    final puff = SphereGeometry(radius: 1, segments: 20, rings: 12);

    for (var i = 0; i < count; i++) {
      final cloud = Node();
      final puffs = 4 + _random.nextInt(3);
      for (var p = 0; p < puffs; p++) {
        cloud.add(
          Node(mesh: Mesh(puff, _material))
            ..position = vm.Vector3(
              (p - (puffs - 1) / 2) * 1.1 + _random.nextDouble() * 0.4,
              _random.nextDouble() * 0.5,
              _random.nextDouble() * 0.8,
            )
            ..scale = vm.Vector3.all(0.8 + _random.nextDouble() * 0.9),
        );
      }
      cloud.position = _spawn(_nearZ + _random.nextDouble() * (_farZ - _nearZ));
      _clouds.add(cloud);
      node.add(cloud);
    }
  }

  @override
  void update(double deltaSeconds) {
    for (final cloud in _clouds) {
      // Dash faces the camera, so the world streams away behind them.
      final position = cloud.position + vm.Vector3(0, 0, speed * deltaSeconds);
      cloud.position = position.z > _farZ ? _spawn(_nearZ) : position;
    }
  }

  /// Clouds form a floor below Dash plus a few high ones off to the sides,
  /// so none ever passes through Dash or the answer boards.
  vm.Vector3 _spawn(double z) {
    if (_random.nextDouble() < 0.65) {
      return vm.Vector3(
        (_random.nextDouble() * 2 - 1) * 14,
        -7 + _random.nextDouble() * 2.5,
        z,
      );
    }
    final side = _random.nextBool() ? 1.0 : -1.0;
    return vm.Vector3(
      side * (4.5 + _random.nextDouble() * 9),
      2 + _random.nextDouble() * 9,
      z,
    );
  }
}
