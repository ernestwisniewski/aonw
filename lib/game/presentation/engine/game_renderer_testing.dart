part of 'game_renderer.dart';

extension GameRendererTestingHooks on GameRenderer {
  @visibleForTesting
  Future<void> handleTileTappedForTesting(TileData tileData) =>
      _handleTileTapped(tileData);

  @visibleForTesting
  void handleTileInspectedForTesting(TileData tileData) {
    _handleTileInspected(tileData);
  }

  @visibleForTesting
  void handleArtifactMarkerTappedForTesting(WorldArtifact artifact) {
    _handleArtifactMarkerTapped(artifact);
  }

  @visibleForTesting
  void handleMapObjectiveMarkerTappedForTesting(MapObjectiveProgress progress) {
    _handleMapObjectiveMarkerTapped(progress);
  }

  @visibleForTesting
  void handleUnitMarkerTappedForTesting(String unitId) {
    _handleUnitMarkerTapped(unitId);
  }

  @visibleForTesting
  void handleCityMarkerTappedForTesting(GameCity city) {
    _handleCityMarkerTapped(city);
  }

  @visibleForTesting
  void handleTileInspectionPreviewedForTesting(TileData tileData) {
    _suppressTapsUntilNextPointerDown = true;
    _longPressInspectActive = true;
    _longPressInspectionPreviewActive = true;
    _longPressInspectHex = CityHex(col: tileData.col, row: tileData.row);
    _handleTileInspectionPreviewed(tileData);
  }

  @visibleForTesting
  void handleTileLongPressedForTesting(TileData tileData) {
    _selectTileFromLongPress(tileData);
  }

  @visibleForTesting
  void confirmTileInspectionForTesting() {
    _confirmLongPressInspect();
  }

  @visibleForTesting
  void cancelTileInspectionForTesting() {
    _cancelLongPressInspect();
  }

  @visibleForTesting
  void syncHoverIntentForTesting(
    TileData tileData, {
    bool forceInspect = false,
  }) {
    _syncHoverIntentForTile(tileData, forceInspect: forceInspect);
  }

  @visibleForTesting
  bool get imageLayerPrefersFastRenderingForTesting =>
      _sceneBuilder.imageLayer.preferFastRendering;

  @visibleForTesting
  int get markerDensitySyncCountForTesting =>
      _markerDensitySyncStateFor(this).syncCount;

  @visibleForTesting
  double get markerDensityLastSyncedZoomForTesting =>
      _markerDensitySyncStateFor(this).zoom;

  @visibleForTesting
  MapPillComponent? get movePreviewPillForTesting =>
      _actionPaletteLayer.movePreviewPillForTesting;

  @visibleForTesting
  List<GameUnit> get unitsForTesting => _renderState.units;

  @visibleForTesting
  List<GameCity> get citiesForTesting => _renderState.cities;

  @visibleForTesting
  List<FieldImprovement> get fieldImprovementsForTesting =>
      _renderState.fieldImprovements;

  @visibleForTesting
  int get fieldImprovementMarkerCountForTesting =>
      _fieldImprovementMarkerLayer.markerCountForTesting;

  @visibleForTesting
  FieldImprovementType? fieldImprovementMarkerTypeForTesting(
    int col,
    int row,
  ) => _fieldImprovementMarkerLayer.markerTypeForTesting(col, row);

  @visibleForTesting
  int get artifactMarkerCountForTesting =>
      _artifactMarkerLayer.markerCountForTesting;

  @visibleForTesting
  Vector2? artifactMarkerPositionForTesting(String artifactId) =>
      _artifactMarkerLayer.markerPositionForTesting(artifactId);

  @visibleForTesting
  bool artifactMarkerSelectedForTesting(String artifactId) =>
      _artifactMarkerLayer.markerSelectedForTesting(artifactId);

  @visibleForTesting
  int get mapObjectiveMarkerCountForTesting =>
      _mapObjectiveMarkerLayer.markerCountForTesting;

  @visibleForTesting
  int? fieldImprovementMarkerEraColumnForTesting(int col, int row) =>
      _fieldImprovementMarkerLayer.markerEraColumnForTesting(col, row);

