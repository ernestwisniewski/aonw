import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/stability/stability_band.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/util/wire_json.dart';

/// Wire codec for turn progress, research, resources, and objectives.
abstract final class ProgressEventSerializer {
  static Map<String, dynamic> toJson(GameEvent event) {
    return switch (event) {
      TurnEndedEvent() => _turnEndedToJson(event),
      StabilityBandChangedEvent() => _stabilityChangedToJson(event),
      WorkerCompletedJobEvent() => _workerCompletedToJson(event),
      DominationThresholdReachedEvent() => _dominationToJson(event),
      ResearchPointsGainedEvent() => _researchPointsToJson(event),
      TechnologyResearchedEvent() => _technologyResearchedToJson(event),
      StrategicResourceDiscoveredEvent() => _resourceDiscoveredToJson(event),
      MapObjectiveSecuredEvent() => _objectiveSecuredToJson(event),
      _ => throw ArgumentError.value(event, 'event', 'Not a progress event'),
    };
  }

  static GameEvent? tryFromJson(Map<String, dynamic> json, String type) {
    return switch (type) {
      'TurnEnded' => _turnEndedFromJson(json, type),
      'StabilityBandChanged' => _stabilityChangedFromJson(json, type),
      'WorkerCompletedJob' => _workerCompletedFromJson(json, type),
      'DominationThresholdReached' => _dominationFromJson(json, type),
      'ResearchPointsGained' => _researchPointsFromJson(json, type),
      'TechnologyResearched' => _technologyResearchedFromJson(json, type),
      'StrategicResourceDiscovered' => _resourceDiscoveredFromJson(json, type),
      'MapObjectiveSecured' => _objectiveSecuredFromJson(json, type),
      _ => null,
    };
  }
}

Map<String, dynamic> _turnEndedToJson(TurnEndedEvent event) => {
  'type': 'TurnEnded',
  'playerId': event.playerId,
};

Map<String, dynamic> _stabilityChangedToJson(StabilityBandChangedEvent event) =>
    {
      'type': 'StabilityBandChanged',
      'playerId': event.playerId,
      'previousBand': event.previousBand.name,
      'newBand': event.newBand.name,
      'net': event.net,
    };

Map<String, dynamic> _workerCompletedToJson(WorkerCompletedJobEvent event) => {
  'type': 'WorkerCompletedJob',
  'unitId': event.unitId,
};

Map<String, dynamic> _dominationToJson(DominationThresholdReachedEvent event) =>
    {
      'type': 'DominationThresholdReached',
      'playerId': event.playerId,
      'controlPercent': event.controlPercent,
      'requiredControlPercent': event.requiredControlPercent,
      'holdTurns': event.holdTurns,
      'requiredHoldTurns': event.requiredHoldTurns,
    };

Map<String, dynamic> _researchPointsToJson(ResearchPointsGainedEvent event) => {
  'type': 'ResearchPointsGained',
  'playerId': event.playerId,
  'points': event.points,
};

Map<String, dynamic> _technologyResearchedToJson(
  TechnologyResearchedEvent event,
) => {
  'type': 'TechnologyResearched',
  'playerId': event.playerId,
  'technologyId': event.technologyId.name,
};

Map<String, dynamic> _resourceDiscoveredToJson(
  StrategicResourceDiscoveredEvent event,
) => {
  'type': 'StrategicResourceDiscovered',
  'playerId': event.playerId,
  'resourceType': event.resourceType.name,
  'controlledCount': event.controlledCount,
  'rivalControlledCount': event.rivalControlledCount,
  'unclaimedCount': event.unclaimedCount,
  'pressure': event.pressure.name,
  'nearestUnclaimedCol': ?event.nearestUnclaimedCol,
  'nearestUnclaimedRow': ?event.nearestUnclaimedRow,
};

Map<String, dynamic> _objectiveSecuredToJson(MapObjectiveSecuredEvent event) =>
    {
      'type': 'MapObjectiveSecured',
      'playerId': event.playerId,
      'objectiveId': event.objectiveId,
      'objectiveType': event.objectiveType.name,
      'col': event.col,
      'row': event.row,
      'holdTurns': event.holdTurns,
      'requiredHoldTurns': event.requiredHoldTurns,
      'victoryPoints': event.victoryPoints,
      'goldPerTurn': event.goldPerTurn,
    };

