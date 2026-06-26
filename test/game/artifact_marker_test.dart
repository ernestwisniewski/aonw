import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/artifacts/artifact_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/artifacts/artifact_marker_layer.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArtifactMarker', () {
    test('uses a compact golden marker with distinct artifact accents', () {
      final crown = ArtifactMarker(
        position: Vector2.zero(),
        type: WorldArtifactType.ancientImperialCrown,
      );
      final tablets = ArtifactMarker(
        position: Vector2.zero(),
        type: WorldArtifactType.astronomersTablets,
      );

      expect(crown.typeColorForTesting, isNot(tablets.typeColorForTesting));
      expect(crown.size.x, 34);
      expect(crown.size.y, 36);
      expect(crown.rimColorForTesting, HudPalette.gold);

      crown.selected = true;

      expect(crown.rimColorForTesting, HudPalette.goldLight);
    });

    test('pulses its glow over time', () {
      final marker = ArtifactMarker(
        position: Vector2.zero(),
        type: WorldArtifactType.templeReliquary,
      );
      final initialPulse = marker.glowPulseForTesting;

      marker.update(0.3125);

      expect(initialPulse, closeTo(0.5, 0.0001));
      expect(marker.glowPulseForTesting, greaterThan(0.95));
    });

    test('renders gradient marker without throwing', () {
      final marker = ArtifactMarker(
        position: Vector2.zero(),
        type: WorldArtifactType.queensMirror,
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      marker.render(canvas);

      recorder.endRecording().dispose();
    });
  });

  group('ArtifactMarkerLayer', () {
    test('renders only artifacts that occupy a map hex', () {
      final layer = ArtifactMarkerLayer();
      final parent = Component();
      final crown = WorldArtifact.placed(
        type: WorldArtifactType.ancientImperialCrown,
        col: 2,
        row: 1,
      );
      final sword = WorldArtifact(
        id: WorldArtifact.idForType(WorldArtifactType.heroSword),
        type: WorldArtifactType.heroSword,
        location: const WorldArtifactLocation.carried(unitId: 'unit_1'),
      );

      layer.sync(
        parent: parent,
        artifacts: [crown, sword],
        selectedHex: const CityHex(col: 2, row: 1),
      );

      expect(layer.markerCountForTesting, 1);
      expect(parent.children.query<ArtifactMarkerLayer>(), hasLength(1));
      expect(parent.children.query<ArtifactMarker>(), hasLength(1));
      expect(layer.markerTypeForTesting(crown.id), crown.type);
      expect(layer.markerTypeForTesting(sword.id), isNull);
      expect(layer.markerSelectedForTesting(crown.id), isTrue);
    });

    test('anchors markers to the projected hex top face', () {
      final layer = ArtifactMarkerLayer();
      final parent = Component();
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.templeReliquary,
        col: 2,
        row: 1,
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
          7;

      layer.sync(parent: parent, artifacts: [artifact]);

      final position = layer.markerPositionForTesting(artifact.id)!;
      expect(position.x, closeTo(tileCenter.x, 0.0001));
      expect(position.y, closeTo(expectedTopFaceY, 0.0001));
      expect(
        layer.markerPriorityForTesting(artifact.id),
        MapPriority.perTile(MapPriority.artifact, col: 2, row: 1),
      );
    });

    test('updates marker scale for density changes', () {
      final layer = ArtifactMarkerLayer();
      final parent = Component();
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.queensMirror,
        col: 0,
        row: 0,
      );

      layer
        ..sync(parent: parent, artifacts: [artifact])
        ..markerWorldScale = 2;

      expect(layer.markerWorldScaleForTesting(artifact.id), 2);
    });
  });
}
