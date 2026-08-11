import 'package:aonw_core/game/domain/diplomacy/diplomatic_contact.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/runtime/pending_player_action.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_auto_explore_advancer.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_context.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_state.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_unit_movement_advancer.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_worker_automation_advancer.dart';

abstract final class TurnMovementOrchestrator {
  static TurnMovementResult resetForPlayers({
    required TurnMovementState state,
    required TurnMovementContext context,
  }) {
    if (context.playerIds.isEmpty) return TurnMovementResult(state: state);
    final phases = _runPhases(state: state, context: context);
    final changed = _movementChanged(
      advanced: phases.advanced,
      interactionChanged: phases.interactionChanged,
      diplomacyChanged: phases.diplomacyChanged,
      workerAutomationChanged: phases.workerAutomation.changed,
      autoExploreChanged: phases.autoExplore.changed,
    );
    if (!changed) return TurnMovementResult(state: state);
    final executions = [
      ...phases.advanced.executions,
      ...phases.workerAutomation.executions,
      ...phases.autoExplore.executions,
    ];
    return _movementResult(
      state: state,
      advanced: phases.advanced,
      workerAutomation: phases.workerAutomation,
      autoExplore: phases.autoExplore,
      executions: executions,
    );
  }

  static _TurnMovementPhases _runPhases({
    required TurnMovementState state,
    required TurnMovementContext context,
  }) {
    final interaction = _expireTurnSkip(state.interaction, context.playerIds);
    final advanced = TurnUnitMovementAdvancer.advance(
      units: state.units,
      cities: state.cities,
      diplomacy: state.diplomacy,
      fogOfWar: state.fogOfWar,
      playerIds: context.playerIds,
      mapData: context.mapData,
      transportNetwork: state.transportNetwork,
    );
    final fogOfWar = advanced.changed
        ? context.fogOfWarService.recompute(
            current: state.fogOfWar,
            mapData: context.mapData,
            playerIds: context.phaseKnownPlayerIds,
            units: advanced.units,
            cities: state.cities,
          )
        : state.fogOfWar;
    final diplomacy = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: state.diplomacy,
      fogOfWar: fogOfWar,
      units: advanced.units,
      cities: state.cities,
      playerIds: context.phaseKnownPlayerIds,
    );
    final workerAutomation = TurnWorkerAutomationAdvancer.advance(
      units: advanced.units,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      research: state.research,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      interaction: interaction,
      playerIds: context.playerIds,
      mapData: context.mapData,
      fogOfWarService: context.fogOfWarService,
      cityRuleset: context.ruleset.city,
      technologyRuleset: context.ruleset.technology,
      paceBalance: context.ruleset.paceBalance,
      transportNetwork: state.transportNetwork,
    );
    final autoExplore = _advanceAutoExplore(
      state: state,
      context: context,
      workerAutomation: workerAutomation,
    );
    return _TurnMovementPhases(
      advanced: advanced,
      interactionChanged: interaction != state.interaction,
      diplomacyChanged: !identical(diplomacy, state.diplomacy),
      workerAutomation: workerAutomation,
      autoExplore: autoExplore,
    );
  }
}

DomainActionState _expireTurnSkip(
  DomainActionState interaction,
  Set<String> playerIds,
) {
  final pending = interaction.pendingAction;
  if (pending is! PendingUnitTurnSkip ||
      !playerIds.contains(pending.ownerPlayerId)) {
    return interaction;
  }
  return interaction.copyWith(pendingAction: null);
}

TurnAutoExploreAdvance _advanceAutoExplore({
  required TurnMovementState state,
  required TurnMovementContext context,
  required TurnWorkerAutomationAdvance workerAutomation,
}) {
  return TurnAutoExploreAdvancer.advance(
    units: workerAutomation.units,
    fogOfWar: workerAutomation.fogOfWar,
    diplomacy: workerAutomation.diplomacy,
    interaction: workerAutomation.interaction,
    cities: state.cities,
    playerIds: context.playerIds,
    phaseKnownPlayerIds: context.phaseKnownPlayerIds,
    mapData: context.mapData,
    fogOfWarService: context.fogOfWarService,
    transportNetwork: state.transportNetwork,
  );
}

final class _TurnMovementPhases {
  const _TurnMovementPhases({
    required this.advanced,
    required this.interactionChanged,
    required this.diplomacyChanged,
    required this.workerAutomation,
    required this.autoExplore,
  });

  final TurnUnitMovementAdvance advanced;
  final bool interactionChanged;
  final bool diplomacyChanged;
  final TurnWorkerAutomationAdvance workerAutomation;
  final TurnAutoExploreAdvance autoExplore;
}

TurnMovementResult _movementResult({
  required TurnMovementState state,
  required TurnUnitMovementAdvance advanced,
  required TurnWorkerAutomationAdvance workerAutomation,
  required TurnAutoExploreAdvance autoExplore,
  required List<MovementCommandExecution> executions,
}) {
  return TurnMovementResult(
    state: TurnMovementState(
      units: List.unmodifiable(autoExplore.units),
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      research: state.research,
      diplomacy: autoExplore.diplomacy,
      fogOfWar: autoExplore.fogOfWar,
      interaction: autoExplore.interaction,
      transportNetwork: state.transportNetwork,
    ),
    changed: true,
    events: _withMissingMovementEvents([
      ...advanced.events,
      ...workerAutomation.events,
      ...autoExplore.events,
    ], executions),
    executions: executions,
  );
}

bool _movementChanged({
  required TurnUnitMovementAdvance advanced,
  required bool interactionChanged,
  required bool diplomacyChanged,
  required bool workerAutomationChanged,
  required bool autoExploreChanged,
}) =>
    advanced.changed ||
    advanced.events.isNotEmpty ||
    interactionChanged ||
    diplomacyChanged ||
    workerAutomationChanged ||
    autoExploreChanged;

List<GameEvent> _withMissingMovementEvents(
  Iterable<GameEvent> events,
  Iterable<MovementCommandExecution> executions,
) {
  final orderedEvents = events.toList(growable: false);
  final existing = {
    for (final event in orderedEvents.whereType<UnitMovedEvent>())
      _movementKey(
        event.unitId,
        event.fromCol,
        event.fromRow,
        event.toCol,
        event.toRow,
      ),
  };
  final byUnitId = <String, List<MovementCommandExecution>>{};
  for (final execution in executions) {
    byUnitId.putIfAbsent(execution.unitId, () => []).add(execution);
  }
  final leadingAlerts = orderedEvents
      .takeWhile((event) => event is FortifiedUnitThreatenedEvent)
      .toList(growable: false);
  return [
    ...leadingAlerts,
    for (final entry in byUnitId.entries)
      if (entry.value.last.steps.isNotEmpty &&
          !existing.contains(_executionKey(entry.key, entry.value)))
        UnitMovedEvent(
          unitId: entry.key,
          fromCol: entry.value.first.fromCol,
          fromRow: entry.value.first.fromRow,
          toCol: entry.value.last.destination.col,
          toRow: entry.value.last.destination.row,
        ),
    ...orderedEvents.skip(leadingAlerts.length),
  ];
}

String _executionKey(String unitId, List<MovementCommandExecution> executions) {
  final first = executions.first;
  final last = executions.last;
  return _movementKey(
    unitId,
    first.fromCol,
    first.fromRow,
    last.destination.col,
    last.destination.row,
  );
}

String _movementKey(
  String unitId,
  int fromCol,
  int fromRow,
  int toCol,
  int toRow,
) => '$unitId\u0000$fromCol\u0000$fromRow\u0000$toCol\u0000$toRow';
