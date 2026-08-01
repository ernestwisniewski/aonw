import 'package:aonw/game/application/services/local_movement_presentation_origin.dart';
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
  if (identical(projected.units, currentState.units)) {
    if (presentationOrigin !=
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
  var state = projected.copyWithInteraction(
    moveCommandActive:
        presentationOrigin ==
            LocalMovementPresentationOrigin.previewConfirmation
        ? _canRetargetMove(projected, updatedUnit)
        : currentState.moveCommandActive,
    movePreview: null,
  );
  if (state.selectedUnitId == unitId) {
    state = _selectUpdatedUnit(state, unitId, mapView);
  }
  return state;
}

bool _canRetargetMove(GameClientState state, GameUnit? unit) {
  return unit != null &&
      state.canControlUnit(unit) &&
      unit.movementPoints > 0 &&
      !unit.isWorking &&
      !unit.isMerchant &&
      unit.queuedPath == null &&
      !unit.isFortified &&
      !unit.isAutoExploring;
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
      !updatedUnit.isWorking &&
      !updatedUnit.isMerchant &&
      updatedUnit.queuedPath == null &&
      !updatedUnit.isFortified &&
      !updatedUnit.isAutoExploring;
}

GameClientState _projectAutoExplore({
  required GameClientState projected,
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

GameClientState _projectDetachment({
  required GameClientState projected,
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
