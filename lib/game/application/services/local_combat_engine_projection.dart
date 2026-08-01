import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

GameClientState projectLocalCombatEngineResult({
  required GameClientState currentState,
  required GameEngineAccepted result,
  required AttackHexCommand command,
  required MapReadView mapView,
}) {
  final domain = result.snapshot.domain;
  var state = currentState.withDomain(domain);
  final pending = state.pendingAction;
  final clearPending =
      pending is PendingAttackTargeting &&
      pending.attackerUnitId == command.attackerUnitId;
  state = state.copyWithInteraction(
    movePreview: null,
    cityFoundingDraft: null,
    pendingAction: clearPending ? null : pending,
    moveCommandActive: false,
  );
  return _refreshSelection(
    state,
    mapView,
    changedCityId: _changedCityId(result.events),
  );
}

String? _changedCityId(Iterable<DomainEvent> events) {
  for (final event in events) {
    if (event case CityAttackedEvent(:final cityId)) return cityId;
  }
  return null;
}

GameClientState _refreshSelection(
  GameClientState state,
  MapTileLookup mapTiles, {
  required String? changedCityId,
}) {
  final selection = state.selection;
  if (selection == null) return state;
  return switch (selection.type) {
    GameSelectionType.tile || GameSelectionType.fieldImprovement => state,
    GameSelectionType.city =>
      selection.city?.id == changedCityId
          ? state.copyWithInteraction(selection: null)
          : state,
    GameSelectionType.unit => _refreshUnit(state, selection, mapTiles),
  };
}

GameClientState _refreshUnit(
  GameClientState state,
  GameSelection selection,
  MapTileLookup mapTiles,
) {
  final selectedId = selection.unit?.id;
  if (selectedId == null) return state.copyWithInteraction(selection: null);
  final unit = state.units.byId(selectedId);
  if (unit == null) return state.copyWithInteraction(selection: null);
  final refreshed =
      GameSelection.unit(
        unit,
        tile: mapTiles.tileAt(unit.col, unit.row),
      ).withVisibleResources(
        playerId: state.activePlayerId,
        research: state.research,
      );
  return state.copyWithInteraction(selection: refreshed);
}
