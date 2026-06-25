import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/unit.dart';

class CityFoundingProcessingPhase extends TurnPhase {
  const CityFoundingProcessingPhase();

  @override
  TurnContext apply(TurnContext context) {
    final state = context.state;
    final result = CityFoundingJobProcessor.advanceForPlayer(
      playerId: context.playerId,
      units: state.units,
      cities: state.cities,
      mapData: context.mapData,
      countryForPlayer: state.countryForPlayer,
      cityRuleset: context.ruleset.city,
    );

    final nextCities = List<GameCity>.unmodifiable(result.cities);
    final nextUnits = List<GameUnit>.unmodifiable(result.units);
    return context.copyWith(
      state: state.copyWith(cities: nextCities, units: nextUnits),
      events: [...context.events, ...result.events],
    );
  }
}
