import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'code_challenge_widget.dart';
import 'game_types.dart';
import 'micro_lesson_widget.dart';
import 'puzzle_drag_drop_widget.dart';
import 'puzzle_reorder_widget.dart';
import 'scenario_simulation_widget.dart';

class GameWidgetFactory extends StatelessWidget {
  final Lesson lesson;
  final dynamic answer;
  final String? code;
  final int elapsedSeconds;
  final ValueChanged<dynamic> onAnswerChanged;
  final ValueChanged<String> onCodeChanged;

  const GameWidgetFactory({
    super.key,
    required this.lesson,
    this.answer,
    this.code,
    this.elapsedSeconds = 0,
    required this.onAnswerChanged,
    required this.onCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final type = GameTypeId.fromString(lesson.gameType);

    return switch (type) {
      GameTypeId.microLesson => MicroLessonWidget(
          config: lesson.configJson,
          content: lesson.content,
          onAnswerChanged: onAnswerChanged,
        ),
      GameTypeId.puzzleReorder => PuzzleReorderWidget(
          config: lesson.configJson,
          onAnswerChanged: onAnswerChanged,
        ),
      GameTypeId.puzzleDragDrop => PuzzleDragDropWidget(
          config: lesson.configJson,
          onAnswerChanged: onAnswerChanged,
        ),
      GameTypeId.codeCompletion => CodeChallengeWidget(
          config: lesson.configJson,
          content: lesson.content,
          onCodeChanged: onCodeChanged,
        ),
      GameTypeId.timedChallenge => CodeChallengeWidget(
          config: lesson.configJson,
          content: lesson.content,
          timed: true,
          elapsedSeconds: elapsedSeconds,
          onCodeChanged: onCodeChanged,
        ),
      GameTypeId.scenarioSimulation => ScenarioSimulationWidget(
          config: lesson.configJson,
          content: lesson.content,
          onAnswerChanged: onAnswerChanged,
        ),
      GameTypeId.unknown => TextField(
          onChanged: (v) => onAnswerChanged(v),
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Your answer'),
        ),
    };
  }
}
