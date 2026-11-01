/// A quiz question with exactly two possible answers.
class Question {
  const Question(this.text, {required this.correct, required this.wrong});

  final String text;
  final String correct;
  final String wrong;
}
