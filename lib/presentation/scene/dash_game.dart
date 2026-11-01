import 'package:flutter/widgets.dart' show Widget;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../domain/entities/answer_side.dart';
import '../../domain/entities/player_character.dart';
import 'answer_board.dart';
import 'character_spec.dart';
import 'cloud_field.dart';
import 'pilot.dart';

/// The 3D world of the quiz: the player's character flying over clouds
/// toward two answer boards. The screen tells it what is happening; it
/// decides how that looks.
class DashGame {
  final Scene scene = Scene();
  final Camera camera = PerspectiveCamera(
    position: vm.Vector3(0, 4.6, -11),
    target: vm.Vector3(0, 3.4, 0),
  );

  final Pilot _pilot = Pilot();
  final CloudField _clouds = CloudField();
  final Map<PlayerCharacter, Node> _characters = {};
  PlayerCharacter _character = PlayerCharacter.dash;
  late final Map<AnswerSide, AnswerBoard> _boards;

  /// Loads the scene. [boardFace] builds the widget shown on each board.
  Future<void> load({
    required Widget Function(AnswerSide side) boardFace,
  }) async {
    await Scene.initializeStaticResources();
    scene.add(Node()..addComponent(_clouds));

    // Both characters live in the rig; only the chosen one is visible.
    final rig = Node()..addComponent(_pilot);
    for (final entry in CharacterSpec.of.entries) {
      final model = await loadScene(entry.value.asset);
      model.position = entry.value.pivotOffset;
      model.visible = false;
      _characters[entry.key] = model;
      rig.add(model);
    }
    scene.add(rig);
    character = _character;

    _boards = {};
    for (final side in AnswerSide.values) {
      final (node, board) = AnswerBoard.create(
        sideSign: side == AnswerSide.left ? -1 : 1,
        face: boardFace(side),
      );
      _boards[side] = board;
      scene.add(node);
    }
  }

  PlayerCharacter get character => _character;

  /// Swaps the visible character and its sky; the pilot keeps flying
  /// without a break.
  set character(PlayerCharacter character) {
    _character = character;
    for (final entry in _characters.entries) {
      entry.value.visible = entry.key == character;
    }
    _pilot.model = _characters[character]!;
    final sky = CharacterSpec.of[character]!.sky;
    sky.apply(scene);
    _clouds.tint = sky.cloudTint;
  }

  /// Steers the character; [lean] is `-1` (left) to `1` (right).
  set steer(double lean) => _pilot.steer = lean;

  /// Shows an answer being held: the character climbs toward that board as
  /// [progress] goes from 0 to 1.
  void showHold(AnswerSide? side, double progress) {
    _pilot.lift = side == null ? 0 : progress;
    for (final entry in _boards.entries) {
      entry.value.highlighted = entry.key == side;
    }
  }

  void beginQuestion() {
    _pilot.mood = PilotMood.flying;
    for (final board in _boards.values) {
      board.present();
    }
  }

  void reveal({required AnswerSide correct, required AnswerSide picked}) {
    _pilot.mood = picked == correct ? PilotMood.happy : PilotMood.sad;
    _boards[correct]!.showCorrect();
    final other = _boards[correct.opposite]!;
    picked == correct ? other.showWrongOther() : other.showWrongPick();
  }

  void finish() {
    _pilot.mood = PilotMood.happy;
    for (final board in _boards.values) {
      board.hide();
    }
  }
}
