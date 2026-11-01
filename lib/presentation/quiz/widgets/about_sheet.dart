import 'package:flutter/material.dart';

import 'quiz_card.dart';

/// Shows what Dash Quiz is for: an open-source, non-commercial showcase of
/// flutter_scene. Completes when the sheet is closed.
Future<void> showAboutSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => const _AboutSheet(),
  );
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About Dash Quiz',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: quizInk,
                ),
              ),
              const SizedBox(height: 8),
              const _Body(
                'Dash Quiz is a free, open-source project. It is not a '
                'commercial product: there are no ads and nothing to buy.',
              ),
              const _Heading('Why it exists'),
              const _Body(
                'The quiz is the excuse. The app is here to show Flutter '
                'developers what flutter_scene, a 3D engine written in Dart, '
                'can do inside an ordinary Flutter app, and to encourage you '
                'to try it in your own.',
              ),
              const _Heading('What flutter_scene does here'),
              const _Bullet(
                'Characters',
                'Dash and La Calavera are .glb models loaded into the scene, '
                    'animated by rotating named nodes in code: wing bones '
                    'for Dash, the hat for La Calavera.',
              ),
              const _Bullet(
                'Answer boards',
                'live Flutter widgets rendered onto surfaces in the 3D '
                    'world.',
              ),
              const _Bullet(
                'Clouds',
                'built in code from one shared sphere and one material.',
              ),
              const _Bullet(
                'Sky and light',
                'a procedural gradient sky, a shadow-casting sun, fog, '
                    'color grading and a vignette, with a different look '
                    'for each character.',
              ),
              const _Bullet(
                'One screen',
                'the 3D view is a single widget with normal Flutter widgets '
                    'stacked on top.',
              ),
              const _Heading('Contributions welcome'),
              const _Body(
                'New questions, scene improvements and platform testing are '
                'all good places to start. The source and the README are on '
                'GitHub:',
              ),
              const SizedBox(height: 6),
              const _Link('github.com/mbcorona/dash_quiz'),
              const _Heading('Learn more'),
              const _Link('pub.dev/packages/flutter_scene'),
              const SizedBox(height: 20),
              const Text(
                'Dash and Flutter are trademarks of Google. This project is '
                'not affiliated with or endorsed by Google.',
                style: TextStyle(fontSize: 12, height: 1.4, color: quizInk),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to the quiz'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: quizInk,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, height: 1.4, color: quizInk),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.label, this.text);

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: text),
          ],
        ),
        style: const TextStyle(fontSize: 15, height: 1.4, color: quizInk),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: quizAccent,
      ),
    );
  }
}