TurnEndedEvent _turnEndedFromJson(Map<String, dynamic> json, String type) =>
    TurnEndedEvent(playerId: requiredStringField(json, type, 'playerId'));

StabilityBandChangedEvent _stabilityChangedFromJson(
  Map<String, dynamic> json,
  String type,
) => StabilityBandChangedEvent(
  playerId: requiredStringField(json, type, 'playerId'),
  previousBand: requiredEnumField(
    json,
    type,
    'previousBand',
    StabilityBand.values,
  ),
  newBand: requiredEnumField(json, type, 'newBand', StabilityBand.values),
  net: requiredIntField(json, type, 'net'),
);

WorkerCompletedJobEvent _workerCompletedFromJson(
  Map<String, dynamic> json,
  String type,
) => WorkerCompletedJobEvent(unitId: requiredStringField(json, type, 'unitId'));

DominationThresholdReachedEvent _dominationFromJson(
  Map<String, dynamic> json,
  String type,
) => DominationThresholdReachedEvent(
  playerId: requiredStringField(json, type, 'playerId'),
  controlPercent: requiredDoubleField(json, type, 'controlPercent'),
  requiredControlPercent: requiredDoubleField(
    json,
    type,
    'requiredControlPercent',
  ),
  holdTurns: requiredIntField(json, type, 'holdTurns'),
  requiredHoldTurns: requiredIntField(json, type, 'requiredHoldTurns'),
);

ResearchPointsGainedEvent _researchPointsFromJson(
  Map<String, dynamic> json,
  String type,
) => ResearchPointsGainedEvent(
  playerId: requiredStringField(json, type, 'playerId'),
  points: requiredIntField(json, type, 'points'),
);

TechnologyResearchedEvent _technologyResearchedFromJson(
  Map<String, dynamic> json,
  String type,
) => TechnologyResearchedEvent(
  playerId: requiredStringField(json, type, 'playerId'),
  technologyId: requiredEnumField(
    json,
    type,
    'technologyId',
    TechnologyId.values,
  ),
);

StrategicResourceDiscoveredEvent _resourceDiscoveredFromJson(
  Map<String, dynamic> json,
  String type,
) {
  final controlledCount = requiredIntField(json, type, 'controlledCount');
  final rivalControlledCount = requiredIntField(
    json,
    type,
    'rivalControlledCount',
  );
  final unclaimedCount = requiredIntField(json, type, 'unclaimedCount');
  final pressure =
      optionalEnumField(
        json,
        type,
        'pressure',
        StrategicResourceDiscoveryPressure.values,
      ) ??
      StrategicResourceDiscoveryPressure.fromCounts(
        controlledCount: controlledCount,
        rivalControlledCount: rivalControlledCount,
        unclaimedCount: unclaimedCount,
      );
  return StrategicResourceDiscoveredEvent(
    playerId: requiredStringField(json, type, 'playerId'),
    resourceType: requiredEnumField(
      json,
      type,
      'resourceType',
      ResourceType.values,
    ),
    controlledCount: controlledCount,
    rivalControlledCount: rivalControlledCount,
    unclaimedCount: unclaimedCount,
    pressure: pressure,
    nearestUnclaimedCol: optionalIntField(json, type, 'nearestUnclaimedCol'),
    nearestUnclaimedRow: optionalIntField(json, type, 'nearestUnclaimedRow'),
  );
}

MapObjectiveSecuredEvent _objectiveSecuredFromJson(
  Map<String, dynamic> json,
  String type,
) => MapObjectiveSecuredEvent(
  playerId: requiredStringField(json, type, 'playerId'),
  objectiveId: requiredStringField(json, type, 'objectiveId'),
  objectiveType: requiredEnumField(
    json,
    type,
    'objectiveType',
    MapObjectiveType.values,
  ),
  col: requiredIntField(json, type, 'col'),
  row: requiredIntField(json, type, 'row'),
  holdTurns: requiredIntField(json, type, 'holdTurns'),
  requiredHoldTurns: requiredIntField(json, type, 'requiredHoldTurns'),
  victoryPoints: requiredIntField(json, type, 'victoryPoints'),
  goldPerTurn: requiredIntField(json, type, 'goldPerTurn'),
);
