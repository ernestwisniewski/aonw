import 'package:aonw/game/application/services/local_movement_presentation_origin.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:flutter/foundation.dart';

final class LocalMovementEngineProjection {
  const LocalMovementEngineProjection({
    required this.state,
    required this.movementExecutions,
  });

  final GameState state;
  final List<MovementCommandExecution> movementExecutions;
}

LocalMovementEngineProjection projectLocalMovementEngineResult({
  required GameState currentState,
  required GameEngineAccepted result,
  required DomainCommand command,
  required MapReadView mapView,
  LocalMovementPresentationOrigin presentationOrigin =
      LocalMovementPresentationOrigin.direct,
}) {
  final projected = _projectCanonicalSlices(
    currentState: currentState,
    result: result,
  );
  final state = switch (command) {
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
    AutoExploreUnitCommand(:final unitId) => _projectAutoExplore(
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
  return LocalMovementEngineProjection(
    state: state,
    movementExecutions: result.movementDelta.executions,
  );
}

GameState projectUnchangedLocalMovementPresentation({
  required GameState currentState,
  required DomainCommand command,
  required LocalMovementPresentationOrigin presentationOrigin,
}) {
  if (command is! MoveUnitCommand ||
      presentationOrigin !=
          LocalMovementPresentationOrigin.previewConfirmation) {
    return currentState;
  }
  return _clearMoveTargeting(currentState);
}

GameState _projectCanonicalSlices({
  required GameState currentState,
  required GameEngineAccepted result,
}) {
  final domain = result.snapshot.domain;
  var state = currentState;
  if (!listEquals(domain.units, currentState.units)) {
    state = state.copyWith(units: domain.units);
  }
  if (!listEquals(domain.artifacts, currentState.artifacts)) {
    state = state.copyWith(artifacts: domain.artifacts);
  }
  if (domain.fogOfWar != currentState.fogOfWar) {
    state = state.copyWith(fogOfWar: domain.fogOfWar);
  }
  if (domain.diplomacy != currentState.diplomacy) {
    state = state.copyWith(diplomacy: domain.diplomacy);
  }
  final interaction = result.snapshot.interaction;
  final cityFoundingDraft =
      state.cityFoundingDraft == interaction.cityFoundingDraft
      ? state.cityFoundingDraft
      : interaction.cityFoundingDraft;
  final pendingAction = state.pendingAction == interaction.pendingAction
      ? state.pendingAction
      : interaction.pendingAction;
  if (!identical(state.cityFoundingDraft, cityFoundingDraft) ||
      !identical(state.pendingAction, pendingAction)) {
    state = state.copyWithInteraction(
      cityFoundingDraft: cityFoundingDraft,
      pendingAction: pendingAction,
    );
  }
  return state;
}

GameState _projectMove({
  required GameState currentState,
  required GameState projected,
  required String unitId,
  required MapReadView mapView,
  required LocalMovementPresentationOrigin presentationOrigin,
}) {
  if (identical(projected.units, currentState.units)) {
    return presentationOrigin ==
            LocalMovementPresentationOrigin.previewConfirmation
        ? _clearMoveTargeting(projected)
        : projected;
  }
  final updatedUnit = projected.units.byId(unitId);
  var state = projected.copyWithInteraction(
    moveCommandActive:
        presentationOrigin ==
            LocalMovementPresentationOrigin.previewConfirmation
        ? updatedUnit?.queuedPath == null
        : currentState.moveCommandActive,
    movePreview: null,
  );
  if (state.selectedUnitId == unitId) {
    state = _selectUpdatedUnit(state, unitId, mapView);
  }
  return state;
}

GameState _clearMoveTargeting(GameState state) {
  return state.copyWithInteraction(moveCommandActive: false, movePreview: null);
}

GameState _projectCancel({
  required GameState currentState,
  required GameState projected,
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
  required GameState state,
}) {
  return previousUnit.isFortified &&
      state.selectedUnitId == updatedUnit.id &&
      state.canControlUnit(updatedUnit) &&
      !updatedUnit.isWorking &&
      !updatedUnit.isMerchant &&
      updatedUnit.queuedPath == null &&
      !updatedUnit.isFortified &&
      !updatedUnit.isAutoExploring;
}

GameState _projectAutoExplore({
  required GameState projected,
  required String unitId,
  required MapReadView mapView,
}) {
  var state = projected.copyWithInteraction(
    moveCommandActive: false,
    movePreview: null,
  );
  if (state.selectedUnitId == unitId) {
    state = _selectUpdatedUnit(state, unitId, mapView);
  }
  return state;
}

GameState _projectMerchant({
  required GameState currentState,
  required GameState projected,
  required String unitId,
  required MapReadView mapView,
}) {
  var state = projected;
  if (state.pendingAction?.ownsUnit(unitId) ?? false) {
    state = state.copyWithInteraction(pendingAction: null);
  }
  if (state.moveCommandActive || state.movePreview != null) {
    state = state.copyWithInteraction(
      moveCommandActive: false,
      movePreview: null,
    );
  }
  if (state.cityFoundingDraft?.unitId == unitId) {
    state = state.copyWithInteraction(cityFoundingDraft: null);
  }
  if (!identical(projected.units, currentState.units) &&
      state.selectedUnitId == unitId) {
    state = _selectUpdatedUnit(state, unitId, mapView);
  }
  return state;
}

GameState _projectDetachment({
  required GameState projected,
  required String unitId,
  required MapReadView mapView,
}) {
  final state = projected.copyWithInteraction(
    moveCommandActive: false,
    movePreview: null,
    cityFoundingDraft: null,
  );
  return _selectUpdatedUnit(state, unitId, mapView);
}

GameState _selectUpdatedUnit(
  GameState state,
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
