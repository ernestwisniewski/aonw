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
    bool? referenceVisible,
  }) => MapInteractionState(
    hovered: clearHovered ? null : hovered ?? this.hovered,
    selected: clearSelected ? null : selected ?? this.selected,
    selectedUnitId: clearSelectedUnit
        ? null
        : selectedUnitId ?? this.selectedUnitId,
    reachable: clearReachable ? null : reachable ?? this.reachable,
    route: clearRoute ? null : route ?? this.route,
    movementPending: movementPending ?? this.movementPending,
    movementError: clearMovementError
        ? null
        : movementError ?? this.movementError,
    lastMovementExecution: lastMovementExecution ?? this.lastMovementExecution,
    actionDeck: clearActionDeck ? null : actionDeck ?? this.actionDeck,
    unitLogistics: clearUnitLogistics
        ? null
        : unitLogistics ?? this.unitLogistics,
    combat: clearCombat ? null : combat ?? this.combat,
    referenceVisible: referenceVisible ?? this.referenceVisible,
  );
}
