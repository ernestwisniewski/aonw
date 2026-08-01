import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_movement_engine_projection.dart';
import 'package:aonw/game/application/services/local_movement_presentation_origin.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class LocalMovementCommandResolution {
  const LocalMovementCommandResolution({
    required this.snapshot,
    required this.state,
    required this.events,
    required this.uiEffects,
    this.movementExecutions = const [],
  });

  final CanonicalGameSnapshot snapshot;
  final GameClientState state;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;
  final List<MovementCommandExecution> movementExecutions;
}

final class LocalMovementCommandResolver {
  const LocalMovementCommandResolver({
    required this.mapView,
    required this.ruleset,
  });

  final MapReadView mapView;
  final GameRuleset ruleset;

  LocalMovementCommandResolution resolve({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
    LocalMovementPresentationOrigin presentationOrigin =
        LocalMovementPresentationOrigin.direct,
  }) {
    if (!_canAct(currentState, context)) {
      return _unchanged(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command,
        savedAt: savedAt,
        presentationOrigin: presentationOrigin,
      );
    }
    final result = _applyEngine(
      snapshot: baseSnapshot,
      state: currentState,
      command: command,
      context: context,
    );
    if (result case final GameEngineRejected rejected) {
      return _unchanged(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command,
        savedAt: savedAt,
        rejectionReason: rejected.reason,
        presentationOrigin: presentationOrigin,
      );
    }
    final accepted = result as GameEngineAccepted;
    return _acceptedResolution(
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      savedAt: savedAt,
      accepted: accepted,
      presentationOrigin: presentationOrigin,
    );
  }

  GameEngineResult _applyEngine({
    required CanonicalGameSnapshot snapshot,
    required GameClientState state,
    required DomainCommand command,
    required GameCommandContext context,
  }) {
    return const GameEngine().apply(
      snapshot: snapshot.canonical,
      command: command,
      context: GameEngineContext(
        actorPlayerId: _actorPlayerId(
          snapshot: snapshot,
          state: state,
          command: command,
          context: context,
        ),
        mapView: mapView,
        ruleset: ruleset,
        commandTick: context.commandTick,
        movementVisibilityMode: _visibilityMode(state, context),
      ),
    );
  }

  LocalMovementCommandResolution _acceptedResolution({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameEngineAccepted accepted,
    required LocalMovementPresentationOrigin presentationOrigin,
  }) {
    final presentation = projectLocalMovementEngineResult(
      currentState: currentState,
      result: accepted,
      command: command,
      mapView: mapView,
      presentationOrigin: presentationOrigin,
    );
    return LocalMovementCommandResolution(
      snapshot: baseSnapshot.withMovementEngineProjection(
        resultSnapshot: accepted.snapshot,
        savedAt: savedAt,
      ),
      state: presentation.state,
      events: accepted.events,
      uiEffects: const [],
      movementExecutions: presentation.movementExecutions,
    );
  }

  bool _canAct(GameClientState state, GameCommandContext context) {
    return context.canAct && (context.hasActor || state.activePlayerCanAct);
  }

  MovementCommandVisibilityMode _visibilityMode(
    GameClientState state,
    GameCommandContext context,
  ) {
    if (context.ignoreFogOfWar ||
        !context.hasActor && state.activePlayerId.isEmpty) {
      return MovementCommandVisibilityMode.unrestricted;
    }
    return MovementCommandVisibilityMode.authoritative;
  }

  LocalMovementCommandResolution _unchanged({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    String? rejectionReason,
    required LocalMovementPresentationOrigin presentationOrigin,
  }) {
    final previewConfirmation =
        command is MoveUnitCommand &&
        presentationOrigin ==
            LocalMovementPresentationOrigin.previewConfirmation;
    return LocalMovementCommandResolution(
      snapshot: baseSnapshot.withMovementEngineProjection(
        resultSnapshot: baseSnapshot.canonical,
        savedAt: savedAt,
      ),
      state: previewConfirmation
          ? currentState.copyWithInteraction(
              moveCommandActive:
                  _canRetargetAfterRejectedMove(rejectionReason) &&
                  currentState.moveCommandActive,
              movePreview: null,
            )
          : currentState,
      events: const [],
      uiEffects:
          command is MoveUnitCommand &&
              rejectionReason == 'unit_movement_capacity_insufficient'
          ? const [
              ShowHudFeedbackEffect(
                reason: HudFeedbackReason.movementInsufficientUnitMovement,
              ),
            ]
          : const [],
    );
  }

  bool _canRetargetAfterRejectedMove(String? reason) {
    return switch (reason) {
      'move_target_out_of_bounds' ||
      'move_path_not_found' ||
      'move_target_is_foreign_city_center' ||
      'move_target_occupied' ||
      'unit_movement_capacity_insufficient' => true,
      _ => false,
    };
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
