class HumanTraceBenchmark {
  const HumanTraceBenchmark({
    required this.source,
    required this.humanPlayerId,
    required this.lastCompletedTurn,
    required this.humanCityCount,
    required this.humanSecondCityTurn,
    required this.firstHumanAttackTurn,
    required this.maxRepeatedAiMoveCount,
    required this.maxAiWorkerStallSelections,
  });

  factory HumanTraceBenchmark.fromTraceJson(Map<String, dynamic> json) {
    final foundedCities = _entries(json, 'humanFoundCities');
    return HumanTraceBenchmark(
      source: json['source'] as String? ?? 'unknown',
      humanPlayerId: json['humanPlayerId'] as String? ?? 'player_1',
      lastCompletedTurn: json['lastCompletedTurn'] as int? ?? 0,
      humanCityCount: foundedCities.length,
      humanSecondCityTurn: _secondCityTurn(foundedCities),
      firstHumanAttackTurn: _earliestTurn(_entries(json, 'humanAttacks')),
      maxRepeatedAiMoveCount: _maxMoveRepeat(
        _entries(json, 'repeatedAiCommands'),
      ),
      maxAiWorkerStallSelections: _maxInt(
        _entries(json, 'aiWorkerStalls'),
        'selectionCount',
      ),
    );
  }

  final String source;
  final String humanPlayerId;
  final int lastCompletedTurn;
  final int humanCityCount;
  final int? humanSecondCityTurn;
  final int? firstHumanAttackTurn;
  final int maxRepeatedAiMoveCount;
  final int maxAiWorkerStallSelections;

  int get secondCityMaxTurn => (humanSecondCityTurn ?? 36) + 15;

  int get minimumMaxCityCount {
    if (humanCityCount <= 2) return 2;
    return (humanCityCount / 2).ceil();
  }

  int get repeatedMoveLimit => 8;
  int get workerSelectionRepeatLimit => 3;

  Map<String, Object?> toJson() {
    return {
      'source': source,
      'humanPlayerId': humanPlayerId,
      'lastCompletedTurn': lastCompletedTurn,
      'humanCityCount': humanCityCount,
      'humanSecondCityTurn': humanSecondCityTurn,
      'firstHumanAttackTurn': firstHumanAttackTurn,
      'maxRepeatedAiMoveCount': maxRepeatedAiMoveCount,
      'maxAiWorkerStallSelections': maxAiWorkerStallSelections,
      'targets': {
        'secondCityMaxTurn': secondCityMaxTurn,
        'minimumMaxCityCount': minimumMaxCityCount,
        'repeatedMoveLimit': repeatedMoveLimit,
        'workerSelectionRepeatLimit': workerSelectionRepeatLimit,
      },
    };
  }
}

List<Map<String, dynamic>> _entries(Map<String, dynamic> json, String key) {
  return [
    for (final value in json[key] as List<dynamic>? ?? const [])
      value as Map<String, dynamic>,
  ];
}

int? _secondCityTurn(List<Map<String, dynamic>> foundedCities) {
  if (foundedCities.length < 2) return null;
  return foundedCities[1]['turn'] as int?;
}

int? _earliestTurn(List<Map<String, dynamic>> entries) {
  final turns = [
    for (final entry in entries)
      if (entry['turn'] case final int turn) turn,
  ];
  if (turns.isEmpty) return null;
  return turns.reduce((earliest, turn) => turn < earliest ? turn : earliest);
}

int _maxMoveRepeat(List<Map<String, dynamic>> entries) {
  return _maxInt([
    for (final entry in entries)
      if (entry['commandType'] == 'MoveUnit') entry,
  ], 'count');
}

int _maxInt(List<Map<String, dynamic>> entries, String key) {
  var result = 0;
  for (final entry in entries) {
    final value = entry[key] as int? ?? 0;
    if (value > result) result = value;
  }
  return result;
}