  @visibleForTesting
  bool fieldImprovementMarkerSelectedForTesting(int col, int row) =>
      _fieldImprovementMarkerLayer.markerSelectedForTesting(col, row);

  @visibleForTesting
  ({int col, int row})? get selectedGridTileForTesting =>
      _isReady ? _sceneBuilder.grid.selectedTileCoords : null;

  @visibleForTesting
  ({int col, int row})? get movePreviewTargetForTesting {
    final preview = _renderState.movePreview;
    if (preview == null) return null;
    return (col: preview.targetCol, row: preview.targetRow);
  }

  @visibleForTesting
  int? get movePreviewCostForTesting => _renderState.movePreview?.totalCost;

  @visibleForTesting
  bool get moveCommandActiveForTesting => _renderState.moveCommandActive;

  @visibleForTesting
  CityFoundingDraft? get cityFoundingDraftForTesting =>
      _renderState.cityFoundingDraft;

  @visibleForTesting
  FogOfWarState get fogOfWarForTesting => _renderState.fogOfWar;

  @visibleForTesting
  FogVisibilityQuery get activePlayerVisibilityForTesting =>
      _renderState.activePlayerVisibility;

  @visibleForTesting
  HexTileMarkers tileMarkersForTesting(int col, int row) => _isReady
      ? _sceneBuilder.grid.markersForCoordinate(col, row)
      : HexTileMarkers.none;

  @visibleForTesting
  List<CityManagementOverlayHex> get cityManagementOverlayHexesForTesting =>
      _cityManagementOverlayLayer.overlayHexesForTesting;

  @visibleForTesting
  ValueListenable<GameRenderViewModel> get viewModelListenable =>
      _viewModelNotifier;

  ValueListenable<bool> get readyListenable => _readyNotifier;

  ValueListenable<double> get zoomListenable => _zoomNotifier;

  ValueListenable<bool> get initialCameraFocusReadyListenable =>
      _initialCameraFocusReadyNotifier;

  @visibleForTesting
  bool get isDisposedForTesting => _isDisposed;

  @visibleForTesting
  bool isUnitMarkerSelectedForTesting(String unitId) =>
      _unitMarkerLayer.isMarkerSelectedForTesting(unitId);

  @visibleForTesting
  bool isUnitMarkerAttackTargetForTesting(String unitId) =>
      _unitMarkerLayer.isMarkerAttackTargetForTesting(unitId);

  @visibleForTesting
  bool unitMarkerHasAttackTargetTintForTesting(String unitId) =>
      _unitMarkerLayer.markerHasAttackTargetTintForTesting(unitId);

  @visibleForTesting
  UnitSpriteAction? unitMarkerActionForTesting(String unitId) =>
      _unitMarkerLayer.markerActionForTesting(unitId);

  @visibleForTesting
  Vector2? unitMarkerPositionForTesting(String unitId) =>
      _unitMarkerLayer.worldPositionForUnit(unitId);

  @visibleForTesting
  String? unitMarkerWorkBadgeForTesting(String unitId) =>
      _unitMarkerLayer.markerWorkBadgeForTesting(unitId);

  @visibleForTesting
  List<ThreatOverlayHex> get threatOverlayHexesForTesting =>
      _threatOverlayLayer.overlayHexesForTesting;

  @visibleForTesting
  HoverIntentKind? get hoverIntentKindForTesting =>
      _hoverIntentMarkerLayer.kindForTesting;

  @visibleForTesting
  int get combatHexAlertCountForTesting =>
      _combatHexAlertLayer.alertCountForTesting();

  @visibleForTesting
  bool combatHexAlertVisibleForTesting(String id) =>
      _combatHexAlertLayer.hasAlertForTesting(id);

  @visibleForTesting
  ({int col, int row})? get hoverIntentTileForTesting {
    final hex = _hoverIntentMarkerLayer.hexForTesting;
    if (hex == null) return null;
    return (col: hex.col, row: hex.row);
  }

  @visibleForTesting
  int? get hoverIntentColorValueForTesting =>
      _hoverIntentMarkerLayer.colorForTesting?.toARGB32();

