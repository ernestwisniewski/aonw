import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/objective/map_objective.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/science_yield.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/wonder/wonder_registry.dart';

/// Persistence-neutral rule state used by the economy phase of a turn.
final class TurnEconomyState {
  const TurnEconomyState({
    required this.playerGold,
    required this.playerWarWeariness,
    required this.playerStabilityNet,
    required this.units,
    required this.cities,
    required this.artifacts,
    required this.fieldImprovements,
    required this.fogOfWar,
    required this.research,
    required this.wonderRegistry,
    required this.diplomacy,
    required this.resourceTradeAgreements,
    required this.mapObjectiveHoldStatesByObjectiveId,
  });

  final Map<String, int> playerGold;
  final Map<String, int> playerWarWeariness;
  final Map<String, int> playerStabilityNet;
  final List<GameUnit> units;
  final List<GameCity> cities;
  final List<WorldArtifact> artifacts;
  final List<FieldImprovement> fieldImprovements;
  final FogOfWarState fogOfWar;
  final ResearchState research;
  final WonderRegistry wonderRegistry;
  final DiplomacyState diplomacy;
  final List<ResourceTradeAgreement> resourceTradeAgreements;
  final Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId;

  TurnEconomyState copyWith({
    Map<String, int>? playerGold,
    Map<String, int>? playerWarWeariness,
    Map<String, int>? playerStabilityNet,
    List<GameUnit>? units,
    List<GameCity>? cities,
    List<WorldArtifact>? artifacts,
    List<FieldImprovement>? fieldImprovements,
    FogOfWarState? fogOfWar,
    ResearchState? research,
    WonderRegistry? wonderRegistry,
    DiplomacyState? diplomacy,
    List<ResourceTradeAgreement>? resourceTradeAgreements,
    Map<String, MapObjectiveHoldState>? mapObjectiveHoldStatesByObjectiveId,
  }) {
    return TurnEconomyState(
      playerGold: playerGold ?? this.playerGold,
      playerWarWeariness: playerWarWeariness ?? this.playerWarWeariness,
      playerStabilityNet: playerStabilityNet ?? this.playerStabilityNet,
      units: units ?? this.units,
      cities: cities ?? this.cities,
      artifacts: artifacts ?? this.artifacts,
      fieldImprovements: fieldImprovements ?? this.fieldImprovements,
      fogOfWar: fogOfWar ?? this.fogOfWar,
      research: research ?? this.research,
      wonderRegistry: wonderRegistry ?? this.wonderRegistry,
      diplomacy: diplomacy ?? this.diplomacy,
      resourceTradeAgreements:
          resourceTradeAgreements ?? this.resourceTradeAgreements,
      mapObjectiveHoldStatesByObjectiveId:
          mapObjectiveHoldStatesByObjectiveId ??
          this.mapObjectiveHoldStatesByObjectiveId,
    );
  }
}

/// Persistence-neutral output of the economy phase of a turn.
final class TurnEconomyResult {
  TurnEconomyResult({
    required this.state,
    Iterable<GameEvent> events = const [],
    this.scienceGained = ScienceYieldBreakdown.empty,
  }) : events = List.unmodifiable(events);

  final TurnEconomyState state;
  final List<GameEvent> events;
  final ScienceYieldBreakdown scienceGained;
}
