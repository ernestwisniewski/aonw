import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/combat_hex_alert_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final kind in CombatHexAlertKind.values) {
    test('${kind.name} outline follows the unit onto its destination hex', () {
      const origin = CityHex(col: 4, row: 5);
      const destination = CityHex(col: 5, row: 5);
      var unitPosition = UnitMarkerLayer.worldPositionFor(
        origin.col,
        origin.row,
      );
      final layer =
          CombatHexAlertLayer(unitPositionFor: (_) => unitPosition.clone())
            ..show(
              parent: Component(),
              effect: ShowCombatHexAlertEffect(
                id: 'tracked:${kind.name}',
                unitId: 'tracked',
                ownerPlayerId: 'player_1',
                col: origin.col,
                row: origin.row,
                kind: kind,
              ),
            );

      unitPosition = UnitMarkerLayer.worldPositionFor(
        destination.col,
        destination.row,
      );
      layer.update(0.1);

      final originCenter = HexGeometry.tilePosition(
        col: origin.col,
        row: origin.row,
        hexRadius: MapConfig.defaultHexRadius,
      );
      final destinationCenter = HexGeometry.tilePosition(
        col: destination.col,
        row: destination.row,
        hexRadius: MapConfig.defaultHexRadius,
      );
      final offset = layer.alertGridOffsetForTesting('tracked:${kind.name}');
      expect(offset.x, closeTo(destinationCenter.x - originCenter.x, 0.001));
      expect(offset.y, closeTo(destinationCenter.y - originCenter.y, 0.001));
    });
  }
}
