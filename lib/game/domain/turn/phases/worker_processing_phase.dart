import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/unit.dart';

class WorkerProcessingPhase extends TurnPhase {
  const WorkerProcessingPhase();

  @override
  TurnContext apply(TurnContext context) {
    final state = context.state;
    final result = WorkerTurnProcessor.advanceForPlayer(
      playerId: context.playerId,
      units: state.units,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      mapData: context.mapData,
    );

    final nextCities = List<GameCity>.unmodifiable(result.cities);
    final nextUnits = List<GameUnit>.unmodifiable(result.units);
    final nextFieldImprovements = List<FieldImprovement>.unmodifiable(
      result.fieldImprovements,
    );
    final events = [
      ..._completedJobEvents(
        playerId: context.playerId,
        previousUnits: state.units,
        updatedUnits: nextUnits,
      ),
      ..._claimedHexEvents(
        previousCities: state.cities,
        updatedCities: nextCities,
      ),
    ];

    return context.copyWith(
      state: state.copyWith(
        cities: nextCities,
        units: nextUnits,
        fieldImprovements: nextFieldImprovements,
      ),
      events: [...context.events, ...events],
    );
  }

  static List<GameEvent> _completedJobEvents({
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

  static List<GameEvent> _claimedHexEvents({
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
}
