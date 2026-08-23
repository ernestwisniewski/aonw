import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';

final class MapInteractionState {
  const MapInteractionState({
    this.hovered,
    this.selected,
    this.selectedUnitId,
    this.reachable,
    this.route,
    this.movementPending = false,
    this.movementError,
    this.referenceVisible = true,
  });

  final MapHexCoordinate? hovered;
  final MapHexCoordinate? selected;
  final String? selectedUnitId;
  final ReachableView? reachable;
  final RoutePlanView? route;
  final bool movementPending;
  final String? movementError;
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
    String? movementError,
    bool clearMovementError = false,
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
    referenceVisible: referenceVisible ?? this.referenceVisible,
  );
}
