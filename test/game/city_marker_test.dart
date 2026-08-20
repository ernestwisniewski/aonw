import 'dart:math' as math;
import 'dart:ui';

import 'package:aonw/game/presentation/engine/rendering_layers/assets/board_asset_cap.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_sprite_catalog.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

part 'city_marker_test_scenarios.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CityMarker', () {
    test('records a loaded city render path deterministically', () async {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF3366CC,
        name: 'Aurelian',
        population: 8,
        healthFraction: 0.5,
        isCapital: true,
        selected: true,
        hasStoredArtifact: true,
      );
      await marker.onLoad();
      final recorder = PictureRecorder();

      marker.render(Canvas(recorder));

      final picture = recorder.endRecording();
      addTearDown(picture.dispose);
      expect(picture.approximateBytesUsed, greaterThan(0));
      expect(marker.debugSnapshot.paintsCityHealthBar, isTrue);
      expect(marker.debugSnapshot.paintsCapitalStar, isTrue);
      expect(marker.debugSnapshot.paintsSelectedCityLabelBorder, isTrue);
      expect(marker.debugSnapshot.paintsStoredArtifactBadge, isTrue);
    });

    test('uses the city sprite without a duplicated type icon badge', () async {
      const capStyle = BoardAssetCapStyles.city;
      final markerWidth = MapConfig.defaultConfig.hexRadius * 2;
      final markerHeight =
          MapConfig.defaultConfig.hexRadius *
          math.sqrt(3) *
          HexGrid.perspectiveY;

      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
      );

      expect(marker.debugSnapshot.markerSize.x, closeTo(markerWidth, 0.0001));
      expect(marker.debugSnapshot.markerSize.y, closeTo(markerHeight, 0.0001));
      expect(marker.anchor, Anchor.center);
      expect(marker.debugSnapshot.sourceInset, 0);
      expect(marker.debugSnapshot.boardCapStyle, capStyle);
      expect(marker.debugSnapshot.usesTypeIconBadge, isFalse);
      expect(marker.debugSnapshot.typeIconRect, Rect.zero);
      expect(marker.debugSnapshot.paintsCityHealthBar, isTrue);
      expect(marker.debugSnapshot.paintsCityOwnerIndicator, isFalse);
    });

    test('paints a unit-style health bar above the city sprite', () {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        healthFraction: 0.5,
        name: 'Aurelian',
      );

      final healthRect = marker.debugSnapshot.cityHealthBarRect;
      final labelRect = marker.debugSnapshot.cityLabelHitRect;

      expect(marker.debugSnapshot.healthFraction, 0.5);
      expect(marker.debugSnapshot.showHealthBar, isTrue);
      expect(marker.debugSnapshot.paintsCityHealthBar, isTrue);
      expect(healthRect, isNot(Rect.zero));
      expect(healthRect.width, greaterThan(30));
      expect(
        healthRect.bottom,
        lessThanOrEqualTo(marker.debugSnapshot.statusTop),
      );
      expect(labelRect.bottom, lessThanOrEqualTo(healthRect.top));
    });

    test(
      'keeps damaged or selected city health visible when density hides it',
      () {
        final marker = CityMarker(
          position: Vector2.zero(),
          colorValue: 0xFF0000FF,
          showHealthBar: false,
        );

        expect(marker.debugSnapshot.showHealthBar, isFalse);
        expect(marker.debugSnapshot.paintsCityHealthBar, isFalse);
        marker.applyVisualState(
          marker.visualState.copyWith(healthFraction: 0.75),
        );
        expect(marker.visualState.healthFraction, 0.75);
        expect(marker.debugSnapshot.paintsCityHealthBar, isTrue);
        marker.applyVisualState(marker.visualState.copyWith(healthFraction: 1));
        expect(marker.visualState.healthFraction, 1);
        expect(marker.debugSnapshot.paintsCityHealthBar, isFalse);
        marker.applyVisualState(marker.visualState.copyWith(selected: true));
        expect(marker.visualState.selected, isTrue);
        expect(marker.debugSnapshot.paintsCityHealthBar, isTrue);
      },
    );

    test('does not paint a selection ring for selected cities', () {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        selected: true,
      );

      expect(marker.debugSnapshot.hasSelectionTint, isFalse);
      expect(marker.debugSnapshot.hasSelectionRing, isFalse);
      expect(marker.debugSnapshot.selectionRingStrokeWidth, 0);
      expect(marker.debugSnapshot.selectionRingRect, Rect.zero);
      marker.applyVisualState(marker.visualState.copyWith(selected: false));
      expect(marker.debugSnapshot.hasSelectionTint, isFalse);
      expect(marker.debugSnapshot.hasSelectionRing, isFalse);
    });

    test('styles city sprites as large 3d board caps', () {
      final marker = CityMarker(position: Vector2.zero(), colorValue: 0);
      const capStyle = BoardAssetCapStyles.city;

      expect(marker.debugSnapshot.boardCapStyle.topSize, capStyle.topSize);
      expect(marker.debugSnapshot.boardCapStyle.sideDepth, greaterThan(0));
      expect(marker.debugSnapshot.boardCapStyle.rimWidth, greaterThan(0));
    });

    test('lightens the city board cap rim while selected', () {
      final marker = CityMarker(position: Vector2.zero(), colorValue: 0);
      const capStyle = BoardAssetCapStyles.city;

      expect(marker.debugSnapshot.rimColor, capStyle.rimColor);
      expect(marker.debugSnapshot.rimShadowColor, capStyle.rimShadowColor);
      marker.applyVisualState(marker.visualState.copyWith(selected: true));
      expect(
        marker.debugSnapshot.rimColor.computeLuminance(),
        greaterThan(capStyle.rimColor.computeLuminance()),
      );
      expect(
        marker.debugSnapshot.rimShadowColor.computeLuminance(),
        greaterThan(capStyle.rimShadowColor.computeLuminance()),
      );
    });

    test('fits the city board cap on the projected map hex', () {
      final marker = CityMarker(position: Vector2.zero(), colorValue: 0);
      final spriteBounds = marker.debugSnapshot.spriteBounds;
      final expectedWidth = MapConfig.defaultConfig.hexRadius * 2;
      final expectedHeight =
          MapConfig.defaultConfig.hexRadius *
          math.sqrt(3) *
          HexGrid.perspectiveY;

      expect(spriteBounds.width, closeTo(expectedWidth, 0.0001));
      expect(spriteBounds.height, closeTo(expectedHeight, 0.0001));
      expect(
        spriteBounds.center.dy,
        closeTo(marker.debugSnapshot.markerSize.y / 2, 0.0001),
      );
      final clipPath = marker.debugSnapshot.spriteClipPath;
      final clipBounds = clipPath.getBounds();
      expect(clipBounds.left, closeTo(spriteBounds.left, 0.0001));
      expect(clipBounds.top, closeTo(spriteBounds.top, 0.0001));
      expect(clipBounds.right, closeTo(spriteBounds.right, 0.0001));
      expect(clipBounds.bottom, closeTo(spriteBounds.bottom, 0.0001));
      expect(clipPath.contains(spriteBounds.center), isTrue);
      expect(
        clipPath.contains(spriteBounds.topLeft + const Offset(1, 1)),
        isFalse,
      );
      expect(
        clipPath.contains(spriteBounds.bottomRight - const Offset(1, 1)),
        isFalse,
      );
    });

    test('keeps city markers stationary without ambient float animation', () {
      final marker = CityMarker(
        position: Vector2(12, 34),
        colorValue: 0xFF0000FF,
      );

      expect(marker.debugSnapshot.hasAmbientFloat, isFalse);
      expect(marker.debugSnapshot.restingPosition.x, 12);
      expect(marker.debugSnapshot.restingPosition.y, 34);

      marker.applyVisualState(marker.visualState.copyWith(reduceMotion: true));

      expect(marker.debugSnapshot.hasAmbientFloat, isFalse);
      expect(marker.position.x, 12);
      expect(marker.position.y, 34);

      marker.applyVisualState(marker.visualState.copyWith(reduceMotion: false));

      expect(marker.debugSnapshot.hasAmbientFloat, isFalse);
      marker.applyVisualState(
        marker.visualState.copyWith(worldPosition: const Offset(18, 42)),
      );

      expect(marker.position.x, 18);
      expect(marker.position.y, 42);
      expect(marker.debugSnapshot.restingPosition.x, 18);
      expect(marker.debugSnapshot.restingPosition.y, 42);
    });

    test('keeps city caps below units in the same row', () {
      final layer = CityMarkerLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );

      layer.sync(parent: parent, cities: [city], selectedCityId: null);

      expect(parent.children.query<CityMarkerLayer>(), hasLength(1));
      expect(parent.children.query<CityMarker>(), hasLength(1));
      expect(layer.markerPriorityForTesting(city.id), lessThan(20));
    });

    test('retains a captured or destroyed city until combat completes', () {
      final layer = CityMarkerLayer(
        colorForPlayer: (playerId) =>
            playerId == 'player_1' ? 0xFF111111 : 0xFF222222,
      );
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );
      layer.sync(parent: parent, cities: const [city], selectedCityId: null);
      expect(layer.markerColorValueForTesting(city.id), 0xFF111111);

      layer
        ..retainPendingAnimationMarkers(const {'city_1'})
        ..sync(parent: parent, cities: const [], selectedCityId: null);
      expect(layer.markerColorValueForTesting(city.id), 0xFF111111);
      layer.sync(
        parent: parent,
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_2',
            name: 'City',
            center: CityHex(col: 0, row: 0),
          ),
        ],
        selectedCityId: null,
      );
      expect(layer.markerColorValueForTesting(city.id), 0xFF111111);

      layer
        ..releasePendingAnimationMarkers(const {'city_1'})
        ..sync(
          parent: parent,
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_2',
              name: 'City',
              center: CityHex(col: 0, row: 0),
            ),
          ],
          selectedCityId: null,
        );
      expect(layer.markerColorValueForTesting(city.id), 0xFF222222);
    });

    test('accepts taps on the city name label above the asset', () async {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        name: 'Aurelian',
      );
      await marker.onLoad();
      final labelRect = marker.debugSnapshot.cityLabelHitRect;

      expect(marker.debugSnapshot.typeIconRect, Rect.zero);
      expect(labelRect.top, lessThan(0));
      expect(
        marker.containsLocalPoint(
          Vector2(labelRect.center.dx, labelRect.center.dy),
        ),
        isTrue,
      );
    });

    test('pulses the city name marker border while selected', () async {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        selected: true,
      );
      await marker.onLoad();
      final initialPulse = marker.debugSnapshot.cityLabelPulse;

      marker.update(0.3);

      expect(marker.debugSnapshot.cityLabelPulse, isNot(initialPulse));
      expect(marker.debugSnapshot.paintsSelectedCityLabelBorder, isTrue);

      marker.applyVisualState(marker.visualState.copyWith(selected: false));

      expect(marker.debugSnapshot.cityLabelPulse, 0);
      expect(marker.debugSnapshot.paintsSelectedCityLabelBorder, isFalse);
    });

    test('keeps selected city cues static with reduce motion', () {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        selected: true,
        reduceMotion: true,
      );
      final frame = marker.debugSnapshot.frameIndex;

      expect(marker.debugSnapshot.cityLabelPulse, 0);
      expect(marker.debugSnapshot.paintsSelectedCityLabelBorder, isTrue);
      expect(marker.debugSnapshot.hasSelectionTint, isFalse);
      expect(marker.debugSnapshot.hasSelectionRing, isFalse);
      expect(marker.debugSnapshot.hasAmbientFloat, isFalse);

      marker.update(1.2);

      expect(marker.debugSnapshot.cityLabelPulse, 0);
      expect(marker.debugSnapshot.frameIndex, frame);

      marker.applyVisualState(marker.visualState.copyWith(reduceMotion: false));

      expect(marker.debugSnapshot.hasSelectionTint, isFalse);
      expect(marker.debugSnapshot.hasSelectionRing, isFalse);
      expect(marker.debugSnapshot.hasAmbientFloat, isFalse);
    });

    test('propagates reduce motion to existing city markers', () {
      final layer = CityMarkerLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );

      layer.sync(parent: parent, cities: [city], selectedCityId: city.id);
      expect(layer.markerReduceMotionForTesting(city.id), isFalse);
      expect(layer.markerHasAmbientFloatForTesting(city.id), isFalse);

      layer.reduceMotion = true;

      expect(layer.markerReduceMotionForTesting(city.id), isTrue);
      expect(layer.markerHasAmbientFloatForTesting(city.id), isFalse);

      layer.reduceMotion = false;

      expect(layer.markerReduceMotionForTesting(city.id), isFalse);
      expect(layer.markerHasAmbientFloatForTesting(city.id), isFalse);
    });

    test('highlights every city marker in the focused empire', () {
      final layer = CityMarkerLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      const focusedCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Focused',
        center: CityHex(col: 0, row: 0),
      );
      const sameEmpireCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        name: 'Same empire',
        center: CityHex(col: 1, row: 0),
      );
      const otherEmpireCity = GameCity(
        id: 'city_3',
        ownerPlayerId: 'player_2',
        name: 'Other empire',
        center: CityHex(col: 2, row: 0),
      );

      layer.sync(
        parent: parent,
        cities: const [focusedCity, sameEmpireCity, otherEmpireCity],
        selectedCityId: focusedCity.id,
        highlightedPlayerId: focusedCity.ownerPlayerId,
      );

      expect(
        layer.markerPaintsSelectedLabelBorderForTesting(focusedCity.id),
        isTrue,
      );
      expect(
        layer.markerPaintsSelectedLabelBorderForTesting(sameEmpireCity.id),
        isTrue,
      );
      expect(
        layer.markerPaintsSelectedLabelBorderForTesting(otherEmpireCity.id),
        isFalse,
      );
    });

    test('keeps city atlas variant static on one marker position', () async {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        technologyProfile: CitySpriteTechnologyProfile.industryModern,
      );
      await marker.onLoad();
      final originalPosition = marker.position.clone();
      final rawSpriteTop = marker.debugSnapshot.spriteBounds.top;

      expect(
        marker.debugSnapshot.frameIndex,
        CitySpriteTechnologyProfile.industryModern.index,
      );

      marker.update(1.02);

      expect(marker.position, originalPosition);
      expect(
        marker.debugSnapshot.frameIndex,
        CitySpriteTechnologyProfile.industryModern.index,
      );
      expect(marker.debugSnapshot.statusTop, closeTo(rawSpriteTop, 0.0001));
    });

    test('does not use asset editor offsets for city atlas variants', () async {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        technologyProfile: CitySpriteTechnologyProfile.militaryFortified,
      );
      await marker.onLoad();

      final spriteTop = marker.debugSnapshot.spriteBounds.top;
      marker.update(1.01);

      expect(marker.debugSnapshot.statusTop, closeTo(spriteTop, 0.0001));
      expect(
        marker.debugSnapshot.frameIndex,
        CitySpriteTechnologyProfile.militaryFortified.index,
      );
    });

    test('selects city atlas row from city maturity', () {
      final layer = CityMarkerLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );

      void sync(GameCity city) {
        layer.sync(parent: parent, cities: [city], selectedCityId: null);
      }

      sync(city);
      expect(layer.markerVisualLevelForTesting(city.id), 0);

      sync(city.copyWith(population: 4));
      expect(layer.markerVisualLevelForTesting(city.id), 1);

      sync(city.copyWith(population: 6));
      expect(layer.markerVisualLevelForTesting(city.id), 2);

      sync(city.copyWith(population: 8));
      expect(layer.markerVisualLevelForTesting(city.id), 3);

      sync(city.copyWith(population: 10));
      expect(layer.markerVisualLevelForTesting(city.id), 4);

      sync(city.copyWith(population: 14));
      expect(layer.markerVisualLevelForTesting(city.id), 5);
    });

    test('updates marker owner color when a city changes owner', () {
      const playerOneColor = 0xFF2244FF;
      const playerTwoColor = 0xFFE24A2A;
      GameCity? tappedCity;
      final layer = CityMarkerLayer(
        colorForPlayer: (playerId) =>
            playerId == 'player_2' ? playerTwoColor : playerOneColor,
        onCityTapped: (city) => tappedCity = city,
      );
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );

      layer.sync(parent: parent, cities: [city], selectedCityId: null);

      expect(layer.markerColorValueForTesting(city.id), playerOneColor);

      final captured = city.copyWith(ownerPlayerId: 'player_2');
      layer.sync(parent: parent, cities: [captured], selectedCityId: null);

      expect(layer.markerColorValueForTesting(city.id), playerTwoColor);
      parent.children.whereType<CityMarker>().single.onTap?.call();
      expect(tappedCity?.ownerPlayerId, 'player_2');
    });

    test('selects city atlas column from owner technology profile', () {
      final layer = CityMarkerLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {
              TechnologyId.mining,
              TechnologyId.metallurgy,
              TechnologyId.steamPower,
            },
          ),
        },
      );

      layer.sync(
        parent: parent,
        cities: [city],
        selectedCityId: null,
        research: research,
      );

      expect(
        layer.markerTechnologyProfileForTesting(city.id),
        CitySpriteTechnologyProfile.industryModern,
      );
    });

    test('anchors city markers to their projected hex top face', () {
      final layer = CityMarkerLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 1),
      );
      final tileCenter = HexGeometry.tilePosition(
        col: city.center.col,
        row: city.center.row,
        hexRadius: MapConfig.defaultConfig.hexRadius,
      );
      final expectedTopFaceY =
          (tileCenter.y +
              HexTileMetrics.topCenterAnchorOffsetY(
                MapConfig.defaultConfig.hexRadius,
              )) *
          HexGrid.perspectiveY;

      layer.sync(parent: parent, cities: [city], selectedCityId: null);

      final position = layer.markerPositionForTesting(city.id)!;
      final restingPosition = layer.markerRestingPositionForTesting(city.id)!;
      expect(position.x, closeTo(tileCenter.x, 0.0001));
      expect(position.y, closeTo(expectedTopFaceY, 0.0001));
      expect(restingPosition.x, closeTo(tileCenter.x, 0.0001));
      expect(restingPosition.y, closeTo(expectedTopFaceY, 0.0001));
    });

    test(
      'syncs persistent city labels with name, population, and visibility',
      () {
        final layer = CityMarkerLayer(colorForPlayer: (_) => 0);
        final parent = Component();
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Aurelian',
          center: CityHex(col: 0, row: 0),
          population: 3,
        );

        layer.sync(parent: parent, cities: [city], selectedCityId: null);

        expect(layer.markerCityNameForTesting(city.id), 'Aurelian');
        expect(layer.markerPopulationForTesting(city.id), 3);
        expect(layer.markerLabelEnabledForTesting(city.id), isTrue);
        expect(layer.markerPaintsLabelForTesting(city.id), isTrue);
        expect(layer.markerPaintsLabelOwnerDotForTesting(city.id), isFalse);

        layer.sync(
          parent: parent,
          cities: [city.copyWith(name: 'Nova', population: 5)],
          selectedCityId: null,
          showLabels: false,
        );

        expect(layer.markerCityNameForTesting(city.id), 'Nova');
        expect(layer.markerPopulationForTesting(city.id), 5);
        expect(layer.markerLabelEnabledForTesting(city.id), isFalse);
        expect(layer.markerPaintsLabelForTesting(city.id), isFalse);
        expect(layer.markerPaintsLabelOwnerDotForTesting(city.id), isFalse);

        layer.sync(
          parent: parent,
          cities: [city.copyWith(name: 'Nova', population: 5)],
          selectedCityId: city.id,
          showLabels: false,
        );

        expect(layer.markerPaintsLabelForTesting(city.id), isTrue);
        expect(layer.markerPaintsLabelOwnerDotForTesting(city.id), isFalse);
      },
    );

    _runCityMarkerOwnershipScenarios();
  });
}