  @visibleForTesting
  bool? get hoverIntentBlockedForTesting =>
      _hoverIntentMarkerLayer.blockedForTesting;

  @visibleForTesting
  bool? cityMarkerPaintsLabelForTesting(String cityId) =>
      _cityMarkerLayer.markerPaintsLabelForTesting(cityId);

  @visibleForTesting
  bool get cityTerritoryStrategicViewForTesting =>
      _cityTerritoryOverlayLayer.strategicViewForTesting;

  @visibleForTesting
  double get cityTerritoryZoomEmphasisForTesting =>
      _cityTerritoryOverlayLayer.zoomEmphasisForTesting;

  @visibleForTesting
  bool get reduceMotionForTesting => _reduceMotion;

  @visibleForTesting
  bool get cinematicCameraEnabledForTesting => _cinematicCameraEnabled;

  @visibleForTesting
  bool unitMarkerReduceMotionForTesting(String unitId) =>
      _unitMarkerLayer.markerReduceMotionForTesting(unitId);

  @visibleForTesting
  bool unitMarkerShowsPeripheralDetailsForTesting(String unitId) =>
      _unitMarkerLayer.markerShowPeripheralDetailsForTesting(unitId);

  @visibleForTesting
  bool unitMarkerShowsOwnerColorForTesting(String unitId) =>
      _unitMarkerLayer.markerShowOwnerColorForTesting(unitId);

  @visibleForTesting
  bool unitMarkerShowsHealthBarForTesting(String unitId) =>
      _unitMarkerLayer.markerShowHealthBarForTesting(unitId);

  @visibleForTesting
  bool unitMarkerShowsTypeBadgeForTesting(String unitId) =>
      _unitMarkerLayer.markerShowTypeBadgeForTesting(unitId);

  @visibleForTesting
  bool unitMarkerShowsStateBadgeForTesting(String unitId) =>
      _unitMarkerLayer.markerShowStateBadgeForTesting(unitId);

  @visibleForTesting
  double? unitMarkerWorldScaleForTesting(String unitId) =>
      _unitMarkerLayer.markerWorldScaleForTesting(unitId);

  @visibleForTesting
  double? unitMarkerSpriteScaleForTesting(String unitId) =>
      _unitMarkerLayer.markerSpriteScaleForTesting(unitId);

  @visibleForTesting
  double? unitMarkerTacticalViewEmphasisForTesting(String unitId) =>
      _unitMarkerLayer.markerTacticalViewEmphasisForTesting(unitId);

  @visibleForTesting
  bool unitMarkerAnimatesSpriteForTesting(String unitId) =>
      _unitMarkerLayer.markerAnimatesSpriteForTesting(unitId);

  @visibleForTesting
  bool unitMarkerAnimateIdleForTesting(String unitId) =>
      _unitMarkerLayer.markerAnimateIdleForTesting(unitId);

  @visibleForTesting
  double get unitMarkerDetailsMinZoomForTesting =>
      _currentMarkerDensity.unitDetailsMinZoom;

  @visibleForTesting
  bool get compactMarkerDensityForTesting =>
      _currentMarkerDensity.compactPortrait;

  @visibleForTesting
  bool cityMarkerReduceMotionForTesting(String cityId) =>
      _cityMarkerLayer.markerReduceMotionForTesting(cityId);

  @visibleForTesting
  double? cityMarkerWorldScaleForTesting(String cityId) =>
      _cityMarkerLayer.markerWorldScaleForTesting(cityId);

  @visibleForTesting
  int get cityProductionParticleEmitterCountForTesting =>
      _cityProductionParticleLayer.emitterCountForTesting;

  @visibleForTesting
  bool cityProductionParticleEmitterReduceMotionForTesting(String cityId) =>
      _cityProductionParticleLayer.emitterReduceMotionForTesting(cityId);

  @visibleForTesting
  bool get actionPaletteVisibleForTesting =>
      _actionPaletteLayer.visibleForTesting;

  @visibleForTesting
  ActionPaletteComponent? get actionPaletteComponentForTesting =>
      _actionPaletteLayer.componentForTesting;

  @visibleForTesting
  Vector2? get actionPalettePositionForTesting =>
      _actionPaletteLayer.positionForTesting;
}
