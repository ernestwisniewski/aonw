import 'dart:ui';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/board_asset_cap.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_sprite_catalog.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/tile/hex_icon_cache.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CityMarker', () {
    test('uses the city sprite without a duplicated type icon badge', () async {
      await HexIconCache.load(CitySpriteCatalog.assetPath);
      const capStyle = BoardAssetCapStyles.city;

      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
      );

      expect(marker.markerSizeForTesting.x, capStyle.componentSize.width);
      expect(
        marker.markerSizeForTesting.y,
        closeTo(capStyle.componentSize.height, 0.0001),
      );
      expect(marker.anchor, Anchor.center);
      expect(marker.sourceInsetForTesting, 0);
      expect(marker.boardCapStyleForTesting, capStyle);
      expect(marker.usesTypeIconBadgeForTesting, isFalse);
      expect(marker.typeIconRectForTesting, Rect.zero);
      expect(marker.paintsCityHealthBarForTesting, isTrue);
      expect(marker.paintsCityOwnerIndicatorForTesting, isFalse);
    });

    test('paints a unit-style health bar above the city sprite', () {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        healthFraction: 0.5,
        name: 'Aurelian',
      );

      final healthRect = marker.cityHealthBarRectForTesting;
      final labelRect = marker.cityLabelHitRectForTesting;

      expect(marker.healthFractionForTesting, 0.5);
      expect(marker.showHealthBarForTesting, isTrue);
      expect(marker.paintsCityHealthBarForTesting, isTrue);
      expect(healthRect, isNot(Rect.zero));
      expect(healthRect.width, greaterThan(30));
      expect(healthRect.bottom, lessThanOrEqualTo(marker.statusTopForTesting));
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

        expect(marker.showHealthBarForTesting, isFalse);
        expect(marker.paintsCityHealthBarForTesting, isFalse);

        marker.healthFraction = 0.75;

        expect(marker.paintsCityHealthBarForTesting, isTrue);

        marker.healthFraction = 1;

        expect(marker.paintsCityHealthBarForTesting, isFalse);

        marker.selected = true;

        expect(marker.paintsCityHealthBarForTesting, isTrue);
      },
    );

    test('does not paint a selection ring for selected cities', () {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        selected: true,
      );

      expect(marker.hasSelectionTintForTesting, isFalse);
      expect(marker.hasSelectionRingForTesting, isFalse);
      expect(marker.selectionRingStrokeWidthForTesting, 0);
      expect(marker.selectionRingRectForTesting, Rect.zero);

      marker.selected = false;

      expect(marker.hasSelectionTintForTesting, isFalse);
      expect(marker.hasSelectionRingForTesting, isFalse);
    });

    test('styles city sprites as large 3d board caps', () {
      final marker = CityMarker(position: Vector2.zero(), colorValue: 0);
      const capStyle = BoardAssetCapStyles.city;

      expect(marker.boardCapStyleForTesting.topSize, capStyle.topSize);
      expect(marker.boardCapStyleForTesting.sideDepth, greaterThan(0));
      expect(marker.boardCapStyleForTesting.rimWidth, greaterThan(0));
    });

    test('lightens the city board cap rim while selected', () {
      final marker = CityMarker(position: Vector2.zero(), colorValue: 0);
      const capStyle = BoardAssetCapStyles.city;

      expect(marker.rimColorForTesting, capStyle.rimColor);
      expect(marker.rimShadowColorForTesting, capStyle.rimShadowColor);

      marker.selected = true;

      expect(
        marker.rimColorForTesting.computeLuminance(),
        greaterThan(capStyle.rimColor.computeLuminance()),
      );
      expect(
        marker.rimShadowColorForTesting.computeLuminance(),
        greaterThan(capStyle.rimShadowColor.computeLuminance()),
      );
    });

    test('fits the city board cap on the projected map hex', () {
      final marker = CityMarker(position: Vector2.zero(), colorValue: 0);
      final spriteBounds = marker.spriteBoundsForTesting;
      const capStyle = BoardAssetCapStyles.city;

      expect(spriteBounds.width, capStyle.topSize.width);
      expect(spriteBounds.height, closeTo(capStyle.topSize.height, 0.0001));
      expect(
        spriteBounds.center.dy,
        closeTo(
          marker.markerSizeForTesting.y / 2 - capStyle.sideDepth / 2,
          0.0001,
        ),
      );
      final clipPath = marker.spriteClipPathForTesting;
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

      expect(marker.hasAmbientFloatForTesting, isFalse);
      expect(marker.restingPositionForTesting.x, 12);
      expect(marker.restingPositionForTesting.y, 34);

      marker.reduceMotion = true;

      expect(marker.hasAmbientFloatForTesting, isFalse);
      expect(marker.position.x, 12);
      expect(marker.position.y, 34);

      marker.reduceMotion = false;

      expect(marker.hasAmbientFloatForTesting, isFalse);
      marker.setWorldPosition(Vector2(18, 42));

      expect(marker.position.x, 18);
      expect(marker.position.y, 42);
      expect(marker.restingPositionForTesting.x, 18);
      expect(marker.restingPositionForTesting.y, 42);
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

    test('accepts taps on the city name label above the asset', () async {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        name: 'Aurelian',
      );
      await marker.onLoad();
      final labelRect = marker.cityLabelHitRectForTesting;

      expect(marker.typeIconRectForTesting, Rect.zero);
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
      final initialPulse = marker.cityLabelPulseForTesting;

      marker.update(0.3);

      expect(marker.cityLabelPulseForTesting, isNot(initialPulse));
      expect(marker.paintsSelectedCityLabelBorderForTesting, isTrue);

      marker.selected = false;

      expect(marker.cityLabelPulseForTesting, 0);
      expect(marker.paintsSelectedCityLabelBorderForTesting, isFalse);
    });

    test('keeps selected city cues static with reduce motion', () {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        selected: true,
        reduceMotion: true,
      );
      final frame = marker.frameIndexForTesting;

      expect(marker.cityLabelPulseForTesting, 0);
      expect(marker.paintsSelectedCityLabelBorderForTesting, isTrue);
      expect(marker.hasSelectionTintForTesting, isFalse);
      expect(marker.hasSelectionRingForTesting, isFalse);
      expect(marker.hasAmbientFloatForTesting, isFalse);

      marker.update(1.2);

      expect(marker.cityLabelPulseForTesting, 0);
      expect(marker.frameIndexForTesting, frame);

      marker.reduceMotion = false;

      expect(marker.hasSelectionTintForTesting, isFalse);
      expect(marker.hasSelectionRingForTesting, isFalse);
      expect(marker.hasAmbientFloatForTesting, isFalse);
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

    test('keeps city atlas variant static on one marker position', () async {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        technologyProfile: CitySpriteTechnologyProfile.industryModern,
      );
      await marker.onLoad();
      final originalPosition = marker.position.clone();
      final rawSpriteTop = marker.spriteBoundsForTesting.top;

      expect(
        marker.frameIndexForTesting,
        CitySpriteTechnologyProfile.industryModern.index,
      );

      marker.update(1.02);

      expect(marker.position, originalPosition);
      expect(
        marker.frameIndexForTesting,
        CitySpriteTechnologyProfile.industryModern.index,
      );
      expect(marker.statusTopForTesting, closeTo(rawSpriteTop, 0.0001));
    });

    test('does not use asset editor offsets for city atlas variants', () async {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        technologyProfile: CitySpriteTechnologyProfile.militaryFortified,
      );
      await marker.onLoad();

      final spriteTop = marker.spriteBoundsForTesting.top;
      marker.update(1.01);

      expect(marker.statusTopForTesting, closeTo(spriteTop, 0.0001));
      expect(
        marker.frameIndexForTesting,
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

    test('city label does not reserve an owner color dot', () {
      final marker = CityMarker(
        position: Vector2.zero(),
        colorValue: 0xFF3366FF,
        name: 'Aurelian',
      );

      expect(marker.labelOwnerDotRadiusForTesting, 0);
      expect(marker.labelOwnerDotGapForTesting, 0);
      expect(marker.paintsCityLabelOwnerDotForTesting, isFalse);

      marker.showLabel = false;

      expect(marker.paintsCityLabelOwnerDotForTesting, isFalse);
    });

    test('propagates city health bar density to existing markers', () {
      final layer = CityMarkerLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );

      layer.sync(parent: parent, cities: [city], selectedCityId: null);

      expect(layer.markerShowHealthBarForTesting(city.id), isTrue);
      expect(layer.markerPaintsHealthBarForTesting(city.id), isTrue);

      layer.showHealthBar = false;

      expect(layer.markerShowHealthBarForTesting(city.id), isFalse);
      expect(layer.markerPaintsHealthBarForTesting(city.id), isFalse);

      layer.sync(
        parent: parent,
        cities: [city.copyWithHitPoints(12)],
        selectedCityId: null,
        healthFractions: const {'city_1': 0.75},
      );

      expect(layer.markerShowHealthBarForTesting(city.id), isFalse);
      expect(layer.markerPaintsHealthBarForTesting(city.id), isTrue);
    });

    test('marks the first city per founding owner as capital', () {
      final layer = CityMarkerLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      const playerCapital = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        foundingOwnerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      );
      const playerSecond = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_1',
        foundingOwnerPlayerId: 'player_1',
        name: 'Second',
        center: CityHex(col: 1, row: 0),
      );
      final capturedRivalCapital = const GameCity(
        id: 'city_3',
        ownerPlayerId: 'player_2',
        name: 'Rival',
        center: CityHex(col: 2, row: 0),
      ).copyWith(ownerPlayerId: 'player_1');

      layer.sync(
        parent: parent,
        cities: [playerCapital, playerSecond, capturedRivalCapital],
        selectedCityId: null,
      );

      expect(layer.markerIsCapitalForTesting(playerCapital.id), isTrue);
      expect(layer.markerPaintsCapitalStarForTesting(playerCapital.id), isTrue);
      expect(layer.markerIsCapitalForTesting(playerSecond.id), isFalse);
      expect(layer.markerPaintsCapitalStarForTesting(playerSecond.id), isFalse);
      expect(layer.markerIsCapitalForTesting(capturedRivalCapital.id), isTrue);
      expect(
        layer.markerPaintsCapitalStarForTesting(capturedRivalCapital.id),
        isTrue,
      );
    });
  });
}
