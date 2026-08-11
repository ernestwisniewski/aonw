import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_phase.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_resolver.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_result.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/transport/transport_network_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class TurnAutoExploreAdvance {
  factory TurnAutoExploreAdvance({
    required List<GameUnit> units,
    required FogOfWarState fogOfWar,
    required DiplomacyState diplomacy,
    required DomainActionState interaction,
    bool changed = false,
    Iterable<GameEvent> events = const [],
    Iterable<MovementCommandExecution> executions = const [],
  }) {
    return TurnAutoExploreAdvance._(
      units: units,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      interaction: interaction,
      changed: changed,
      events: events.isEmpty ? const [] : List.unmodifiable(events),
      executions: executions.isEmpty ? const [] : List.unmodifiable(executions),
    );
  }

  const TurnAutoExploreAdvance._({
    required this.units,
    required this.fogOfWar,
    required this.diplomacy,
    required this.interaction,
    required this.changed,
    required this.events,
    required this.executions,
  });

  final List<GameUnit> units;
  final FogOfWarState fogOfWar;
  final DiplomacyState diplomacy;
  final DomainActionState interaction;
  final bool changed;
  final List<GameEvent> events;
  final List<MovementCommandExecution> executions;
}

abstract final class TurnAutoExploreAdvancer {
  static TurnAutoExploreAdvance advance({
    required List<GameUnit> units,
    required FogOfWarState fogOfWar,
    required DiplomacyState diplomacy,
    required DomainActionState interaction,
    required List<GameCity> cities,
    required Set<String> playerIds,
    required Set<String> phaseKnownPlayerIds,
    required MapTraversalView mapData,
    required FogOfWarService fogOfWarService,
    TransportNetworkState transportNetwork = TransportNetworkState.empty,
  }) {
    var currentUnits = units;
    var currentFog = fogOfWar;
    var currentDiplomacy = diplomacy;
    var currentInteraction = interaction;
    var changed = false;
    final events = <GameEvent>[];
    final executions = <MovementCommandExecution>[];

    for (var index = 0; index < currentUnits.length; index++) {
      final unit = currentUnits[index];
      if (!_canAdvance(unit, playerIds)) continue;
      final result = _resolveContinuation(
        unit: unit,
        state: _continuationState(
          units: currentUnits,
          cities: cities,
          fogOfWar: currentFog,
          diplomacy: currentDiplomacy,
          playerIds: phaseKnownPlayerIds,
          interaction: currentInteraction,
          transportNetwork: transportNetwork,
        ),
        mapData: mapData,
        fogOfWarService: fogOfWarService,
      );
      if (!result.accepted) continue;

      changed =
          changed ||
          !identical(result.units, currentUnits) ||
          !identical(result.fogOfWar, currentFog) ||
          !identical(result.diplomacy, currentDiplomacy) ||
          !identical(result.interaction, currentInteraction);
      currentUnits = result.units;
      currentFog = result.fogOfWar;
      currentDiplomacy = result.diplomacy;
      currentInteraction = result.interaction;
      events.addAll(result.events);
      if (result.execution case final execution?) executions.add(execution);
    }
    return TurnAutoExploreAdvance(
      units: currentUnits,
      fogOfWar: currentFog,
      diplomacy: currentDiplomacy,
      interaction: currentInteraction,
      changed: changed,
      events: events,
      executions: executions,
    );
  }

  static AutoExploreCommandState _continuationState({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required FogOfWarState fogOfWar,
    required DiplomacyState diplomacy,
    required Set<String> playerIds,
    required DomainActionState interaction,
    required TransportNetworkState transportNetwork,
  }) {
    return AutoExploreCommandState(
      movement: MovementCommandState(
        units: units,
        cities: cities,
        fogOfWar: fogOfWar,
        diplomacy: diplomacy,
        playerIds: playerIds,
        transportNetwork: transportNetwork,
      ),
      interaction: interaction,
    );
  }

  static AutoExploreCommandResult _resolveContinuation({
    required GameUnit unit,
    required AutoExploreCommandState state,
    required MapTraversalView mapData,
    required FogOfWarService fogOfWarService,
  }) {
    return AutoExploreCommandResolver(fogOfWarService: fogOfWarService).resolve(
      state: state,
      command: AutoExploreUnitCommand(unit.id),
      actorPlayerId: unit.ownerPlayerId,
      mapData: mapData,
      phase: AutoExploreCommandPhase.continuation,
    );
  }

  static bool _canAdvance(GameUnit unit, Set<String> playerIds) {
    return playerIds.contains(unit.ownerPlayerId) &&
        unit.type == GameUnitType.scout &&
        unit.isAutoExploring &&
        unit.movementPoints > 0 &&
        unit.queuedPath == null &&
        !unit.isWorking &&
        !unit.isFortified;
  }
}
