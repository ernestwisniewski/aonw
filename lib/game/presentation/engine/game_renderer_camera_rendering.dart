part of 'game_renderer.dart';

final Expando<_MarkerDensitySyncState> _markerDensitySyncStates =
    Expando<_MarkerDensitySyncState>('GameRenderer.markerDensitySyncState');

extension GameRendererCameraRendering on GameRenderer {
  static const double _fastRenderHoldSeconds = 0.12;
  static const double _markerDensityZoomEpsilon = 0.025;

  void _syncFastCameraRendering(double dt) {
    if (!_isReady || _isDisposed) return;

    final position = camera.viewfinder.position;
    final zoom = camera.viewfinder.zoom;
    final lastPosition = _lastCameraPositionForFastRender;
    final lastZoom = _lastCameraZoomForFastRender;
    final cameraMoved =
        lastPosition == null ||
        (position - lastPosition).length > 0.001 ||
        lastZoom == null ||
        (zoom - lastZoom).abs() > 0.0001;

    _lastCameraPositionForFastRender = position.clone();
    _lastCameraZoomForFastRender = zoom;

    if (cameraMoved) {
      _cameraFastRenderHoldRemaining = _fastRenderHoldSeconds;
    } else if (_cameraFastRenderHoldRemaining > 0) {
      final remaining = _cameraFastRenderHoldRemaining - dt;
      _cameraFastRenderHoldRemaining = remaining <= 0 ? 0 : remaining;
    }

    _setFastCameraRendering(_cameraFastRenderHoldRemaining > 0);
  }

  void _setFastCameraRendering(bool value) {
    if (_cameraFastRendering == value) {
      if (_isReady && !_isDisposed) {
        _sceneBuilder.imageLayer.preferFastRendering = value;
      }
      return;
    }
    _cameraFastRendering = value;
    if (_isReady && !_isDisposed) {
      _sceneBuilder.imageLayer.preferFastRendering = value;
    }
  }

  MarkerDensity? _markerDensityForZoomSync({required bool force}) {
    final density = _currentMarkerDensity;
    final state = _markerDensitySyncStateFor(this);
    final key = _MarkerDensitySyncKey.from(density);
    final zoom = camera.viewfinder.zoom;
    final shouldSync =
        force ||
        state.key != key ||
        (zoom - state.zoom).abs() >= _markerDensityZoomEpsilon;
    if (!shouldSync) return null;

    state
      ..key = key
      ..zoom = zoom;
    state.syncCount++;
    return density;
  }
}

_MarkerDensitySyncState _markerDensitySyncStateFor(GameRenderer renderer) {
  return _markerDensitySyncStates[renderer] ??= _MarkerDensitySyncState();
}

class _MarkerDensitySyncState {
  _MarkerDensitySyncKey? key;
  double zoom = double.nan;
  int syncCount = 0;
}

class _MarkerDensitySyncKey {
  final bool compactPortrait;
  final bool showCityLabels;
  final bool showUnitPeripheralDetails;
  final bool showOwnerColor;
  final bool showHealthBar;
  final bool showTypeBadge;
  final bool showStateBadge;
  final bool showYieldBadges;
  final bool showCostLabel;
  final bool showFloatingText;
  final bool showProductionParticles;
  final bool animateUnitIdle;

  const _MarkerDensitySyncKey({
    required this.compactPortrait,
    required this.showCityLabels,
    required this.showUnitPeripheralDetails,
    required this.showOwnerColor,
    required this.showHealthBar,
    required this.showTypeBadge,
    required this.showStateBadge,
    required this.showYieldBadges,
    required this.showCostLabel,
    required this.showFloatingText,
    required this.showProductionParticles,
    required this.animateUnitIdle,
  });

  factory _MarkerDensitySyncKey.from(MarkerDensity density) {
    return _MarkerDensitySyncKey(
      compactPortrait: density.compactPortrait,
      showCityLabels: density.showCityLabels,
      showUnitPeripheralDetails: density.showUnitPeripheralDetails,
      showOwnerColor: density.showOwnerColor,
      showHealthBar: density.showHealthBar,
      showTypeBadge: density.showTypeBadge,
      showStateBadge: density.showStateBadge,
      showYieldBadges: density.showYieldBadges,
      showCostLabel: density.showCostLabel,
      showFloatingText: density.showFloatingText,
      showProductionParticles: density.showProductionParticles,
      animateUnitIdle: density.animateUnitIdle,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _MarkerDensitySyncKey &&
        other.compactPortrait == compactPortrait &&
        other.showCityLabels == showCityLabels &&
        other.showUnitPeripheralDetails == showUnitPeripheralDetails &&
        other.showOwnerColor == showOwnerColor &&
        other.showHealthBar == showHealthBar &&
        other.showTypeBadge == showTypeBadge &&
        other.showStateBadge == showStateBadge &&
        other.showYieldBadges == showYieldBadges &&
        other.showCostLabel == showCostLabel &&
        other.showFloatingText == showFloatingText &&
        other.showProductionParticles == showProductionParticles &&
        other.animateUnitIdle == animateUnitIdle;
  }

  @override
  int get hashCode => Object.hash(
    compactPortrait,
    showCityLabels,
    showUnitPeripheralDetails,
    showOwnerColor,
    showHealthBar,
    showTypeBadge,
    showStateBadge,
    showYieldBadges,
    showCostLabel,
    showFloatingText,
    showProductionParticles,
    animateUnitIdle,
  );
}
