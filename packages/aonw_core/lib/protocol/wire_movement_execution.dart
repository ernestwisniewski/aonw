import 'package:aonw_core/protocol/wire_json.dart';

const _serverAudiencePlayerIdsKey = '_serverAudiencePlayerIds';

final class WireMovementStep {
  const WireMovementStep({
    required this.col,
    required this.row,
    required this.enterCost,
    required this.cumulativeCost,
  });

  final int col;
  final int row;
  final int enterCost;
  final int cumulativeCost;

  factory WireMovementStep.fromJson(Map<String, dynamic> json) {
    return WireMovementStep(
      col: WireJson.requiredInt(json, 'WireMovementStep', 'col'),
      row: WireJson.requiredInt(json, 'WireMovementStep', 'row'),
      enterCost: WireJson.requiredInt(json, 'WireMovementStep', 'enterCost'),
      cumulativeCost: WireJson.requiredInt(
        json,
        'WireMovementStep',
        'cumulativeCost',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'col': col,
    'row': row,
    'enterCost': enterCost,
    'cumulativeCost': cumulativeCost,
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WireMovementStep &&
            other.col == col &&
            other.row == row &&
            other.enterCost == enterCost &&
            other.cumulativeCost == cumulativeCost;
  }

  @override
  int get hashCode => Object.hash(col, row, enterCost, cumulativeCost);
}

final class WireMovementExecution {
  WireMovementExecution({
    required this.unitId,
    required this.fromCol,
    required this.fromRow,
    required Iterable<WireMovementStep> steps,
    Iterable<String>? serverAudiencePlayerIds,
  }) : steps = List<WireMovementStep>.unmodifiable(steps),
       serverAudiencePlayerIds = serverAudiencePlayerIds == null
           ? null
           : List<String>.unmodifiable(serverAudiencePlayerIds) {
    if (unitId.trim().isEmpty) {
      throw ArgumentError.value(
        unitId,
        'unitId',
        'Expected a non-blank unit identifier',
      );
    }
    if (this.steps.isEmpty) {
      throw ArgumentError.value(
        steps,
        'steps',
        'An executed movement path must contain at least one travel step',
      );
    }
    _validateServerAudience(this.serverAudiencePlayerIds);
  }

  final String unitId;
  final int fromCol;
  final int fromRow;
  final List<WireMovementStep> steps;
  final List<String>? serverAudiencePlayerIds;

  factory WireMovementExecution.fromJson(Map<String, dynamic> json) {
    final rawSteps = WireJson.requiredList(
      json['steps'],
      'WireMovementExecution.steps',
    );
    return WireMovementExecution(
      unitId: WireJson.requiredString(json, 'WireMovementExecution', 'unitId'),
      fromCol: WireJson.requiredInt(json, 'WireMovementExecution', 'fromCol'),
      fromRow: WireJson.requiredInt(json, 'WireMovementExecution', 'fromRow'),
      steps: rawSteps.map(
        (step) => WireMovementStep.fromJson(
          WireJson.requiredMap(step, 'WireMovementExecution.steps[]'),
        ),
      ),
      serverAudiencePlayerIds: _readServerAudience(json),
    );
  }

  Map<String, dynamic> toJson({bool includeServerMetadata = true}) => {
    'unitId': unitId,
    'fromCol': fromCol,
    'fromRow': fromRow,
    'steps': [for (final step in steps) step.toJson()],
    if (includeServerMetadata && serverAudiencePlayerIds != null)
      _serverAudiencePlayerIdsKey: [...serverAudiencePlayerIds!],
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WireMovementExecution &&
            other.unitId == unitId &&
            other.fromCol == fromCol &&
            other.fromRow == fromRow &&
            _listEquals(other.steps, steps) &&
            _listEquals(other.serverAudiencePlayerIds, serverAudiencePlayerIds);
  }

  @override
  int get hashCode => Object.hash(
    unitId,
    fromCol,
    fromRow,
    Object.hashAll(steps),
    serverAudiencePlayerIds == null
        ? null
        : Object.hashAll(serverAudiencePlayerIds!),
  );

  static List<String>? _readServerAudience(Map<String, dynamic> json) {
    if (!json.containsKey(_serverAudiencePlayerIdsKey)) return null;
    final rawAudience = WireJson.requiredList(
      json[_serverAudiencePlayerIdsKey],
      'WireMovementExecution.$_serverAudiencePlayerIdsKey',
    );
    return [
      for (var index = 0; index < rawAudience.length; index++)
        switch (rawAudience[index]) {
          final String playerId when playerId.trim().isNotEmpty => playerId,
          final value => throw ArgumentError.value(
            value,
            'WireMovementExecution.$_serverAudiencePlayerIdsKey[$index]',
            'Expected a non-blank String',
          ),
        },
    ];
  }

  static void _validateServerAudience(List<String>? playerIds) {
    if (playerIds == null) return;
    if (playerIds.isEmpty) {
      throw ArgumentError.value(
        playerIds,
        'serverAudiencePlayerIds',
        'A present server audience must not be empty',
      );
    }
    for (var index = 0; index < playerIds.length; index++) {
      final playerId = playerIds[index];
      if (playerId.trim().isEmpty) {
        throw ArgumentError.value(
          playerId,
          'serverAudiencePlayerIds[$index]',
          'Expected a non-blank player identifier',
        );
      }
      if (index > 0 && playerIds[index - 1].compareTo(playerId) >= 0) {
        throw ArgumentError.value(
          playerIds,
          'serverAudiencePlayerIds',
          'Expected sorted, unique player identifiers',
        );
      }
    }
  }
}

final class WireMovementExecutionList {
  WireMovementExecutionList(Iterable<WireMovementExecution> values)
    : values = List<WireMovementExecution>.unmodifiable(values);

  final List<WireMovementExecution> values;

  bool get isEmpty => values.isEmpty;

  factory WireMovementExecutionList.fromJson(Object? json) {
    final rawValues = WireJson.requiredList(json, 'WireMovementExecutionList');
    return WireMovementExecutionList(
      rawValues.map(
        (value) => WireMovementExecution.fromJson(
          WireJson.requiredMap(value, 'WireMovementExecutionList[]'),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> toJson({bool includeServerMetadata = true}) {
    return [
      for (final value in values)
        value.toJson(includeServerMetadata: includeServerMetadata),
    ];
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WireMovementExecutionList && _listEquals(other.values, values);
  }

  @override
  int get hashCode => Object.hashAll(values);
}

bool _listEquals<T>(List<T>? first, List<T>? second) {
  if (identical(first, second)) return true;
  if (first == null || second == null || first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
