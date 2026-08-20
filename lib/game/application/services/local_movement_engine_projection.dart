import 'package:aonw/game/application/services/client_interaction_ownership.dart';
import 'package:aonw/game/application/services/local_movement_presentation_origin.dart';
import 'package:aonw/game/application/services/multiplayer_interaction_reconciler.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class LocalMovementEngineProjection {
  const LocalMovementEngineProjection({
    required this.state,
    required this.movementExecutions,
  });

  final GameClientState state;
  final List<MovementCommandExecution> movementExecutions;
}

LocalMovementEngineProjection projectLocalMovementEngineResult({
  required GameClientState currentState,
  required GameEngineAccepted result,
  required DomainCommand command,
  required MapReadView mapView,
  required String actorPlayerId,
  LocalMovementPresentationOrigin presentationOrigin =
      LocalMovementPresentationOrigin.direct,
}) {
  final state =
      ClientInteractionOwnership.actorMayProject(
        state: currentState,
        actorPlayerId: actorPlayerId,
      )
      ? _projectActorInteraction(
          currentState: currentState,
          result: result,
          command: command,
          mapView: mapView,
          presentationOrigin: presentationOrigin,
        )
      : _reconcileForeignActorInteraction(
          currentState: currentState,
          result: result,
        );
  return LocalMovementEngineProjection(
    state: state,
    movementExecutions: result.movementDelta.executions,
  );
}

GameClientState _projectActorInteraction({
  required GameClientState currentState,
  required GameEngineAccepted result,
  required DomainCommand command,
  required MapReadView mapView,
  required LocalMovementPresentationOrigin presentationOrigin,
}) {
  final projected = _projectCanonicalSlices(
    currentState: currentState,
    result: result,
  );
  return switch (command) {
    MoveUnitCommand(:final unitId) => _projectMove(
      currentState: currentState,
      projected: projected,
      unitId: unitId,
      mapView: mapView,
      presentationOrigin: presentationOrigin,
    ),
    CancelUnitActionCommand(:final unitId) => _projectCancel(
      currentState: currentState,
      projected: projected,
      unitId: unitId,
      mapView: mapView,
    ),
    AutomatedUnitCommand(:final unitId) => _projectAutoExplore(
      projected: projected,
      unitId: unitId,
      mapView: mapView,
    ),
    AssignMerchantTradeRouteCommand(:final unitId) ||
    MoveMerchantToCityCommand(:final unitId) => _projectMerchant(
      currentState: currentState,
      projected: projected,
      unitId: unitId,
      mapView: mapView,
    ),
    DetachTroopCommand(:final unitId) => _projectDetachment(
      projected: projected,
      unitId: unitId,
      mapView: mapView,
    ),
    _ => projected,
  };
}

GameClientState _reconcileForeignActorInteraction({
  required GameClientState currentState,
  required GameEngineAccepted result,
}) {
  return MultiplayerInteractionReconciler.reconcile(
    authoritativeState: GameClientState.fromDomain(
      domain: result.snapshot.domain,
      activePlayerId: currentState.activePlayerId,
      activePlayerCanAct: currentState.activePlayerCanAct,
    ),
    interactionSource: currentState,
  );
}

GameClientState _projectCanonicalSlices({
  required GameClientState currentState,
  required GameEngineAccepted result,
}) => currentState.withDomain(result.snapshot.domain);

GameClientState _projectMove({
  required GameClientState currentState,
  required GameClientState projected,
  required String unitId,
  required MapReadView mapView,
  required LocalMovementPresentationOrigin presentationOrigin,
}) {
  final ownsMoveTargeting =
      currentState.selectedUnitId == unitId ||
      currentState.movePreview?.unitId == unitId;
  if (identical(projected.units, currentState.units)) {
    if (!ownsMoveTargeting ||
        presentationOrigin !=
            LocalMovementPresentationOrigin.previewConfirmation) {
      return projected;
    }
    final unit = projected.units.byId(unitId);
    return projected.copyWithInteraction(
      moveCommandActive: _canRetargetMove(projected, unit),
      movePreview: null,
    );
  }
  final updatedUnit = projected.units.byId(unitId);
  var state = ownsMoveTargeting
      ? projected.copyWithInteraction(
          moveCommandActive:
              presentationOrigin ==
                  LocalMovementPresentationOrigin.previewConfirmation
              ? _canRetargetMove(projected, updatedUnit)
              : currentState.moveCommandActive,
          movePreview: null,
        )
      : projected;
  if (state.selectedUnitId == unitId) {
    state = _selectUpdatedUnit(state, unitId, mapView);
  }
  return state;
}

