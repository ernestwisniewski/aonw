import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
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
