import 'package:aonw/game/presentation/engine/rendering_layers/map/marker_density_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarkerDensityPolicy', () {
    const policy = MarkerDensityPolicy();

    double expectedMarkerCenterEmphasis(double zoom) {
      const range =
          MarkerDensityPolicy.unitMarkerCenterBaseZoom -
          MarkerDensityPolicy.unitMarkerCenterFullZoom;
      return ((MarkerDensityPolicy.unitMarkerCenterBaseZoom - zoom) / range)
          .clamp(0.0, 1.0)
          .toDouble();
    }

    test('keeps regular landscape thresholds for desktop-like viewports', () {
      final density = policy.resolve(
        zoom: 0.72,
        viewportWidth: 2592,
        viewportHeight: 1438,
      );

      expect(density.compactPortrait, isFalse);
      expect(density.unitDetailsMinZoom, 0.72);
      expect(density.showCityLabels, isTrue);
      expect(density.showUnitPeripheralDetails, isTrue);
      expect(density.ownerColorMinZoom, 0.45);
      expect(density.healthBarMinZoom, 0.0);
      expect(density.typeBadgeMinZoom, 0.0);
      expect(density.stateBadgeMinZoom, 0.65);
      expect(density.yieldBadgesMinZoom, 0.75);
      expect(density.costLabelMinZoom, 0.50);
      expect(density.floatingTextMinZoom, 0.45);
      expect(density.productionParticlesMinZoom, 0.55);
      expect(density.showOwnerColor, isTrue);
      expect(density.showHealthBar, isTrue);
      expect(density.showTypeBadge, isTrue);
      expect(density.showStateBadge, isTrue);
      expect(density.showYieldBadges, isFalse);
      expect(density.showCostLabel, isTrue);
      expect(density.showFloatingText, isTrue);
      expect(density.showProductionParticles, isTrue);
      expect(density.markerWorldScale, 1.0);
      expect(density.unitSpriteScale, MarkerDensityPolicy.unitSpriteMinScale);
      expect(
        density.unitTacticalEmphasis,
        closeTo(expectedMarkerCenterEmphasis(0.72), 0.0001),
      );
      expect(density.animateUnitIdle, isFalse);
      expect(density.territoryOverlayEmphasis, lessThan(0.4));
    });

    test('uses stricter marker thresholds for compact portrait screens', () {
      final density = policy.resolve(
        zoom: 0.72,
        viewportWidth: 678,
        viewportHeight: 1442,
      );

      expect(density.compactPortrait, isTrue);
      expect(density.unitDetailsMinZoom, 0.82);
      expect(density.showCityLabels, isTrue);
      expect(density.showUnitPeripheralDetails, isFalse);
      expect(density.ownerColorMinZoom, 0.55);
      expect(density.healthBarMinZoom, 0.0);
      expect(density.typeBadgeMinZoom, 0.0);
      expect(density.stateBadgeMinZoom, 0.75);
      expect(density.yieldBadgesMinZoom, 0.85);
      expect(density.costLabelMinZoom, 0.60);
      expect(density.floatingTextMinZoom, 0.55);
      expect(density.productionParticlesMinZoom, 0.65);
      expect(density.showOwnerColor, isTrue);
      expect(density.showHealthBar, isTrue);
      expect(density.showTypeBadge, isTrue);
      expect(density.showStateBadge, isFalse);
      expect(density.showYieldBadges, isFalse);
      expect(density.showCostLabel, isTrue);
      expect(density.showFloatingText, isTrue);
      expect(density.showProductionParticles, isTrue);
      expect(density.markerWorldScale, 1.0);
    });

    test('keeps tablet portrait out of compact portrait density', () {
      final density = policy.resolve(
        zoom: 0.72,
        viewportWidth: 840,
        viewportHeight: 1436,
      );

      expect(density.compactPortrait, isFalse);
      expect(density.unitDetailsMinZoom, 0.72);
      expect(density.showUnitPeripheralDetails, isTrue);
    });

    test('keeps city labels visible and switches unit details at boundary', () {
      final veryFar = policy.resolve(
        zoom: 0.1,
        viewportWidth: 678,
        viewportHeight: 1442,
      );
      final belowUnit = policy.resolve(
        zoom: 0.819,
        viewportWidth: 678,
        viewportHeight: 1442,
      );
      final atUnit = policy.resolve(
        zoom: 0.82,
        viewportWidth: 678,
        viewportHeight: 1442,
      );

      expect(veryFar.showCityLabels, isTrue);
      expect(
        veryFar.markerWorldScale,
        MarkerDensityPolicy.markerReadableMaxScale,
      );
      expect(belowUnit.showUnitPeripheralDetails, isFalse);
      expect(belowUnit.markerWorldScale, 1.0);
      expect(atUnit.showUnitPeripheralDetails, isTrue);
      expect(atUnit.markerWorldScale, 1.0);
    });

    test('applies the extended map element thresholds independently', () {
      final far = policy.resolve(
        zoom: 0.52,
        viewportWidth: 2592,
        viewportHeight: 1438,
      );

      expect(far.showOwnerColor, isTrue);
      expect(far.showFloatingText, isTrue);
      expect(far.showCostLabel, isTrue);
      expect(far.showCityLabels, isTrue);
      expect(far.showHealthBar, isTrue);
      expect(far.showTypeBadge, isTrue);
      expect(far.showStateBadge, isFalse);
      expect(far.showYieldBadges, isFalse);
      expect(far.showProductionParticles, isFalse);
      expect(far.markerWorldScale, greaterThan(1.0));
      expect(far.unitSpriteScale, MarkerDensityPolicy.unitSpriteMinScale);
      expect(
        far.unitTacticalEmphasis,
        closeTo(expectedMarkerCenterEmphasis(0.52), 0.0001),
      );
      expect(far.animateUnitIdle, isFalse);
    });

    test(
      'uses regular thresholds and keeps marker bodies readable below very far zoom',
      () {
        final density = policy.resolve(
          zoom: 0.349,
          viewportWidth: 2592,
          viewportHeight: 1438,
        );

        expect(density.showCityLabels, isTrue);
        expect(density.showOwnerColor, isFalse);
        expect(density.showHealthBar, isTrue);
        expect(density.showTypeBadge, isTrue);
        expect(density.showUnitPeripheralDetails, isFalse);
        expect(density.markerWorldScale, greaterThan(1.0));
        expect(
          density.markerWorldScale * 0.349,
          closeTo(MarkerDensityPolicy.markerReadableMinZoom, 0.0001),
        );
        expect(density.unitSpriteScale, MarkerDensityPolicy.unitSpriteMinScale);
        expect(density.unitTacticalEmphasis, 1);
        expect(density.animateUnitIdle, isFalse);
        expect(density.territoryOverlayEmphasis, greaterThan(0.99));
      },
    );

    test('shrinks unit sprites into tactical markers as zoom decreases', () {
      final close = policy.resolve(
        zoom: 1.0,
        viewportWidth: 2592,
        viewportHeight: 1438,
      );
      final mid = policy.resolve(
        zoom: 0.9,
        viewportWidth: 2592,
        viewportHeight: 1438,
      );
      final far = policy.resolve(
        zoom: 0.8,
        viewportWidth: 2592,
        viewportHeight: 1438,
      );

      expect(close.unitSpriteScale, 1);
      expect(close.unitTacticalEmphasis, 0);
      expect(close.animateUnitIdle, isTrue);
      expect(mid.unitSpriteScale, lessThan(close.unitSpriteScale));
      expect(mid.unitTacticalEmphasis, greaterThan(0));
      expect(mid.animateUnitIdle, isTrue);
      expect(far.unitSpriteScale, MarkerDensityPolicy.unitSpriteMinScale);
      expect(
        far.unitTacticalEmphasis,
        closeTo(expectedMarkerCenterEmphasis(0.8), 0.0001),
      );
      expect(far.animateUnitIdle, isFalse);
    });

    test('strengthens territory overlay as the camera zooms out', () {
      final close = policy.resolve(
        zoom: 1.0,
        viewportWidth: 2592,
        viewportHeight: 1438,
      );
      final mid = policy.resolve(
        zoom: 0.65,
        viewportWidth: 2592,
        viewportHeight: 1438,
      );
      final far = policy.resolve(
        zoom: 0.35,
        viewportWidth: 2592,
        viewportHeight: 1438,
      );

      expect(close.territoryOverlayEmphasis, 0);
      expect(
        mid.territoryOverlayEmphasis,
        greaterThan(close.territoryOverlayEmphasis),
      );
      expect(far.territoryOverlayEmphasis, 1);
    });
  });
}
