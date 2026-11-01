import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';

import '../../domain/entities/answer_side.dart';
import '../scene/dash_game.dart';
import 'quiz_controller.dart';
import 'widgets/about_sheet.dart';
import 'widgets/answer_board_face.dart';
import 'widgets/character_sheet.dart';
import 'widgets/quiz_card.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.createController});

  /// Builds the controller this screen owns for its lifetime.
  final QuizController Function() createController;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizController _controller = widget.createController();
  final DashGame _game = DashGame();
  bool _sceneReady = false;
  bool _sheetOpen = false;
  // What the scene was last told, so it only hears about changes.
  (QuizStatus, int)? _shown;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncScene);
    _controller.start();
    _game
        .load(
          boardFace: (side) =>
              AnswerBoardFace(side: side, controller: _controller),
        )
        .then((_) {
          if (!mounted) return;
          setState(() => _sceneReady = true);
          _syncScene();
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Tells the 3D scene about quiz events: new question, reveal, finish.
  void _syncScene() {
    final status = _controller.status;
    if (!_sceneReady || status == QuizStatus.loading) return;
    final session = _controller.session;
    final current = (status, session.index);
    if (current == _shown) return;
    _shown = current;
    switch (status) {
      case QuizStatus.answering:
        _game.beginQuestion();
      case QuizStatus.revealed:
        _game.reveal(
          correct: session.correctSide,
          picked: _controller.selectedSide!,
        );
      case QuizStatus.finished:
        _game.finish();
      case QuizStatus.loading:
        break;
    }
  }

  void _tick(Duration elapsed, double dt) {
    // The quiz waits while a sheet is open; the scene keeps flying.
    if (_sheetOpen) {
      _game.steer = 0;
      return;
    }
    _controller.tick(dt);
    final hold = _controller.hold.value;
    _game.steer = _controller.status == QuizStatus.finished
        ? 0
        : _controller.lean;
    _game.showHold(hold.side, hold.progress);
  }

  /// Pressing and holding a half of the screen works like leaning that way.
  void _press(PointerEvent event) {
    final width = MediaQuery.sizeOf(context).width;
    _controller.press(
      event.position.dx < width / 2 ? AnswerSide.left : AnswerSide.right,
    );
  }

  Future<void> _openAbout() => _showSheet(() => showAboutSheet(context));

  Future<void> _openCharacters() => _showSheet(() async {
    final picked = await showCharacterSheet(context, current: _game.character);
    if (picked != null) _game.character = picked;
  });

  /// Runs [show] with the quiz paused, so a tilt while reading the sheet
  /// does not pick an answer.
  Future<void> _showSheet(Future<void> Function() show) async {
    _controller.press(null);
    _sheetOpen = true;
    await show();
    _sheetOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E88E5), Color(0xFF64B5F6), Color(0xFFBBDEFB)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_sceneReady)
              Listener(
                onPointerDown: _press,
                onPointerUp: (_) => _controller.press(null),
                onPointerCancel: (_) => _controller.press(null),
                child: SceneView(
                  _game.scene,
                  camera: _game.camera,
                  onTick: _tick,
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => switch (_controller.status) {
                    QuizStatus.loading => const SizedBox.shrink(),
                    QuizStatus.finished => _FinishedView(_controller),
                    QuizStatus.answering ||
                    QuizStatus.revealed => _QuestionView(_controller),
                  },
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        onPressed: _openCharacters,
                        tooltip: 'Choose character',
                        icon: const Icon(Icons.face),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        onPressed: _openAbout,
                        tooltip: 'About this project',
                        icon: const Icon(Icons.info_outline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView(this.controller);

  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuizPill('Question ${session.index + 1} / ${session.length}'),
            QuizPill('Score ${session.score}'),
          ],
        ),
        const SizedBox(height: 12),
        QuizCard(
          child: Text(
            session.question.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: quizInk,
            ),
          ),
        ),
        const Spacer(),
        if (controller.status == QuizStatus.answering)
          // Side padding keeps the hint clear of the corner buttons.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 96),
            child: Text(
              'Tilt your phone and hold to answer',
              textAlign: TextAlign.center,
              style: TextStyle(color: quizInk, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView(this.controller);

  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        QuizCard(
          child: Column(
            children: [
              const Text(
                'All done!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: quizInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You got ${session.score} of ${session.length} right',
                style: const TextStyle(fontSize: 18, color: quizInk),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.restart,
                child: const Text('Play again'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
