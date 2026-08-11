import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/transport.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class TurnWorkerAutomationAdvance {
  factory TurnWorkerAutomationAdvance({
    required List<GameUnit> units,
    required FogOfWarState fogOfWar,
    required DiplomacyState diplomacy,
    required DomainActionState interaction,
    bool changed = false,
    Iterable<GameEvent> events = const [],
    Iterable<MovementCommandExecution> executions = const [],
  }) {
    return TurnWorkerAutomationAdvance._(
      units: units,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      interaction: interaction,
      changed: changed,
      events: events.isEmpty ? const [] : List.unmodifiable(events),
      executions: executions.isEmpty ? const [] : List.unmodifiable(executions),
    );
  }

  const TurnWorkerAutomationAdvance._({
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

abstract final class TurnWorkerAutomationAdvancer {
  static TurnWorkerAutomationAdvance advance({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required FogOfWarState fogOfWar,
    required DiplomacyState diplomacy,
    required DomainActionState interaction,
    required Set<String> playerIds,
    required MapTraversalView mapData,
    required FogOfWarService fogOfWarService,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
    required TransportNetworkState transportNetwork,
  }) {
    final progress = _TurnWorkerAutomationProgress(
      units: units,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      interaction: interaction,
    );
    for (final unitId in _orderedUnitIds(units, playerIds)) {
      final result = _advanceUnit(
        unitId: unitId,
        progress: progress,
        cities: cities,
        fieldImprovements: fieldImprovements,
        research: research,
        playerIds: playerIds,
        mapData: mapData,
        fogOfWarService: fogOfWarService,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: paceBalance,
        transportNetwork: transportNetwork,
      );
      if (result != null) progress.absorb(result);
    }
    return progress.toAdvance();
  }

  static DomainWorkerAutomationCommandResult? _advanceUnit({
    required String unitId,
    required _TurnWorkerAutomationProgress progress,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required Set<String> playerIds,
    required MapTraversalView mapData,
    required FogOfWarService fogOfWarService,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
    required TransportNetworkState transportNetwork,
  }) {
    final unit = _unitById(progress.units, unitId);
    if (unit == null || !_canAdvance(unit, playerIds)) return null;
    final state = DomainState.snapshot(
      units: progress.units,
      cities: cities,
      fieldImprovements: fieldImprovements,
      research: research,
      fogOfWar: progress.fogOfWar,
      diplomacy: progress.diplomacy,
      actions: progress.interaction,
      transportNetwork: transportNetwork,
    );
    final DomainWorkerAutomationCommandResolver resolver =
        DomainWorkerAutomationCommandResolver(fogOfWarService: fogOfWarService);
    final result = resolver.resolve(
      state: state,
      interaction: progress.interaction,
      command: AutomateWorkerCommand(unit.id),
      actorPlayerId: unit.ownerPlayerId,
      mapData: mapData,
      phase: WorkerAutomationCommandPhase.continuation,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
    return result.accepted ? result : null;
  }

  static List<String> _orderedUnitIds(
    List<GameUnit> units,
    Set<String> playerIds,
  ) {
    final result =
        <String>[
          for (final unit in units)
            if (_canAdvance(unit, playerIds)) unit.id,
        ]..sort((firstId, secondId) {
          final first = _unitById(units, firstId)!;
          final second = _unitById(units, secondId)!;
          final owner = first.ownerPlayerId.compareTo(second.ownerPlayerId);
          return owner != 0 ? owner : first.id.compareTo(second.id);
        });
    return result;
  }

  static bool _canAdvance(GameUnit unit, Set<String> playerIds) {
    return playerIds.contains(unit.ownerPlayerId) &&
        unit.isWorker &&
        unit.isAutoWorking &&
        !unit.isWorking &&
        !unit.isFortified &&
        unit.movementPoints > 0;
  }

  static GameUnit? _unitById(Iterable<GameUnit> units, String unitId) {
    for (final unit in units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }
}

final class _TurnWorkerAutomationProgress {
  _TurnWorkerAutomationProgress({
    required this.units,
    required this.fogOfWar,
    required this.diplomacy,
    required this.interaction,
  });

  List<GameUnit> units;
  FogOfWarState fogOfWar;
  DiplomacyState diplomacy;
  DomainActionState interaction;
  bool changed = false;
  final List<GameEvent> events = [];
  final List<MovementCommandExecution> executions = [];

  void absorb(DomainWorkerAutomationCommandResult result) {
    changed =
        changed ||
        !identical(result.state.units, units) ||
        !identical(result.state.fogOfWar, fogOfWar) ||
        !identical(result.state.diplomacy, diplomacy) ||
        !identical(result.interaction, interaction);
    units = result.state.units;
    fogOfWar = result.state.fogOfWar;
    diplomacy = result.state.diplomacy;
    interaction = result.interaction;
    events.addAll(result.events);
    if (result.execution case final execution?) executions.add(execution);
  }

  TurnWorkerAutomationAdvance toAdvance() {
    return TurnWorkerAutomationAdvance(
      units: units,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      interaction: interaction,
      changed: changed,
      events: events,
      executions: executions,
    );
  }
}
