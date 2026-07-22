/// Selects which fog-of-war constraints movement command resolution applies.
enum MovementCommandVisibilityMode {
  /// Applies both the terrain-knowledge horizon and dynamic-unit visibility.
  authoritative,

  /// Ignores terrain knowledge while retaining hidden dynamic information.
  ///
  /// This is intended for auto-exploration, whose planner selects an unknown
  /// destination without revealing blockers that the player cannot see.
  unrestrictedPathing,

  /// Resolves movement with neither terrain nor dynamic fog restrictions.
  unrestricted;

  bool get ignoresPathingFog => this != authoritative;

  bool get ignoresDynamicFog => this == unrestricted;
}
