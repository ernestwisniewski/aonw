enum MapTapTarget { unit, artifact, objective, tileInspection, hex }

final class MapTapCycle {
  String? _cycleId;
  MapTapTarget _lastTarget = MapTapTarget.hex;

  MapTapTarget nextTarget(String cycleId) {
    if (_cycleId != cycleId) {
      _cycleId = cycleId;
      _lastTarget = MapTapTarget.artifact;
      return _lastTarget;
    }

    _lastTarget = _lastTarget == MapTapTarget.artifact
        ? MapTapTarget.hex
        : MapTapTarget.artifact;
    return _lastTarget;
  }

  MapTapTarget nextOccupiedTarget(
    String cycleId, {
    required bool unitAlreadySelected,
  }) {
    if (_cycleId != cycleId) {
      _cycleId = cycleId;
      _lastTarget = unitAlreadySelected
          ? MapTapTarget.artifact
          : MapTapTarget.unit;
      return _lastTarget;
    }

    _lastTarget = switch (_lastTarget) {
      MapTapTarget.unit => MapTapTarget.artifact,
      MapTapTarget.artifact => MapTapTarget.hex,
      MapTapTarget.objective => MapTapTarget.hex,
      MapTapTarget.tileInspection => MapTapTarget.hex,
      MapTapTarget.hex => MapTapTarget.unit,
    };
    return _lastTarget;
  }

  MapTapTarget nextStackTarget(
    String cycleId, {
    required List<MapTapTarget> targets,
    required MapTapTarget preferredFirstTarget,
  }) {
    assert(targets.isNotEmpty, 'targets must not be empty');
    final firstTarget = targets.contains(preferredFirstTarget)
        ? preferredFirstTarget
        : targets.first;
    if (_cycleId != cycleId) {
      _cycleId = cycleId;
      _lastTarget = firstTarget;
      return _lastTarget;
    }

    final currentIndex = targets.indexOf(_lastTarget);
    final nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + 1) % targets.length;
    _lastTarget = targets[nextIndex];
    return _lastTarget;
  }

  void clear() {
    _cycleId = null;
    _lastTarget = MapTapTarget.hex;
  }
}
