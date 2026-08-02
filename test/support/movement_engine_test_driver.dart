import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/accepted_engine_command_interaction_source.dart';
import 'package:aonw/game/application/services/local_movement_engine_projection.dart';
import 'package:aonw/game/application/services/local_movement_presentation_origin.dart';
import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

GameStateTransition resolveMovementCommandForTest(
  GameClientState state,
  DomainCommand command,
  MapTileLookup mapTiles, {
  GameCommandContext context = const GameCommandContext(),
  MovementCommandVisibilityMode visibilityMode =
      MovementCommandVisibilityMode.authoritative,
}) {
  if (!_canAct(state, context)) {
    return GameStateTransition(state: state);
  }
  final mapView = mapTiles is MapReadView
      ? mapTiles
      : _TestMapReadView(mapTiles);
  final snapshot = _snapshotFor(state);
  final actorPlayerId =
      context.actorPlayerId ??
      (state.activePlayerId.isNotEmpty
          ? state.activePlayerId
          : _commandOwner(snapshot, command));
  final result = const GameEngine().apply(
    snapshot: snapshot,
    command: command,
    context: GameEngineContext(
      actorPlayerId: actorPlayerId,
      mapView: mapView,
      ruleset: GameRuleset.standard(),
      commandTick: context.commandTick,
      movementVisibilityMode: _visibilityMode(
        state: state,
        context: context,
        requested: visibilityMode,
      ),
    ),
  );
  if (result case final GameEngineRejected rejected) {
    return GameStateTransition(
      state: state,
      uiEffects:
          command is MoveUnitCommand &&
              rejected.reason == 'unit_movement_capacity_insufficient'
          ? const [
              ShowHudFeedbackEffect(
                reason: HudFeedbackReason.movementInsufficientUnitMovement,
              ),
            ]
          : const [],
    );
  }
  final accepted = result as GameEngineAccepted;
  if (identical(accepted.snapshot, snapshot) &&
      accepted.events.isEmpty &&
      accepted.movementDelta.executions.isEmpty &&
      command is! CancelUnitActionCommand) {
    return GameStateTransition(state: state);
  }
  final projection = projectLocalMovementEngineResult(
    currentState: acceptedEngineCommandInteractionSource(
      currentState: state,
      command: command,
      family: GameEngineCommandFamily.movement,
      domainActions: accepted.snapshot.domain.actions,
    ),
    result: accepted,
    command: command,
    mapView: mapView,
    presentationOrigin: _presentationOrigin(state, command),
  );
  return GameStateTransition(
    state: projection.state,
    events: accepted.events,
    uiEffects: QueuedMovementEffectBuilder.fromExecutions(
      projection.movementExecutions,
    ),
  );
}

LocalMovementPresentationOrigin _presentationOrigin(
  GameClientState state,
  DomainCommand command,
) {
  final preview = state.movePreview;
  return command is MoveUnitCommand &&
          preview?.unitId == command.unitId &&
          preview?.targetCol == command.targetCol &&
          preview?.targetRow == command.targetRow
      ? LocalMovementPresentationOrigin.previewConfirmation
      : LocalMovementPresentationOrigin.direct;
}

bool _canAct(GameClientState state, GameCommandContext context) {
  return context.canAct && (context.hasActor || state.activePlayerCanAct);
}

MovementCommandVisibilityMode _visibilityMode({
  required GameClientState state,
  required GameCommandContext context,
  required MovementCommandVisibilityMode requested,
}) {
  if (requested != MovementCommandVisibilityMode.authoritative) {
    return requested;
  }
  if (context.ignoreFogOfWar ||
      !context.hasActor && state.activePlayerId.isEmpty) {
    return MovementCommandVisibilityMode.unrestricted;
  }
  return requested;
}

final class _TestMapReadView implements MapReadView {
  const _TestMapReadView(this.mapTiles);

  @override
  final MapTileLookup mapTiles;

  MapTraversalView? get _traversal =>
      mapTiles is MapTraversalView ? mapTiles as MapTraversalView : null;

  @override
  int get cols => _traversal?.cols ?? 0;

  @override
  int get rows => _traversal?.rows ?? 0;

  @override
  MapTileView? tileAt(int col, int row) => mapTiles.tileAt(col, row);

  @override
  String? get mapName => null;

  @override
  Iterable<MapObjectiveDefinition> get objectives => const [];

  @override
  int get tileCount => tileViews.length;

  @override
  Iterable<Iterable<TerrainType>> get tileTerrains =>
      tileViews.map((tile) => tile.terrains);

  @override
  Iterable<MapTileView> get tileViews sync* {
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final tile = tileAt(col, row);
        if (tile != null) yield tile;
      }
    }
  }
}

CanonicalGameSnapshot _snapshotFor(GameClientState state) {
  return GameSnapshotFactory.fromDomainState(
    save: GameSave(
      id: 'movement_engine_test',
      name: 'Movement engine test',
      mapName: 'test',
      turn: state.domain.turn,
      playerStates: state.domain.turnStatesByPlayerId,
      savedAt: DateTime.utc(1970),
      camera: CameraState.zero,
      players: state.domain.participants,
      gameMode: state.domain.gameMode,
      matchRules: state.domain.matchRules,
    ),
    state: state.domain,
  );
}

String _commandOwner(CanonicalGameSnapshot snapshot, DomainCommand command) {
  final unitId = switch (command) {
    MoveUnitCommand(:final unitId) ||
    CancelUnitActionCommand(:final unitId) ||
    AutoExploreUnitCommand(:final unitId) ||
    AssignMerchantTradeRouteCommand(:final unitId) ||
    MoveMerchantToCityCommand(:final unitId) ||
    DetachTroopCommand(:final unitId) => unitId,
    _ => '',
  };
  return snapshot.domain.units.byId(unitId)?.ownerPlayerId ?? '';
}
