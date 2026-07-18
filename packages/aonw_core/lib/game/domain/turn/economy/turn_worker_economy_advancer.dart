import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_context.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_event_factory.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/worker_turn_processor.dart';

abstract final class TurnWorkerEconomyAdvancer {
  static TurnEconomyResult advance({
    required TurnEconomyState state,
    required String playerId,
    required TurnEconomyContext context,
  }) {
    final result = WorkerTurnProcessor.advanceForPlayer(
      playerId: playerId,
      units: state.units,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      mapData: context.mapData.mapTiles,
    );
    final nextCities = List<GameCity>.unmodifiable(result.cities);
    final nextUnits = List<GameUnit>.unmodifiable(result.units);
    final nextImprovements = List<FieldImprovement>.unmodifiable(
      result.fieldImprovements,
    );
    return TurnEconomyResult(
      state: state.copyWith(
        cities: nextCities,
        units: nextUnits,
        fieldImprovements: nextImprovements,
      ),
      events: [
        ...TurnEconomyEventFactory.completedWorkerJobs(
          playerId: playerId,
          previousUnits: state.units,
          updatedUnits: nextUnits,
        ),
        ...TurnEconomyEventFactory.claimedWorkerHexes(
          previousCities: state.cities,
          updatedCities: nextCities,
        ),
      ],
    );
  }
}
