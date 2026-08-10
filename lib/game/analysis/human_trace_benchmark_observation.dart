import 'dart:convert';

class PlayerBenchmarkObservation {
  const PlayerBenchmarkObservation({
    required this.gameIndex,
    required this.playerId,
    required this.country,
    required this.secondCityTurn,
    required this.thirdCityTurn,
    required this.maxCityCount,
    required this.firstPostCitySettlerTurn,
    required this.firstPostCityFoundCommandTurn,
    required this.oneCityNoSettlerTurns,
    required this.oneCityStartUnitCommands,
    required this.oneCityAttackCommands,
    required this.firstPostSecondCitySettlerTurn,
    required this.firstPostSecondCityFoundCommandTurn,
    required this.twoCityNoSettlerTurns,
    required this.twoCityStartUnitCommands,
    required this.twoCityStartBuildingCommands,
    required this.twoCityStartProjectCommands,
    required this.twoCityAttackCommands,
    required this.finalSettlerCount,
    required this.finalCityLocations,
    required this.finalSettlerLocations,
    required this.settlerMoveDetails,
    required this.finalMilitaryCount,
    required this.attackCommands,
    required this.maxRepeatedMoveCount,
    required this.maxRepeatedMoveCommand,
    required this.maxRepeatedWorkerSelectionCount,
    required this.maxRepeatedWorkerSelectionCommand,
    required this.rejectedCommands,
    required this.rejectedCommandDetails,
  });

  final int gameIndex;
  final String playerId;
  final String country;
  final int? secondCityTurn;
  final int? thirdCityTurn;
  final int maxCityCount;
  final int? firstPostCitySettlerTurn;
  final int? firstPostCityFoundCommandTurn;
  final int oneCityNoSettlerTurns;
  final int oneCityStartUnitCommands;
  final int oneCityAttackCommands;
  final int? firstPostSecondCitySettlerTurn;
  final int? firstPostSecondCityFoundCommandTurn;
  final int twoCityNoSettlerTurns;
  final int twoCityStartUnitCommands;
  final int twoCityStartBuildingCommands;
  final int twoCityStartProjectCommands;
  final int twoCityAttackCommands;
  final int finalSettlerCount;
  final List<String> finalCityLocations;
  final List<String> finalSettlerLocations;
  final List<String> settlerMoveDetails;
  final int finalMilitaryCount;
  final int attackCommands;
  final int maxRepeatedMoveCount;
  final String? maxRepeatedMoveCommand;
  final int maxRepeatedWorkerSelectionCount;
  final String? maxRepeatedWorkerSelectionCommand;
  final int rejectedCommands;
  final List<Map<String, Object?>> rejectedCommandDetails;

  Map<String, Object?> toJson() {
    return {
      'gameIndex': gameIndex,
      'playerId': playerId,
      'country': country,
      'secondCityTurn': secondCityTurn,
      'thirdCityTurn': thirdCityTurn,
      'maxCityCount': maxCityCount,
      'firstPostCitySettlerTurn': firstPostCitySettlerTurn,
      'firstPostCityFoundCommandTurn': firstPostCityFoundCommandTurn,
      'oneCityNoSettlerTurns': oneCityNoSettlerTurns,
      'oneCityStartUnitCommands': oneCityStartUnitCommands,
      'oneCityAttackCommands': oneCityAttackCommands,
      'firstPostSecondCitySettlerTurn': firstPostSecondCitySettlerTurn,
      'firstPostSecondCityFoundCommandTurn':
          firstPostSecondCityFoundCommandTurn,
      'twoCityNoSettlerTurns': twoCityNoSettlerTurns,
      'twoCityStartUnitCommands': twoCityStartUnitCommands,
      'twoCityStartBuildingCommands': twoCityStartBuildingCommands,
      'twoCityStartProjectCommands': twoCityStartProjectCommands,
      'twoCityAttackCommands': twoCityAttackCommands,
      'finalSettlerCount': finalSettlerCount,
      'finalCityLocations': finalCityLocations,
      'finalSettlerLocations': finalSettlerLocations,
      'settlerMoveDetails': settlerMoveDetails,
      'finalMilitaryCount': finalMilitaryCount,
      'attackCommands': attackCommands,
      'maxRepeatedMoveCount': maxRepeatedMoveCount,
      'maxRepeatedMoveCommand': _decodeCommand(maxRepeatedMoveCommand),
      'maxRepeatedWorkerSelectionCount': maxRepeatedWorkerSelectionCount,
      'maxRepeatedWorkerSelectionCommand': _decodeCommand(
        maxRepeatedWorkerSelectionCommand,
      ),
      'rejectedCommands': rejectedCommands,
      'rejectedCommandDetails': rejectedCommandDetails,
    };
  }
}

Map<String, dynamic>? _decodeCommand(String? command) {
  if (command == null) return null;
  return jsonDecode(command) as Map<String, dynamic>;
}

class HumanTraceBenchmarkFinding {
  const HumanTraceBenchmarkFinding({
    required this.severity,
    required this.code,
    required this.message,
  });

  final HumanTraceBenchmarkSeverity severity;
  final String code;
  final String message;

  Map<String, Object?> toJson() {
    return {'severity': severity.name, 'code': code, 'message': message};
  }
}

enum HumanTraceBenchmarkSeverity { info, warn, fail }
