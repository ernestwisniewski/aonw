import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_management_overlay.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_management_overlay_layer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityManagementOverlay', () {
    test('maps city management states to three visual color groups', () {
      final overlay = CityManagementOverlay(
        hexes: const [
          CityManagementOverlayHex(
            hex: CityHex(col: 0, row: 0),
            kind: CityManagementOverlayHexKind.workedManual,
            label: 'R',
          ),
        ],
      );

      expect(
        overlay.colorForTesting(CityManagementOverlayHexKind.workedManual),
        HudPalette.success,
      );
      expect(
        overlay.colorForTesting(CityManagementOverlayHexKind.workedAuto),
        HudPalette.success,
      );
      expect(
        overlay.colorForTesting(CityManagementOverlayHexKind.workedIdle),
        HudPalette.success,
      );
      expect(
        overlay.colorForTesting(
          CityManagementOverlayHexKind.workerImprovementExisting,
        ),
        HudPalette.info,
      );
      expect(
        overlay.colorForTesting(
          CityManagementOverlayHexKind.workerImprovementMissingInCity,
        ),
        HudPalette.info,
      );
      expect(
        overlay.colorForTesting(CityManagementOverlayHexKind.growthRecommended),
        HudPalette.info,
      );
      expect(
        overlay.colorForTesting(CityManagementOverlayHexKind.growthCandidate),
        HudPalette.warning,
      );
    });

    test('caps city management alpha and details while dimmed', () {
      final overlay = CityManagementOverlay(
        dimmed: true,
        hexes: const [
          CityManagementOverlayHex(
            hex: CityHex(col: 0, row: 0),
            kind: CityManagementOverlayHexKind.workerImprovementExisting,
            label: '3F',
          ),
        ],
      );

      expect(overlay.dimmedForTesting, isTrue);
      expect(overlay.drawsDetailsForTesting, isFalse);
      expect(
        overlay.fillAlphaForTesting(
          CityManagementOverlayHexKind.workerImprovementExisting,
        ),
        MapAlpha.faint,
      );
    });
  });

  group('CityManagementOverlayLayer', () {
    test('marks preferred city expansion as recommended', () {
      final layer = CityManagementOverlayLayer();
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 2, row: 1)],
        preferredExpansionHex: CityHex(col: 1, row: 2),
      );

      layer.sync(
        parent: parent,
        state: const GameState(
          cities: [city],
          interaction: GameInteractionState(
            pendingAction: PendingCityExpansionSelection(
              ownerPlayerId: 'player_1',
              cityId: 'city_1',
            ),
          ),
        ),
        mapData: _map(),
        cityRuleset: CityRulesets.standard,
      );

      final hexes = layer.overlayHexesForTesting;
      expect(hexes, isNotEmpty);
      expect(hexes.first.hex, const CityHex(col: 1, row: 2));
      expect(hexes.first.kind, CityManagementOverlayHexKind.growthRecommended);
      expect(
        hexes.map((hex) => hex.kind),
        contains(CityManagementOverlayHexKind.growthCandidate),
      );
    });
  });
}

MapData _map() {
  return MapData(
    cols: 4,
    rows: 4,
    tiles: [
      for (var row = 0; row < 4; row++)
        for (var col = 0; col < 4; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
