class MarkerDensityPolicy {
  static const double compactPortraitMaxWidth = 720.0;
  static const double regularUnitDetailsMinZoom = 0.72;
  static const double compactPortraitUnitDetailsMinZoom = 0.82;

  static const double regularOwnerColorMinZoom = 0.45;
  static const double compactPortraitOwnerColorMinZoom = 0.55;
  static const double regularHealthBarMinZoom = 0.0;
  static const double compactPortraitHealthBarMinZoom = 0.0;
  static const double regularTypeBadgeMinZoom = 0.0;
  static const double compactPortraitTypeBadgeMinZoom = 0.0;
  static const double regularStateBadgeMinZoom = 0.65;
  static const double compactPortraitStateBadgeMinZoom = 0.75;
  static const double regularYieldBadgesMinZoom = 0.75;
  static const double compactPortraitYieldBadgesMinZoom = 0.85;
  static const double regularCostLabelMinZoom = 0.50;
  static const double compactPortraitCostLabelMinZoom = 0.60;
  static const double regularFloatingTextMinZoom = 0.45;
  static const double compactPortraitFloatingTextMinZoom = 0.55;
  static const double regularProductionParticlesMinZoom = 0.55;
  static const double compactPortraitProductionParticlesMinZoom = 0.65;
  static const double markerReadableMinZoom = 0.55;
  static const double markerReadableMaxScale = 2.75;
  static const double unitSpriteScaleBaseZoom = 1.0;
  static const double unitSpriteScaleFullCompactZoom = 0.8;
  static const double unitMarkerCenterBaseZoom = 1.0;
  static const double unitMarkerCenterFullZoom = 0.35;
  static const double unitSpriteMinScale = 0.68;
  static const double unitIdleAnimationMinZoom = 0.85;
  static const double territoryOverlayBaseZoom = 0.95;
  static const double territoryOverlayFullEmphasisZoom = 0.35;

  const MarkerDensityPolicy();

