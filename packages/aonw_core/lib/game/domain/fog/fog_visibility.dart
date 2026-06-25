enum FogVisibility { hidden, discovered, visible }

extension FogVisibilityX on FogVisibility {
  bool get isKnown => this != FogVisibility.hidden;

  bool get isVisible => this == FogVisibility.visible;
}
