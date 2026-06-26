import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_units.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class MerchantTradeRouteReducer {
  static GameStateTransition startSelection(
    GameState state,
    StartMerchantTradeRouteSelectionCommand command,
    MapData mapData, {
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
                mapData: mapData,
                units: state.units,
                cities: state.cities,
              ) !=
              null,
        );
    if (!hasDestination) return GameStateTransition(state: state);

    final tile = mapData.tileAt(unit.col, unit.row);
    return GameStateTransition(
      state: _clearTransientModes(state).copyWith(
        pendingAction: PendingMerchantTradeRouteSelection(
          ownerPlayerId: unit.ownerPlayerId,
          unitId: unit.id,
        ),
        selection: GameSelection.unit(unit, tile: tile),
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
    return GameStateTransition(state: state.copyWith(pendingAction: null));
  }

  static GameStateTransition assignRoute(
    GameState state,
    AssignMerchantTradeRouteCommand command,
    MapData mapData, {
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
    final destination = _findCity(state, command.destinationCityId);
    if (origin == null ||
        destination == null ||
        destination.ownerPlayerId != unit.ownerPlayerId ||
        destination.id == origin.id) {
      return GameStateTransition(state: state);
    }

    final route = MerchantTradeRouteRules.planRoute(
      merchant: unit,
      originCity: origin,
      destinationCity: destination,
      mapData: mapData,
      units: state.units,
      cities: state.cities,
    );
    if (route == null) return GameStateTransition(state: state);

    final updated = unit
        .copyWith(posture: UnitPosture.active)
        .copyWithQueuedPath(null)
        .copyWithMerchantTradeRoute(route);
    var next = state.copyWith(units: replaceUnit(state.units, updated));
    if (next.pendingAction?.ownsUnit(updated.id) ?? false) {
      next = next.copyWith(pendingAction: null);
    }
    next = next.copyWith(moveCommandActive: false, movePreview: null);
    if (next.cityFoundingDraft?.unitId == updated.id) {
      next = next.copyWith(cityFoundingDraft: null);
    }
    if (next.selectedUnitId == updated.id) {
      final tile = mapData.tileAt(updated.col, updated.row);
      next = next.copyWith(selection: GameSelection.unit(updated, tile: tile));
    }
    return GameStateTransition(state: next);
  }

  static GameStateTransition startMoveToCitySelection(
    GameState state,
    StartMerchantMoveToCitySelectionCommand command,
    MapData mapData, {
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
                mapData: mapData,
                units: state.units,
                cities: state.cities,
              ) !=
              null,
        );
    if (!hasDestination) return GameStateTransition(state: state);

    final tile = mapData.tileAt(unit.col, unit.row);
    return GameStateTransition(
      state: _clearTransientModes(state).copyWith(
        pendingAction: PendingMerchantMoveToCitySelection(
          ownerPlayerId: unit.ownerPlayerId,
          unitId: unit.id,
        ),
        selection: GameSelection.unit(unit, tile: tile),
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
    return GameStateTransition(state: state.copyWith(pendingAction: null));
  }

  static GameStateTransition moveToCity(
    GameState state,
    MoveMerchantToCityCommand command,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final unit = _findUnit(state, command.unitId);
    if (unit == null ||
        unit.type != GameUnitType.merchant ||
        unit.isWorking ||
        unit.isFortified ||
        unit.merchantTradeRoute != null ||
        !context.canControlUnit(state, unit)) {
      return GameStateTransition(state: state);
    }

    final destination = _findCity(state, command.destinationCityId);
    if (destination == null ||
        destination.ownerPlayerId != unit.ownerPlayerId ||
        destination.occupiesCenter(unit.col, unit.row)) {
      return GameStateTransition(state: state);
    }

    final plan = MerchantTradeRouteRules.planMoveToCity(
      merchant: unit,
      destinationCity: destination,
      mapData: mapData,
      units: state.units,
      cities: state.cities,
    );
    if (plan == null) return GameStateTransition(state: state);

    final updated = unit
        .copyWith(posture: UnitPosture.active)
        .copyWithQueuedPath(_queuedPathFor(plan))
        .copyWithMerchantTradeRoute(null);
    var next = state.copyWith(units: replaceUnit(state.units, updated));
    if (next.pendingAction?.ownsUnit(updated.id) ?? false) {
      next = next.copyWith(pendingAction: null);
    }
    next = next.copyWith(moveCommandActive: false, movePreview: null);
    if (next.cityFoundingDraft?.unitId == updated.id) {
      next = next.copyWith(cityFoundingDraft: null);
    }
    if (next.selectedUnitId == updated.id) {
      final tile = mapData.tileAt(updated.col, updated.row);
      next = next.copyWith(selection: GameSelection.unit(updated, tile: tile));
    }
    return GameStateTransition(state: next);
  }

  static QueuedMovePath _queuedPathFor(UnitMovementPlan plan) => QueuedMovePath(
    targetCol: plan.targetCol,
    targetRow: plan.targetRow,
    steps: plan.steps,
  );

  static GameState _clearTransientModes(GameState state) => state.copyWith(
    moveCommandActive: false,
    movePreview: null,
    cityFoundingDraft: null,
  );

  static GameUnit? _findUnit(GameState state, String unitId) {
    for (final unit in state.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  static GameCity? _findCity(GameState state, String cityId) {
    for (final city in state.cities) {
      if (city.id == cityId) return city;
    }
    return null;
  }
}
