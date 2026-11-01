import 'package:vector_math/vector_math.dart' as vm;

import '../../domain/entities/player_character.dart';
import 'sky.dart';

/// How a character appears in the scene: its model, how it is pivoted and
/// the sky it flies under. Adding a character is adding an entry to
/// [CharacterSpec.of]; nothing else needs to change.
class CharacterSpec {
  const CharacterSpec._({
    required this.asset,
    required this.pivot,
    required this.sky,
  });

  static const Map<PlayerCharacter, CharacterSpec> of = {
    PlayerCharacter.dash: CharacterSpec._(
      asset: 'assets/dash.glb',
      pivot: (0, -1.4, 0),
      sky: SkyLook.day,
    ),
    PlayerCharacter.calavera: CharacterSpec._(
      asset: 'assets/calavera.glb',
      pivot: (0, -1.5, 0),
      sky: SkyLook.ofrenda,
    ),
  };

  /// Source path of the `.glb`, loadable with `loadScene`.
  final String asset;

  /// Offset that moves the pivot from the model's feet to its body, so
  /// turns look like banking rather than swinging.
  final (double, double, double) pivot;

  final SkyLook sky;

  vm.Vector3 get pivotOffset => vm.Vector3(pivot.$1, pivot.$2, pivot.$3);
}
