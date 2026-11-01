import '../../domain/entities/question.dart';
import '../../domain/repositories/question_repository.dart';

/// Questions bundled with the app.
class LocalQuestionRepository implements QuestionRepository {
  const LocalQuestionRepository();

  @override
  Future<List<Question>> getQuestions() async => _questions;
}

const List<Question> _questions = [
  Question(
    'Which State method runs exactly once, when a StatefulWidget is first inserted into the tree?',
    correct: 'initState()',
    wrong: 'build()',
  ),
  Question(
    'Which method must every StatelessWidget override?',
    correct: 'build()',
    wrong: 'createState()',
  ),
  Question(
    'Which method tells Flutter that a State has changed and needs to rebuild?',
    correct: 'setState()',
    wrong: 'initState()',
  ),
  Question(
    'Which method does a ChangeNotifier call to tell its listeners about a change?',
    correct: 'notifyListeners()',
    wrong: 'setState()',
  ),
  Question(
    'Which Dart keyword creates a compile-time constant?',
    correct: 'const',
    wrong: 'final',
  ),
  Question(
    'Which Dart operator accesses a member only when the object is not null?',
    correct: '?.',
    wrong: '??',
  ),
  Question(
    'Which Dart keyword pauses an async function until a Future completes?',
    correct: 'await',
    wrong: 'yield',
  ),
  Question(
    'What does Dart use to run code in parallel with its own separate memory?',
    correct: 'Isolates',
    wrong: 'Futures',
  ),
  Question(
    'Which widget makes its child fill the remaining space in a Row or Column?',
    correct: 'Expanded',
    wrong: 'Padding',
  ),
  Question(
    'Which widget keeps content clear of notches and system bars?',
    correct: 'SafeArea',
    wrong: 'Scaffold',
  ),
  Question(
    'Which constructor builds list items lazily, only as they scroll into view?',
    correct: 'ListView.builder',
    wrong: 'SingleChildScrollView',
  ),
  Question(
    'Which widget rebuilds its UI when a single asynchronous task completes?',
    correct: 'FutureBuilder',
    wrong: 'StreamBuilder',
  ),
  Question(
    'Which widget animates automatically when its properties change?',
    correct: 'AnimatedContainer',
    wrong: 'Container',
  ),
  Question(
    'What are the three trees Flutter uses to build and render the UI?',
    correct: 'Widget, Element and RenderObject',
    wrong: 'Widget, State and BuildContext',
  ),
  Question(
    "What is Flutter's default rendering engine on iOS and Android?",
    correct: 'Impeller',
    wrong: 'Skia',
  ),
  Question(
    "Which feature applies code changes while keeping the app's current state?",
    correct: 'Hot reload',
    wrong: 'Hot restart',
  ),
  Question(
    'Which command checks your code for errors and lint warnings?',
    correct: 'flutter analyze',
    wrong: 'flutter doctor',
  ),
  Question(
    'Which command downloads the packages listed in pubspec.yaml?',
    correct: 'flutter pub get',
    wrong: 'flutter clean',
  ),
  Question(
    "Which file declares a Flutter app's package dependencies?",
    correct: 'pubspec.yaml',
    wrong: 'main.dart',
  ),
  Question(
    'Which kind of test checks a single widget without running the whole app?',
    correct: 'Widget test',
    wrong: 'Integration test',
  ),
];