  MarkerDensity resolve({
    required double zoom,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    final compactPortrait =
        viewportWidth <= compactPortraitMaxWidth &&
        viewportHeight > viewportWidth;
    final unitDetailsMinZoom = compactPortrait
        ? compactPortraitUnitDetailsMinZoom
        : regularUnitDetailsMinZoom;
    final ownerColorMinZoom = compactPortrait
        ? compactPortraitOwnerColorMinZoom
        : regularOwnerColorMinZoom;
    final healthBarMinZoom = compactPortrait
        ? compactPortraitHealthBarMinZoom
        : regularHealthBarMinZoom;
    final typeBadgeMinZoom = compactPortrait
        ? compactPortraitTypeBadgeMinZoom
        : regularTypeBadgeMinZoom;
    final stateBadgeMinZoom = compactPortrait
        ? compactPortraitStateBadgeMinZoom
        : regularStateBadgeMinZoom;
    final yieldBadgesMinZoom = compactPortrait
        ? compactPortraitYieldBadgesMinZoom
        : regularYieldBadgesMinZoom;
    final costLabelMinZoom = compactPortrait
        ? compactPortraitCostLabelMinZoom
        : regularCostLabelMinZoom;
    final floatingTextMinZoom = compactPortrait
        ? compactPortraitFloatingTextMinZoom
        : regularFloatingTextMinZoom;
    final productionParticlesMinZoom = compactPortrait
        ? compactPortraitProductionParticlesMinZoom
        : regularProductionParticlesMinZoom;

    return MarkerDensity(
      compactPortrait: compactPortrait,
      unitDetailsMinZoom: unitDetailsMinZoom,
      ownerColorMinZoom: ownerColorMinZoom,
      healthBarMinZoom: healthBarMinZoom,
      typeBadgeMinZoom: typeBadgeMinZoom,
      stateBadgeMinZoom: stateBadgeMinZoom,
      yieldBadgesMinZoom: yieldBadgesMinZoom,
      costLabelMinZoom: costLabelMinZoom,
      floatingTextMinZoom: floatingTextMinZoom,
      productionParticlesMinZoom: productionParticlesMinZoom,
      showCityLabels: true,
      showUnitPeripheralDetails: zoom >= unitDetailsMinZoom,
      showOwnerColor: zoom >= ownerColorMinZoom,
      showHealthBar: zoom >= healthBarMinZoom,
      showTypeBadge: zoom >= typeBadgeMinZoom,
      showStateBadge: zoom >= stateBadgeMinZoom,
      showYieldBadges: zoom >= yieldBadgesMinZoom,
      showCostLabel: zoom >= costLabelMinZoom,
      showFloatingText: zoom >= floatingTextMinZoom,
      showProductionParticles: zoom >= productionParticlesMinZoom,
      markerWorldScale: _markerWorldScaleFor(zoom),
      unitSpriteScale: _unitSpriteScaleFor(zoom),
      unitTacticalEmphasis: _unitTacticalEmphasisFor(zoom),
      animateUnitIdle: zoom >= unitIdleAnimationMinZoom,
      territoryOverlayEmphasis: _territoryOverlayEmphasisFor(zoom),
    );
  }

  double _markerWorldScaleFor(double zoom) {
    if (zoom >= markerReadableMinZoom) return 1.0;
    if (zoom <= 0) return markerReadableMaxScale;
    return (markerReadableMinZoom / zoom)
        .clamp(1.0, markerReadableMaxScale)
        .toDouble();
  }

  double _unitSpriteScaleFor(double zoom) {
    final t = _unitSpriteCompactEmphasisFor(zoom);
    return 1 - (1 - unitSpriteMinScale) * t;
  }

  double _unitSpriteCompactEmphasisFor(double zoom) {
    if (zoom >= unitSpriteScaleBaseZoom) return 0.0;
    if (zoom <= unitSpriteScaleFullCompactZoom) return 1.0;
    const range = unitSpriteScaleBaseZoom - unitSpriteScaleFullCompactZoom;
    return ((unitSpriteScaleBaseZoom - zoom) / range)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _unitTacticalEmphasisFor(double zoom) {
    if (zoom >= unitMarkerCenterBaseZoom) return 0.0;
    if (zoom <= unitMarkerCenterFullZoom) return 1.0;
    const range = unitMarkerCenterBaseZoom - unitMarkerCenterFullZoom;
    return ((unitMarkerCenterBaseZoom - zoom) / range)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _territoryOverlayEmphasisFor(double zoom) {
    if (zoom >= territoryOverlayBaseZoom) return 0.0;
    if (zoom <= territoryOverlayFullEmphasisZoom) return 1.0;
    const range = territoryOverlayBaseZoom - territoryOverlayFullEmphasisZoom;
    return ((territoryOverlayBaseZoom - zoom) / range)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

class MarkerDensity {
  final bool compactPortrait;
  final double unitDetailsMinZoom;
  final double ownerColorMinZoom;
  final double healthBarMinZoom;
  final double typeBadgeMinZoom;
  final double stateBadgeMinZoom;
  final double yieldBadgesMinZoom;
  final double costLabelMinZoom;
  final double floatingTextMinZoom;
  final double productionParticlesMinZoom;
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
  final double markerWorldScale;
  final double unitSpriteScale;
  final double unitTacticalEmphasis;
  final bool animateUnitIdle;
  final double territoryOverlayEmphasis;

  const MarkerDensity({
    required this.compactPortrait,
    required this.unitDetailsMinZoom,
    required this.ownerColorMinZoom,
    required this.healthBarMinZoom,
    required this.typeBadgeMinZoom,
    required this.stateBadgeMinZoom,
    required this.yieldBadgesMinZoom,
    required this.costLabelMinZoom,
    required this.floatingTextMinZoom,
    required this.productionParticlesMinZoom,
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
    required this.markerWorldScale,
    required this.unitSpriteScale,
    required this.unitTacticalEmphasis,
    required this.animateUnitIdle,
    required this.territoryOverlayEmphasis,
  });
}
