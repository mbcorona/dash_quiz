import 'package:flutter/material.dart';

import '../../../domain/entities/answer_side.dart';
import '../../scene/answer_board.dart';
import '../quiz_controller.dart';
import 'quiz_card.dart';

/// The widget drawn on a 3D answer board: the answer text and the ring that
/// fills while that answer is held. Opaque and exactly
/// [AnswerBoard.faceSize], because it is captured as a texture.
class AnswerBoardFace extends StatelessWidget {
  const AnswerBoardFace({
    super.key,
    required this.side,
    required this.controller,
  });

  final AnswerSide side;
  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: AnswerBoard.faceSize,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.status == QuizStatus.loading) {
            return const ColoredBox(color: Colors.white);
          }
          final revealed = controller.status == QuizStatus.revealed;
          final correct = side == controller.session.correctSide;
          final picked = side == controller.selectedSide;
          final text = controller.session.optionOn(side);

          final color = switch ((revealed, correct, picked)) {
            (true, true, _) => const Color(0xFFB9F6CA),
            (true, false, true) => const Color(0xFFFFCDD2),
            _ => Colors.white,
          };
          final icon = switch ((revealed, correct)) {
            (true, true) => Icons.check,
            (true, false) => Icons.close,
            _ =>
              side == AnswerSide.left ? Icons.arrow_back : Icons.arrow_forward,
          };

          return ColoredBox(
            color: color,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SizedBox.square(
                    dimension: 54,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ValueListenableBuilder<Hold>(
                          valueListenable: controller.hold,
                          builder: (context, hold, _) =>
                              CircularProgressIndicator(
                                value: hold.side == side ? hold.progress : 0,
                                strokeWidth: 7,
                                strokeCap: StrokeCap.round,
                                color: quizAccent,
                                backgroundColor: const Color(0x220553B1),
                              ),
                        ),
                        Icon(icon, color: quizAccent, size: 28),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _fontSizeFor(text),
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: quizInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Short answers get big type; long ones, or ones with a long unbreakable
  /// word, shrink so they fit the board without splitting a word.
  static double _fontSizeFor(String text) {
    final longestWord = text
        .split(' ')
        .fold(
          0,
          (longest, word) => word.length > longest ? word.length : longest,
        );
    if (longestWord > 15) return 22;
    if (text.length <= 12) return 42;
    if (text.length <= 30) return 31;
    return 25;
  }
}
