import '../../cities/application/city_state.dart';
import '../../combat/application/combat_state.dart';
import '../../logistics/application/unit_logistics_state.dart';
import '../../unit_actions/application/action_deck_state.dart';
import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';

enum MapMovementFailureViewCode {
  requestFailed,
  responseIncompatible,
  sessionUnavailable,
  moveRejected,
}

final class MapMovementFailure {
  const MapMovementFailure(this.code) : rejectionCode = null;

  const MapMovementFailure.rejected(this.rejectionCode)
    : code = MapMovementFailureViewCode.moveRejected;

  final MapMovementFailureViewCode code;
  final CommandRejectionCodeView? rejectionCode;
}

final class MapInteractionState {
  const MapInteractionState({
    this.hovered,
    this.selected,
    this.selectedUnitId,
    this.reachable,
    this.route,
    this.movementPending = false,
    this.movementError,
    this.lastMovementExecution,
    this.actionDeck,
    this.unitLogistics,
    this.combat,
    this.city,
    this.referenceVisible = true,
  });

  final MapHexCoordinate? hovered;
  final MapHexCoordinate? selected;
  final String? selectedUnitId;
  final ReachableView? reachable;
  final RoutePlanView? route;
  final bool movementPending;
  final MapMovementFailure? movementError;
  final MoveUnitExecutionView? lastMovementExecution;
  final ActionDeckViewState? actionDeck;
  final UnitLogisticsState? unitLogistics;
  final CombatState? combat;
  final CityState? city;
  final bool referenceVisible;

  MapInteractionState copyWith({
    MapHexCoordinate? hovered,
    bool clearHovered = false,
    MapHexCoordinate? selected,
    bool clearSelected = false,
    String? selectedUnitId,
    bool clearSelectedUnit = false,
    ReachableView? reachable,
    bool clearReachable = false,
    RoutePlanView? route,
    bool clearRoute = false,
    bool? movementPending,
    MapMovementFailure? movementError,
    bool clearMovementError = false,
    MoveUnitExecutionView? lastMovementExecution,
    ActionDeckViewState? actionDeck,
    bool clearActionDeck = false,
    UnitLogisticsState? unitLogistics,
    bool clearUnitLogistics = false,
    CombatState? combat,
    bool clearCombat = false,
    CityState? city,
    bool clearCity = false,
    bool? referenceVisible,
  }) => MapInteractionState(
    hovered: _replaceNullable(this.hovered, hovered, clearHovered),
    selected: _replaceNullable(this.selected, selected, clearSelected),
    selectedUnitId: _replaceNullable(
      this.selectedUnitId,
      selectedUnitId,
      clearSelectedUnit,
    ),
    reachable: _replaceNullable(this.reachable, reachable, clearReachable),
    route: _replaceNullable(this.route, route, clearRoute),
    movementPending: movementPending ?? this.movementPending,
    movementError: _replaceNullable(
      this.movementError,
      movementError,
      clearMovementError,
    ),
    lastMovementExecution: lastMovementExecution ?? this.lastMovementExecution,
    actionDeck: _replaceNullable(this.actionDeck, actionDeck, clearActionDeck),
    unitLogistics: _replaceNullable(
      this.unitLogistics,
      unitLogistics,
      clearUnitLogistics,
    ),
    combat: _replaceNullable(this.combat, combat, clearCombat),
    city: _replaceNullable(this.city, city, clearCity),
    referenceVisible: referenceVisible ?? this.referenceVisible,
  );
}

T? _replaceNullable<T>(T? current, T? replacement, bool clear) =>
    clear ? null : replacement ?? current;
