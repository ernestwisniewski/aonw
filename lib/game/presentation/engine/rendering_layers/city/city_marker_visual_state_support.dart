part of 'city_marker.dart';

extension _CityMarkerVisualStateSupport on CityMarker {
  bool get _selected => _visualState.selected;

  String get _name => _visualState.name;

  int get _population => _visualState.population;

  bool get _showLabel => _visualState.showLabel;

  bool get _showHealthBar => _visualState.showHealthBar;

  bool get _isCapital => _visualState.isCapital;

  int get _visualLevel => _visualState.visualLevel;

  CitySpriteTechnologyProfile get _technologyProfile =>
      _visualState.technologyProfile;

  double get _healthFraction => _visualState.healthFraction;

  bool get _hasStoredArtifact => _visualState.hasStoredArtifact;

  bool get _reduceMotion => _visualState.reduceMotion;

  double get _markerWorldScale => _visualState.markerWorldScale;

  void _applyVisualState(CityMarkerVisualState value) {
    final previous = _visualState;
    final positionChanged = previous.worldPosition != value.worldPosition;
    final scaleChanged = previous.markerWorldScale != value.markerWorldScale;
    final resetSelectionEffects =
        previous.selected != value.selected ||
        previous.reduceMotion != value.reduceMotion;
    final spriteChanged =
        previous.visualLevel != value.visualLevel ||
        previous.technologyProfile != value.technologyProfile;

    if (previous.name != value.name || previous.isCapital != value.isCapital) {
      _cachedNamePainter = null;
    }
    if (previous.population != value.population) {
      _cachedPopulationPainter = null;
      // Population width changes the width available to the city name.
      _cachedNamePainter = null;
    }

    _visualState = value;
    if (positionChanged) {
      position.setValues(value.worldPosition.dx, value.worldPosition.dy);
    }
    if (scaleChanged) {
      scale = Vector2.all(value.markerWorldScale);
    }
    if (resetSelectionEffects) {
      _labelPulseElapsed = 0;
      _syncSelectionEffects();
    }
    if (spriteChanged && isLoaded) unawaited(_loadCityFrame());
  }
}
