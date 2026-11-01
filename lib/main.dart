import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/repositories/local_question_repository.dart';
import 'data/services/accelerometer_tilt_source.dart';
import 'presentation/quiz/quiz_controller.dart';
import 'presentation/quiz/quiz_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Answers are chosen by tilting, so the screen must not rotate.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DashQuizApp());
}

/// Composition root: the only place that knows which concrete data sources
/// sit behind the domain interfaces.
class DashQuizApp extends StatelessWidget {
  const DashQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dash Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0553B1)),
      ),
      home: QuizScreen(
        createController: () => QuizController(
          questions: const LocalQuestionRepository(),
          tilt: AccelerometerTiltSource(),
        ),
      ),
    );
  }
}
