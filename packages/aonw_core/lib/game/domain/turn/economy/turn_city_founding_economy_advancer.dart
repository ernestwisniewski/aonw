import 'package:aonw_core/game/domain/city/city_founding_job_processor.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_context.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

abstract final class TurnCityFoundingEconomyAdvancer {
  static TurnEconomyResult advance({
    required TurnEconomyState state,
    required String playerId,
    required TurnEconomyContext context,
  }) {
    final result = CityFoundingJobProcessor.advanceForPlayer(
      playerId: playerId,
      units: state.units,
      cities: state.cities,
      mapTiles: context.mapData.mapTiles,
      countryForPlayer: context.countryForPlayer,
      cityRuleset: context.ruleset.city,
    );
    return TurnEconomyResult(
      state: state.copyWith(
        cities: List<GameCity>.unmodifiable(result.cities),
        units: List<GameUnit>.unmodifiable(result.units),
      ),
      events: result.events,
    );
  }
}
