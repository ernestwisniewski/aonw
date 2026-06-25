enum ArtifactMarkerTapTarget { unit, artifact, objective, tileInspection, hex }

final class ArtifactMarkerTapCycle {
  String? _artifactId;
  ArtifactMarkerTapTarget _lastTarget = ArtifactMarkerTapTarget.hex;

  ArtifactMarkerTapTarget nextTarget(String artifactId) {
    if (_artifactId != artifactId) {
      _artifactId = artifactId;
      _lastTarget = ArtifactMarkerTapTarget.artifact;
      return _lastTarget;
    }

    _lastTarget = _lastTarget == ArtifactMarkerTapTarget.artifact
        ? ArtifactMarkerTapTarget.hex
        : ArtifactMarkerTapTarget.artifact;
    return _lastTarget;
  }

  ArtifactMarkerTapTarget nextOccupiedTarget(
    String artifactId, {
    required bool unitAlreadySelected,
  }) {
    if (_artifactId != artifactId) {
      _artifactId = artifactId;
      _lastTarget = unitAlreadySelected
          ? ArtifactMarkerTapTarget.artifact
          : ArtifactMarkerTapTarget.unit;
      return _lastTarget;
    }

    _lastTarget = switch (_lastTarget) {
      ArtifactMarkerTapTarget.unit => ArtifactMarkerTapTarget.artifact,
      ArtifactMarkerTapTarget.artifact => ArtifactMarkerTapTarget.hex,
      ArtifactMarkerTapTarget.objective => ArtifactMarkerTapTarget.hex,
      ArtifactMarkerTapTarget.tileInspection => ArtifactMarkerTapTarget.hex,
      ArtifactMarkerTapTarget.hex => ArtifactMarkerTapTarget.unit,
    };
    return _lastTarget;
  }

  ArtifactMarkerTapTarget nextStackTarget(
    String stackId, {
    required List<ArtifactMarkerTapTarget> targets,
    required ArtifactMarkerTapTarget preferredFirstTarget,
  }) {
    assert(targets.isNotEmpty, 'targets must not be empty');
    final firstTarget = targets.contains(preferredFirstTarget)
        ? preferredFirstTarget
        : targets.first;
    if (_artifactId != stackId) {
      _artifactId = stackId;
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
    _artifactId = null;
    _lastTarget = ArtifactMarkerTapTarget.hex;
  }
}
