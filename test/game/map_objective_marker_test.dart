import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/artifact_marker.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_objective_marker.dart';
import 'package:aonw/map/rendering/map_objective_marker_layer.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapObjectiveMarker', () {
    test('uses status colors for neutral, contested, and completed states', () {
      final neutral = MapObjectiveMarker(
        position: Vector2.zero(),
        type: MapObjectiveType.ruins,
      );
      final contested = MapObjectiveMarker(
        position: Vector2.zero(),
        type: MapObjectiveType.strategicPass,
        contested: true,
      );
      final completed = MapObjectiveMarker(
        position: Vector2.zero(),
        type: MapObjectiveType.holySite,
        controllingPlayerId: 'player_1',
        completed: true,
      );

      expect(neutral.statusColorForTesting, HudPalette.goldLight);
      expect(contested.statusColorForTesting, HudPalette.warning);
      expect(completed.statusColorForTesting, HudPalette.successLight);
      expect(neutral.size.x, 38);
      expect(neutral.size.y, 36);
      expect(neutral.outlineVertexCountForTesting, 3);
    });

    test(
      'keeps objective silhouette triangular and distinct from artifacts',
      () {
        final objective = MapObjectiveMarker(
          position: Vector2.zero(),
          type: MapObjectiveType.holySite,
        );
        final artifact = ArtifactMarker(
          position: Vector2.zero(),
          type: WorldArtifactType.templeReliquary,
        );

        expect(objective.outlineVertexCountForTesting, 3);
        expect(artifact.outlineVertexCountForTesting, 6);
        expect(
          objective.outlineVertexCountForTesting,
          isNot(artifact.outlineVertexCountForTesting),
        );
      },
    );

    test('pulses its glow over time', () {
      final marker = MapObjectiveMarker(
        position: Vector2.zero(),
        type: MapObjectiveType.legendaryResource,
      );
      final initialPulse = marker.glowPulseForTesting;

      marker.update(0.35);

      expect(initialPulse, closeTo(0.5, 0.0001));
      expect(marker.glowPulseForTesting, greaterThan(0.95));
    });

    test('renders objective marker without throwing', () {
      final marker = MapObjectiveMarker(
        position: Vector2.zero(),
        type: MapObjectiveType.legendaryResource,
        controllingPlayerId: 'player_1',
        controlColorValue: HudPalette.info.toARGB32(),
        holdTurns: 2,
        requiredHoldTurns: 3,
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      marker.render(canvas);

      recorder.endRecording().dispose();
    });
  });

  group('MapObjectiveMarkerLayer', () {
    test('creates markers from objective progress', () {
      final layer = MapObjectiveMarkerLayer(
        colorForPlayer: (_) => HudPalette.success.toARGB32(),
      );
      final parent = Component();
      final progress = MapObjectiveProgress(
        definition: _objective(),
        controllingPlayerId: 'player_1',
        holdTurns: 2,
      );

      layer.sync(parent: parent, objectives: [progress]);

      expect(layer.markerCountForTesting, 1);
      expect(parent.children.query<MapObjectiveMarkerLayer>(), hasLength(1));
      expect(parent.children.query<MapObjectiveMarker>(), hasLength(1));
      expect(
        layer.markerTypeForTesting('pass_1'),
        MapObjectiveType.strategicPass,
      );
      expect(layer.markerControllingPlayerForTesting('pass_1'), 'player_1');
      expect(layer.markerCompletedForTesting('pass_1'), isTrue);
      expect(layer.markerHoldTurnsForTesting('pass_1'), 2);
    });

    test('anchors markers to the projected hex top face', () {
      final layer = MapObjectiveMarkerLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      final progress = MapObjectiveProgress(
        definition: _objective(),
        controllingPlayerId: null,
        holdTurns: 0,
      );
      final tileCenter = HexGeometry.tilePosition(
        col: 2,
        row: 1,
        hexRadius: MapConfig.defaultConfig.hexRadius,
      );
      final expectedTopFaceY =
          (tileCenter.y +
                  HexTileMetrics.topCenterAnchorOffsetY(
                    MapConfig.defaultConfig.hexRadius,
                  )) *
              HexGrid.perspectiveY -
          31;

      layer.sync(parent: parent, objectives: [progress]);

      final position = layer.markerPositionForTesting('pass_1')!;
      expect(position.x, closeTo(tileCenter.x, 0.0001));
      expect(position.y, closeTo(expectedTopFaceY, 0.0001));
      expect(
        layer.markerPriorityForTesting('pass_1'),
        MapPriority.perTile(MapPriority.mapObjective, col: 2, row: 1),
      );
    });

    test('updates marker scale for density changes', () {
      final layer = MapObjectiveMarkerLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      final progress = MapObjectiveProgress(
        definition: _objective(),
        controllingPlayerId: null,
        holdTurns: 0,
      );

      layer
        ..sync(parent: parent, objectives: [progress])
        ..markerWorldScale = 2;

      expect(layer.markerWorldScaleForTesting('pass_1'), 2);
    });
  });
}

MapObjectiveDefinition _objective() {
  return const MapObjectiveDefinition(
    id: 'pass_1',
    type: MapObjectiveType.strategicPass,
    hex: CityHex(col: 2, row: 1),
    requiredHoldTurns: 2,
  );
}
