part of 'city_marker.dart';

extension CityMarkerMutableState on CityMarker {
  int get colorValue => _colorValue;

  set colorValue(int value) {
    if (_colorValue == value) return;
    _colorValue = value;
  }

  bool get reduceMotion => _reduceMotion;

  double get markerWorldScale => _markerWorldScale;

  set markerWorldScale(double value) {
    final next = _normalizeMarkerWorldScale(value);
    if (_markerWorldScale == next) return;
    _markerWorldScale = next;
    scale = Vector2.all(next);
  }

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    _labelPulseElapsed = 0;
    _syncSelectionEffects();
  }

  void setWorldPosition(Vector2 value) {
    if (_samePosition(_restingPosition, value)) return;
    _restingPosition = value.clone();
    position = _restingPosition.clone();
  }

  String get name => _name;

  set name(String value) {
    if (_name == value) return;
    _name = value;
    _cachedNamePainter = null;
  }

  int get population => _population;

  set population(int value) {
    final next = math.max(1, value);
    if (_population == next) return;
    _population = next;
    _cachedPopulationPainter = null;
    // Population width affects nameMaxWidth, so the name layout has to be
    // recomputed when population digits change (1 → 10, 99 → 100, …).
    _cachedNamePainter = null;
  }

  bool get showLabel => _showLabel;

  set showLabel(bool value) {
    if (_showLabel == value) return;
    _showLabel = value;
  }

  bool get showHealthBar => _showHealthBar;

  set showHealthBar(bool value) {
    if (_showHealthBar == value) return;
    _showHealthBar = value;
  }

  bool get isCapital => _isCapital;

  set isCapital(bool value) {
    if (_isCapital == value) return;
    _isCapital = value;
    // Capital star reserves horizontal space, shrinking the name's max width.
    _cachedNamePainter = null;
  }

  double get healthFraction => _healthFraction;

  set healthFraction(double value) {
    final next = value.clamp(0.0, 1.0).toDouble();
    if (_healthFraction == next) return;
    _healthFraction = next;
  }

  bool get hasStoredArtifact => _hasStoredArtifact;

  set hasStoredArtifact(bool value) {
    if (_hasStoredArtifact == value) return;
    _hasStoredArtifact = value;
  }

  bool get selected => _selected;

  set selected(bool value) {
    if (_selected == value) return;
    _selected = value;
    _labelPulseElapsed = 0;
    _syncSelectionEffects();
  }
}
