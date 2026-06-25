enum GameTypeId {
  microLesson,
  puzzleDragDrop,
  puzzleReorder,
  codeCompletion,
  timedChallenge,
  scenarioSimulation,
  unknown;

  static GameTypeId fromString(String value) {
    switch (value) {
      case 'MICRO_LESSON':
        return GameTypeId.microLesson;
      case 'PUZZLE_DRAG_DROP':
        return GameTypeId.puzzleDragDrop;
      case 'PUZZLE_REORDER':
        return GameTypeId.puzzleReorder;
      case 'CODE_COMPLETION':
        return GameTypeId.codeCompletion;
      case 'TIMED_CHALLENGE':
        return GameTypeId.timedChallenge;
      case 'SCENARIO_SIMULATION':
        return GameTypeId.scenarioSimulation;
      default:
        return GameTypeId.unknown;
    }
  }

  bool get isCoding => this == GameTypeId.codeCompletion || this == GameTypeId.timedChallenge;
}
