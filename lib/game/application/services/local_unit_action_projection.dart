import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

GameClientState projectLocalUnitActionPresentation({
  required MapReadView mapView,
  required GameClientState currentState,
  required CanonicalGameSnapshot baseSnapshot,
  required CanonicalGameSnapshot resultSnapshot,
  required DomainCommand command,
}) {
  final unitId = switch (command) {
    SkipUnitTurnCommand(:final unitId) => unitId,
    FortifyUnitCommand(:final unitId) => unitId,
    _ => '',
  };
  final projected = _projectCanonicalSlices(
    currentState: currentState,
    baseSnapshot: baseSnapshot,
    resultSnapshot: resultSnapshot,
  );
  if (currentState.units.byId(unitId) == null) return projected;
  final updatedUnit = projected.units.byId(unitId);
  if (updatedUnit == null) return projected;

  final targetingCleared = _clearOwnedMoveTargeting(projected, unitId);
  if (targetingCleared.selectedUnitId != unitId) return targetingCleared;
  final selection =
      GameSelection.unit(
        updatedUnit,
        tile: mapView.tileAt(updatedUnit.col, updatedUnit.row),
      ).withVisibleResources(
        playerId: targetingCleared.activePlayerId,
        research: targetingCleared.research,
      );
  return targetingCleared.copyWithInteraction(selection: selection);
}

GameClientState _clearOwnedMoveTargeting(GameClientState state, String unitId) {
  final owned =
      state.selectedUnitId == unitId || state.movePreview?.unitId == unitId;
  final hasTargeting = state.moveCommandActive || state.movePreview != null;
  if (!owned || !hasTargeting) return state;
  return state.copyWithInteraction(moveCommandActive: false, movePreview: null);
}

GameClientState _projectCanonicalSlices({
  required GameClientState currentState,
  required CanonicalGameSnapshot baseSnapshot,
  required CanonicalGameSnapshot resultSnapshot,
}) {
  var state = currentState;
  if (!identical(resultSnapshot.domain.units, baseSnapshot.domain.units)) {
    state = state.copyWith(units: resultSnapshot.domain.units);
  }
  if (!identical(
    resultSnapshot.domain.artifacts,
    baseSnapshot.domain.artifacts,
  )) {
    state = state.copyWith(artifacts: resultSnapshot.domain.artifacts);
  }
  if (!identical(resultSnapshot.domain.actions, baseSnapshot.domain.actions)) {
    state = state.copyWithInteraction(
      cityFoundingDraft: resultSnapshot.domain.actions.cityFoundingDraft,
      pendingAction: resultSnapshot.domain.actions.pendingAction,
    );
  }
  return state;
}
