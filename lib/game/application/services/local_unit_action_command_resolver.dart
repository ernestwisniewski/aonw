import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/accepted_engine_command_interaction_source.dart';
import 'package:aonw/game/application/services/local_unit_action_projection.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class LocalUnitActionCommandResolution {
  const LocalUnitActionCommandResolution({
    required this.snapshot,
    required this.state,
    required this.events,
  });

  final CanonicalGameSnapshot snapshot;
  final GameClientState state;
  final List<GameEvent> events;
}

final class LocalUnitActionCommandResolver {
  const LocalUnitActionCommandResolver({
    required this.mapView,
    required this.ruleset,
  });

  final MapReadView mapView;
  final GameRuleset ruleset;

  LocalUnitActionCommandResolution resolve({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    if (!context.canAct ||
        (!context.hasActor && !currentState.activePlayerCanAct)) {
      return _unchanged(baseSnapshot, currentState, savedAt);
    }
    final result = const GameEngine().apply(
      snapshot: baseSnapshot.canonical,
      command: command,
      context: GameEngineContext(
        actorPlayerId: _actorPlayerId(
          snapshot: baseSnapshot,
          state: currentState,
          command: command,
          context: context,
        ),
        mapView: mapView,
        ruleset: ruleset,
        commandTick: context.commandTick,
      ),
    );
    if (result is GameEngineRejected ||
        identical(result.snapshot, baseSnapshot.canonical)) {
      return _unchanged(baseSnapshot, currentState, savedAt);
    }
    return _accepted(
      result: result,
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      savedAt: savedAt,
    );
  }

  LocalUnitActionCommandResolution _accepted({
    required GameEngineResult result,
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
  }) {
    final snapshot = baseSnapshot.withEngineResult(
      resultSnapshot: result.snapshot,
      savedAt: savedAt,
    );
    final presentation = projectLocalUnitActionPresentation(
      mapView: mapView,
      currentState: acceptedEngineCommandInteractionSource(
        currentState: currentState,
        command: command,
        family: GameEngineCommandFamily.unitAction,
        domainActions: result.snapshot.domain.actions,
      ),
      resultSnapshot: result.snapshot,
      command: command,
    );
    return LocalUnitActionCommandResolution(
      snapshot: snapshot,
      state: presentation.withDomain(result.snapshot.domain),
      events: result.events,
    );
  }

  LocalUnitActionCommandResolution _unchanged(
    CanonicalGameSnapshot snapshot,
    GameClientState state,
    DateTime savedAt,
  ) {
    return LocalUnitActionCommandResolution(
      snapshot: snapshot.withEngineResult(
        resultSnapshot: snapshot.canonical,
        savedAt: savedAt,
      ),
      state: state,
      events: const [],
    );
  }

  String _actorPlayerId({
    required CanonicalGameSnapshot snapshot,
    required GameClientState state,
    required DomainCommand command,
    required GameCommandContext context,
  }) {
    final contextActor = context.actorPlayerId;
    if (contextActor != null && contextActor.isNotEmpty) return contextActor;
    if (state.activePlayerId.isNotEmpty) return state.activePlayerId;
    final unitId = (command as UnitDomainCommand).unitId;
    return snapshot.domain.units.byId(unitId)?.ownerPlayerId ?? '';
  }
}
