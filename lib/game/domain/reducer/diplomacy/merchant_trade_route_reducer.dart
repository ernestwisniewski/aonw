import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class MerchantTradeRouteReducer {
  static GameStateTransition startSelection(
    GameState state,
    StartMerchantTradeRouteSelectionCommand command,
    MapTraversalView mapView, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final unit = _findUnit(state, command.unitId);
    if (unit == null ||
        unit.type != GameUnitType.merchant ||
        unit.isWorking ||
        unit.isFortified ||
        !context.canControlUnit(state, unit)) {
      return GameStateTransition(state: state);
    }

    final origin = MerchantTradeRouteRules.originCityFor(
      merchant: unit,
      cities: state.cities,
    );
    if (origin == null) return GameStateTransition(state: state);

    final hasDestination =
        MerchantTradeRouteRules.destinationCandidatesFor(
          merchant: unit,
          cities: state.cities,
        ).any(
          (city) =>
              MerchantTradeRouteRules.planRoute(
                merchant: unit,
                originCity: origin,
                destinationCity: city,
                mapData: mapView,
                units: state.units,
                cities: state.cities,
              ) !=
              null,
        );
    if (!hasDestination) return GameStateTransition(state: state);

    return GameStateTransition(
      state: _clearTransientModes(state).copyWithInteraction(
        pendingAction: PendingMerchantTradeRouteSelection(
          ownerPlayerId: unit.ownerPlayerId,
          unitId: unit.id,
        ),
        selection: _unitSelection(state, unit, mapView),
      ),
    );
  }

  static GameStateTransition cancelSelection(
    GameState state,
    CancelMerchantTradeRouteSelectionCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingMerchantTradeRouteSelection) {
      return GameStateTransition(state: state);
    }
    if (pending.unitId != command.unitId) {
      return GameStateTransition(state: state);
    }
    return GameStateTransition(
      state: state.copyWithInteraction(pendingAction: null),
    );
  }

  static GameStateTransition assignRoute(
    GameState state,
    AssignMerchantTradeRouteCommand command,
    MapTraversalView mapView, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final units = state.units;
    final cities = state.cities;
    final unit = units.byId(command.unitId);
    if (unit == null || !context.canControlUnit(state, unit)) {
      return GameStateTransition(state: state);
    }
    final result = MerchantRoutingCommandResolver.assignRoute(
      units: units,
      cities: cities,
      mapData: mapView,
      command: command,
      actorPlayerId: unit.ownerPlayerId,
    );
    return _applyRoutingResult(
      state,
      result,
      unit.id,
      mapView,
      inputUnits: units,
    );
  }

  static GameStateTransition startMoveToCitySelection(
    GameState state,
    StartMerchantMoveToCitySelectionCommand command,
    MapTraversalView mapView, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final unit = _findUnit(state, command.unitId);
    if (unit == null ||
        unit.type != GameUnitType.merchant ||
        unit.isWorking ||
        unit.isFortified ||
        unit.queuedPath != null ||
        unit.merchantTradeRoute != null ||
        !context.canControlUnit(state, unit)) {
      return GameStateTransition(state: state);
    }

    final hasDestination =
        MerchantTradeRouteRules.moveToCityCandidatesFor(
          merchant: unit,
          cities: state.cities,
        ).any(
          (city) =>
              MerchantTradeRouteRules.planMoveToCity(
                merchant: unit,
                destinationCity: city,
                mapData: mapView,
                units: state.units,
                cities: state.cities,
              ) !=
              null,
        );
    if (!hasDestination) return GameStateTransition(state: state);

    return GameStateTransition(
      state: _clearTransientModes(state).copyWithInteraction(
        pendingAction: PendingMerchantMoveToCitySelection(
          ownerPlayerId: unit.ownerPlayerId,
          unitId: unit.id,
        ),
        selection: _unitSelection(state, unit, mapView),
      ),
    );
  }

  static GameStateTransition cancelMoveToCitySelection(
    GameState state,
    CancelMerchantMoveToCitySelectionCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingMerchantMoveToCitySelection) {
      return GameStateTransition(state: state);
    }
    if (pending.unitId != command.unitId) {
      return GameStateTransition(state: state);
    }
    return GameStateTransition(
      state: state.copyWithInteraction(pendingAction: null),
    );
  }

  static GameStateTransition moveToCity(
    GameState state,
    MoveMerchantToCityCommand command,
    MapTraversalView mapView, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final units = state.units;
    final cities = state.cities;
    final unit = units.byId(command.unitId);
    if (unit == null || !context.canControlUnit(state, unit)) {
      return GameStateTransition(state: state);
    }
    final result = MerchantRoutingCommandResolver.moveToCity(
      units: units,
      cities: cities,
      mapData: mapView,
      command: command,
      actorPlayerId: unit.ownerPlayerId,
    );
    return _applyRoutingResult(
      state,
      result,
      unit.id,
      mapView,
      inputUnits: units,
    );
  }

  static GameStateTransition _applyRoutingResult(
    GameState state,
    MerchantRoutingCommandResult result,
    String unitId,
    MapTraversalView mapView, {
    required List<GameUnit> inputUnits,
  }) {
    if (!result.accepted) return GameStateTransition(state: state);
    final unitsChanged = !identical(result.units, inputUnits);
    final updated = result.units.byId(unitId)!;
    final cleanup = _merchantRoutingCleanupFor(state, updated.id);
    final hasCleanup =
        cleanup.pendingAction ||
        cleanup.moveTargeting ||
        cleanup.cityFoundingDraft;
    if (!unitsChanged && !hasCleanup) {
      return GameStateTransition(state: state);
    }

    var next = unitsChanged ? state.copyWith(units: result.units) : state;
    next = _applyMerchantRoutingCleanup(next, cleanup);
    if (unitsChanged && next.selectedUnitId == updated.id) {
      next = next.copyWithInteraction(
        selection: _unitSelection(next, updated, mapView),
      );
    }
    return GameStateTransition(state: next);
  }

  static GameState _clearTransientModes(GameState state) =>
      state.copyWith(interaction: state.interaction.clearTransientModes());

  static GameSelection _unitSelection(
    GameState state,
    GameUnit unit,
    MapTileLookup mapTiles,
  ) {
    final tile = mapTiles.tileAt(unit.col, unit.row);
    return GameSelection.unit(unit, tile: tile).withVisibleResources(
      playerId: state.activePlayerId,
      research: state.research,
    );
  }

  static GameUnit? _findUnit(GameState state, String unitId) {
    return state.unitById(unitId);
  }
}

typedef _MerchantRoutingCleanup = ({
  bool pendingAction,
  bool moveTargeting,
  bool cityFoundingDraft,
});

_MerchantRoutingCleanup _merchantRoutingCleanupFor(
  GameState state,
  String unitId,
) => (
  pendingAction: state.pendingAction?.ownsUnit(unitId) ?? false,
  moveTargeting: state.moveCommandActive || state.movePreview != null,
  cityFoundingDraft: state.cityFoundingDraft?.unitId == unitId,
);

GameState _applyMerchantRoutingCleanup(
  GameState state,
  _MerchantRoutingCleanup cleanup,
) {
  var next = state;
  if (cleanup.pendingAction) {
    next = next.copyWithInteraction(pendingAction: null);
  }
  if (cleanup.moveTargeting) {
    next = next.copyWithInteraction(
      moveCommandActive: false,
      movePreview: null,
    );
  }
  if (cleanup.cityFoundingDraft) {
    next = next.copyWithInteraction(cityFoundingDraft: null);
  }
  return next;
}
