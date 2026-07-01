import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/turn.dart';
import 'package:aonw_core/game/domain/unit.dart';

class CityProcessingPhase extends TurnPhase {
  const CityProcessingPhase();

  @override
  TurnContext apply(TurnContext context) {
    final state = context.state;
    final result = CityTurnProcessor.advanceForPlayer(
      playerId: context.playerId,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      mapData: context.mapData,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: context.ruleset.city,
      research: state.research,
      technologyRuleset: context.ruleset.technology,
      stabilityModifier: PersistentStabilityProcessor.modifierForNet(
        state.playerStabilityNet[context.playerId] ?? 0,
        ruleset: context.ruleset.stability,
      ),
      paceBalance: context.ruleset.paceBalance,
    );

    final nextCities = PersistentCityHitPointRecoveryProcessor.recoverForPlayer(
      cities: result.cities,
      artifacts: state.artifacts,
      events: context.events,
      combatRuleset: context.ruleset.combat,
      playerId: context.playerId,
    );
    final nextFieldImprovements = List<FieldImprovement>.unmodifiable(
      result.fieldImprovements,
    );
    final nextUnits = List<GameUnit>.unmodifiable(result.units);
    final unitUpkeep = UnitUpkeepRules.forPlayer(
      playerId: context.playerId,
      units: nextUnits,
      cities: nextCities,
    );

    final events = _eventsFromCityTurn(
      previousCities: state.cities,
      cityEvents: result.events,
      updatedCities: nextCities,
    );

    return context.copyWith(
      state: state.copyWith(
        units: nextUnits,
        cities: nextCities,
        fieldImprovements: nextFieldImprovements,
        playerGold: _addGoldDelta(
          state.playerGold,
          context.playerId,
          result.goldGained - unitUpkeep.total,
        ),
      ),
      events: [...context.events, ...events],
      bonusScience: result.scienceGained,
    );
  }

  static Map<String, int> _addGoldDelta(
    Map<String, int> playerGold,
    String playerId,
    int amount,
  ) {
    if (playerId.isEmpty || amount == 0) return playerGold;
    final nextGold = (playerGold[playerId] ?? 0) + amount;
    return {...playerGold, playerId: nextGold < 0 ? 0 : nextGold};
  }

  static List<GameEvent> _eventsFromCityTurn({
    required List<GameCity> previousCities,
    required List<CityTurnEvent> cityEvents,
    required List<GameCity> updatedCities,
  }) {
    final previousCityById = {for (final city in previousCities) city.id: city};
    final updatedCityById = {for (final city in updatedCities) city.id: city};
    final events = <GameEvent>[];

    for (final cityEvent in cityEvents) {
      switch (cityEvent.type) {
        case CityTurnEventType.builtBuilding:
          final previousCity = previousCityById[cityEvent.cityId];
          final updatedCity = updatedCityById[cityEvent.cityId];
          if (previousCity == null || updatedCity == null) break;
          final newBuildings = updatedCity.buildings.difference(
            previousCity.buildings,
          );
          final buildingType = newBuildings.firstOrNull;
          if (buildingType != null) {
            events.add(
              CityBuiltBuildingEvent(
                cityId: cityEvent.cityId,
                buildingType: buildingType,
              ),
            );
          }
        case CityTurnEventType.producedUnit:
          final producedUnit = cityEvent.producedUnit;
          if (producedUnit != null) {
            events.add(
              CityProducedUnitEvent(
                cityId: cityEvent.cityId,
                unitType: producedUnit.type,
                producedUnitId: producedUnit.id,
              ),
            );
          }
        case CityTurnEventType.grew:
          break;
        case CityTurnEventType.claimedHex:
          final hex = cityEvent.hex;
          if (hex != null) {
            events.add(
              CityClaimedHexEvent(
                cityId: cityEvent.cityId,
                col: hex.col,
                row: hex.row,
              ),
            );
          }
      }
    }

    return events;
  }
}
