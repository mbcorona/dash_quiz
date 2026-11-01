import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// A whole mood for the sky: gradient, sun, key light, fog and grading.
/// Each character flies under its own.
class SkyLook {
  const SkyLook._({
    required this.zenith,
    required this.horizon,
    required this.ground,
    required this.sunDirection,
    required this.sunColor,
    required this.sunSharpness,
    required this.keyLight,
    required this.keyIntensity,
    required this.fog,
    required this.saturation,
    required this.contrast,
    required this.vignette,
    required this.cloudTint,
  });

  /// Bright daytime: Dash's blue sky over a white cloud floor.
  static const day = SkyLook._(
    zenith: (0.02, 0.16, 0.75),
    horizon: (0.16, 0.42, 0.92),
    // Below the horizon is haze over the cloud layer, not ground.
    ground: (0.36, 0.62, 1.0),
    // Ahead of the camera, up and to the right of the character.
    sunDirection: (0.22, 0.2, 0.95),
    // Kept low: the sky shader adds a wide halo of 15% of this color,
    // which washes the whole view out at high values.
    sunColor: (1.2, 1.05, 0.8),
    sunSharpness: 900,
    keyLight: (1.0, 0.96, 0.88),
    keyIntensity: 2.5,
    fog: (0.30, 0.55, 0.96),
    saturation: 1.2,
    contrast: 1.05,
    vignette: 0.2,
    // A little self-glow keeps the shaded side of clouds from going gray.
    cloudTint: (0.45, 0.47, 0.5),
  );

  /// Day of the Dead dusk for La Calavera: violet sky, a magenta horizon
  /// and a marigold glow rising from below, as if from an ofrenda.
  static const ofrenda = SkyLook._(
    zenith: (0.05, 0.01, 0.16),
    horizon: (0.48, 0.12, 0.42),
    ground: (1.0, 0.42, 0.10),
    sunDirection: (-0.25, 0.08, 0.96),
    sunColor: (1.1, 0.55, 0.25),
    sunSharpness: 500,
    // Candlelight-warm, so the skull stays ivory rather than going blue.
    keyLight: (1.0, 0.78, 0.55),
    keyIntensity: 2.3,
    fog: (0.42, 0.16, 0.38),
    saturation: 1.3,
    contrast: 1.1,
    vignette: 0.38,
    // Clouds catch the dusk and turn lilac.
    cloudTint: (0.42, 0.26, 0.48),
  );

  final (double, double, double) zenith;
  final (double, double, double) horizon;
  final (double, double, double) ground;
  final (double, double, double) sunDirection;
  final (double, double, double) sunColor;
  final double sunSharpness;
  final (double, double, double) keyLight;
  final double keyIntensity;
  final (double, double, double) fog;
  final double saturation;
  final double contrast;
  final double vignette;

  /// Emissive color for the clouds, so they take on the sky's mood.
  final (double, double, double) cloudTint;

  /// Applies this look to [scene]'s sky, post-processing and key light.
  void apply(Scene scene) {
    final sky = GradientSkySource(
      zenithColor: _v3(zenith),
      horizonColor: _v3(horizon),
      groundColor: _v3(ground),
      sunDirection: _v3(sunDirection),
      sunColor: _v3(sunColor),
      sunSharpness: sunSharpness,
    );
    // The sky is only the backdrop. Lighting stays on the engine's neutral
    // studio environment, because lighting from the sky tints the character
    // and the clouds. Bloom is left off: it hazes Dash's eyes.
    scene.environmentSettings = EnvironmentSettings(
      skybox: Skybox(sky),
      toneMapping: ToneMappingMode.pbrNeutral,
      colorGradingEnabled: true,
      saturation: saturation,
      contrast: contrast,
      // Linear, starting behind the character, so only the far clouds fade.
      fogEnabled: true,
      fogMode: FogMode.linear,
      fogStart: 22,
      fogEnd: 95,
      fogColor: _v3(fog),
      vignetteEnabled: true,
      vignetteIntensity: vignette,
    );
    // The visible sun sits ahead of the camera, which would leave the face
    // in shadow, so the key light comes from over the player's shoulder.
    scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-0.35, -0.75, 0.55),
      color: _v3(keyLight),
      intensity: keyIntensity,
      castsShadow: true,
    );
  }

  static vm.Vector3 _v3((double, double, double) c) =>
      vm.Vector3(c.$1, c.$2, c.$3);
}
