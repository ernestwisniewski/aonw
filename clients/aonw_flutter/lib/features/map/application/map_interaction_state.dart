import '../read_model/map_view.dart';

final class MapInteractionState {
  const MapInteractionState({
    this.hovered,
    this.selected,
    this.referenceVisible = true,
  });

  final MapHexCoordinate? hovered;
  final MapHexCoordinate? selected;
  final bool referenceVisible;

  MapInteractionState copyWith({
    MapHexCoordinate? hovered,
    bool clearHovered = false,
    MapHexCoordinate? selected,
    bool clearSelected = false,
    bool? referenceVisible,
  }) => MapInteractionState(
    hovered: clearHovered ? null : hovered ?? this.hovered,
    selected: clearSelected ? null : selected ?? this.selected,
    referenceVisible: referenceVisible ?? this.referenceVisible,
  );
}
