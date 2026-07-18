import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/objective/map_objective.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

abstract final class TurnEconomyEventFactory {
  static List<GameEvent> fromCityTurn({
    required List<GameCity> previousCities,
    required List<CityTurnEvent> cityEvents,
    required List<GameCity> updatedCities,
  }) {
    final previousById = {for (final city in previousCities) city.id: city};
    final updatedById = {for (final city in updatedCities) city.id: city};
    final events = <GameEvent>[];
    for (final cityEvent in cityEvents) {
      final event = _fromCityEvent(
        cityEvent,
        previousById: previousById,
        updatedById: updatedById,
      );
      if (event != null) events.add(event);
    }
    return events;
  }

  static GameEvent? _fromCityEvent(
    CityTurnEvent event, {
    required Map<String, GameCity> previousById,
    required Map<String, GameCity> updatedById,
  }) {
    return switch (event.type) {
      CityTurnEventType.builtBuilding => _builtBuildingEvent(
        event,
        previous: previousById[event.cityId],
        updated: updatedById[event.cityId],
      ),
      CityTurnEventType.producedUnit => _producedUnitEvent(event),
      CityTurnEventType.grew => null,
      CityTurnEventType.claimedHex => _claimedHexEvent(event),
    };
  }

  static GameEvent? _builtBuildingEvent(
    CityTurnEvent event, {
    required GameCity? previous,
    required GameCity? updated,
  }) {
    if (previous == null || updated == null) return null;
    final building = updated.buildings
        .difference(previous.buildings)
        .firstOrNull;
    return building == null
        ? null
        : CityBuiltBuildingEvent(cityId: event.cityId, buildingType: building);
  }

  static GameEvent? _producedUnitEvent(CityTurnEvent event) {
    final unit = event.producedUnit;
    return unit == null
        ? null
        : CityProducedUnitEvent(
            cityId: event.cityId,
            unitType: unit.type,
            producedUnitId: unit.id,
          );
  }

  static GameEvent? _claimedHexEvent(CityTurnEvent event) {
    final hex = event.hex;
    return hex == null
        ? null
        : CityClaimedHexEvent(cityId: event.cityId, col: hex.col, row: hex.row);
  }

  static List<GameEvent> completedWorkerJobs({
    required String playerId,
    required List<GameUnit> previousUnits,
    required List<GameUnit> updatedUnits,
  }) {
    final updatedById = {for (final unit in updatedUnits) unit.id: unit};
    return [
      for (final previous in previousUnits)
        if (previous.ownerPlayerId == playerId &&
            previous.workerJob != null &&
            updatedById[previous.id]?.workerJob == null)
          WorkerCompletedJobEvent(unitId: previous.id),
    ];
  }

  static List<GameEvent> claimedWorkerHexes({
    required List<GameCity> previousCities,
    required List<GameCity> updatedCities,
  }) {
    final previousById = {for (final city in previousCities) city.id: city};
    final events = <GameEvent>[];
    for (final city in updatedCities) {
      final previous = previousById[city.id];
      if (previous == null) continue;
      final previousHexes = previous.controlledHexes.toSet();
      for (final hex in city.controlledHexes) {
        if (previousHexes.contains(hex)) continue;
        events.add(
          CityClaimedHexEvent(cityId: city.id, col: hex.col, row: hex.row),
        );
      }
    }
    return events;
  }

  static List<MapObjectiveSecuredEvent> securedMapObjectives({
    required Iterable<MapObjectiveDefinition> objectives,
    required Map<String, MapObjectiveHoldState> previous,
    required Map<String, MapObjectiveHoldState> next,
  }) {
    final events = <MapObjectiveSecuredEvent>[];
    for (final objective in objectives) {
      final nextHold = next[objective.id];
      if (nextHold == null ||
          nextHold.holdTurns < objective.requiredHoldTurns) {
        continue;
      }
      final previousHold = previous[objective.id];
      final alreadySecured =
          previousHold != null &&
          previousHold.playerId == nextHold.playerId &&
          previousHold.holdTurns >= objective.requiredHoldTurns;
      if (alreadySecured) continue;
      events.add(_securedObjective(objective, nextHold));
    }
    return events;
  }

  static MapObjectiveSecuredEvent _securedObjective(
    MapObjectiveDefinition objective,
    MapObjectiveHoldState hold,
  ) {
    return MapObjectiveSecuredEvent(
      playerId: hold.playerId,
      objectiveId: objective.id,
      objectiveType: objective.type,
      col: objective.hex.col,
      row: objective.hex.row,
      holdTurns: hold.holdTurns,
      requiredHoldTurns: objective.requiredHoldTurns,
      victoryPoints: objective.victoryPoints,
      goldPerTurn: objective.goldPerTurn,
    );
  }
}