bool _canRetargetMove(GameClientState state, GameUnit? unit) {
  return unit != null &&
      state.canControlUnit(unit) &&
      UnitManualMovementRules.canStartTargeting(unit);
}

GameClientState _projectCancel({
  required GameClientState currentState,
  required GameClientState projected,
  required String unitId,
  required MapReadView mapView,
}) {
  final previousUnit = currentState.units.byId(unitId);
  final updatedUnit = projected.units.byId(unitId);
  if (previousUnit == null || updatedUnit == null) return projected;
  var state = projected;
  final ownsTargeting =
      state.selectedUnitId == unitId || state.movePreview?.unitId == unitId;
  if (ownsTargeting && (state.moveCommandActive || state.movePreview != null)) {
    state = state.copyWithInteraction(
      moveCommandActive: false,
      movePreview: null,
    );
  }
  if (state.selectedUnitId == unitId) {
    state = _selectUpdatedUnit(state, unitId, mapView);
  }
  if (_shouldReactivateMoveTargeting(
    previousUnit: previousUnit,
    updatedUnit: updatedUnit,
    state: state,
  )) {
    state = state.copyWithInteraction(moveCommandActive: true);
  }
  return state;
}

bool _shouldReactivateMoveTargeting({
  required GameUnit previousUnit,
  required GameUnit updatedUnit,
  required GameClientState state,
}) {
  return previousUnit.isFortified &&
      state.selectedUnitId == updatedUnit.id &&
      state.canControlUnit(updatedUnit) &&
      UnitManualMovementRules.canStartTargeting(updatedUnit);
}

GameClientState _projectAutoExplore({
  required GameClientState projected,
  required String unitId,
  required MapReadView mapView,
}) {
  var state = _clearOwnedMoveTargeting(projected, unitId);
  if (state.selectedUnitId == unitId) {
    state = _selectUpdatedUnit(state, unitId, mapView);
  }
  return state;
}

GameClientState _projectMerchant({
  required GameClientState currentState,
  required GameClientState projected,
  required String unitId,
  required MapReadView mapView,
}) {
  var state = projected;
  if (state.pendingAction?.ownsUnit(unitId) ?? false) {
    state = state.copyWithInteraction(pendingAction: null);
  }
  state = _clearOwnedMoveTargeting(state, unitId);
  if (state.cityFoundingDraft?.unitId == unitId) {
    state = state.copyWithInteraction(cityFoundingDraft: null);
  }
  if (!identical(projected.units, currentState.units) &&
      state.selectedUnitId == unitId) {
    state = _selectUpdatedUnit(state, unitId, mapView);
  }
  return state;
}

GameClientState _clearOwnedMoveTargeting(GameClientState state, String unitId) {
  final ownsTargeting =
      state.selectedUnitId == unitId || state.movePreview?.unitId == unitId;
  if (!ownsTargeting || !state.moveCommandActive && state.movePreview == null) {
    return state;
  }
  return state.copyWithInteraction(moveCommandActive: false, movePreview: null);
}

GameClientState _projectDetachment({
  required GameClientState projected,
  required String unitId,
  required MapReadView mapView,
}) {
  var state = _clearOwnedMoveTargeting(projected, unitId);
  if (state.cityFoundingDraft?.unitId == unitId) {
    state = state.copyWithInteraction(cityFoundingDraft: null);
  }
  return state.selectedUnitId == unitId
      ? _selectUpdatedUnit(state, unitId, mapView)
      : state;
}

GameClientState _selectUpdatedUnit(
  GameClientState state,
  String unitId,
  MapTileLookup mapTiles,
) {
  final unit = state.units.byId(unitId);
  if (unit == null) return state;
  final selection =
      GameSelection.unit(
        unit,
        tile: mapTiles.tileAt(unit.col, unit.row),
      ).withVisibleResources(
        playerId: state.activePlayerId,
        research: state.research,
      );
  return state.copyWithInteraction(selection: selection);
}
