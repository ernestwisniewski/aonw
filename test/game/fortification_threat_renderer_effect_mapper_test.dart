import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_event_renderer_effect_mapper.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/combat_hex_alert_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fortification threat renderer effects', () {
    test('shows blue threat borders without moving the camera', () {
      final fortifier = _fortifier();
      final state = GameClientState(
        activePlayerId: 'player_1',
        units: [
          fortifier,
          _enemy(id: 'enemy_a', col: 5, row: 4),
          _enemy(id: 'enemy_b', col: 4, row: 5),
        ],
      );
      final event = FortifiedUnitThreatenedEvent(
        unitId: fortifier.id,
        ownerPlayerId: fortifier.ownerPlayerId,
        targets: const [
          FortifiedUnitThreatTarget(unitId: 'enemy_a', col: 5, row: 4),
          FortifiedUnitThreatTarget(unitId: 'enemy_b', col: 4, row: 5),
        ],
      );

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: [event],
        state: state,
        viewerPlayerId: 'player_1',
      );

      final alerts = effects.whereType<ShowCombatHexAlertEffect>().toList();
      expect(alerts, hasLength(2));
      expect(alerts.map((alert) => (alert.col, alert.row, alert.kind)), [
        (5, 4, CombatHexAlertKind.fortificationThreat),
        (4, 5, CombatHexAlertKind.fortificationThreat),
      ]);
      expect(effects.whereType<SmoothCameraEffect>(), isEmpty);
    });

    test('tracks the detected enemy without overshooting its destination', () {
      final fortifier = _fortifier();
      final enemy = _enemy(id: 'enemy', col: 4, row: 4);
      final previousState = GameClientState(
        activePlayerId: 'player_1',
        units: [fortifier, enemy],
      );
      final state = previousState.copyWith(
        units: [fortifier, enemy.copyWith(col: 5, row: 4)],
      );

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: [
          FortifiedUnitThreatenedEvent(
            unitId: fortifier.id,
            ownerPlayerId: fortifier.ownerPlayerId,
            targets: const [
              FortifiedUnitThreatTarget(unitId: 'enemy', col: 4, row: 4),
            ],
          ),
        ],
        state: state,
        previousState: previousState,
        viewerPlayerId: 'player_1',
      );

      final alert = effects.first as ShowCombatHexAlertEffect;
      expect(alert.unitId, enemy.id);
      expect((alert.col, alert.row), (4, 4));
      expect(effects, hasLength(1));
      expect(effects.whereType<SmoothCameraEffect>(), isEmpty);

      var enemyWorldPosition = UnitMarkerLayer.worldPositionFor(4, 4);
      final layer = CombatHexAlertLayer(
        unitPositionFor: (_) => enemyWorldPosition.clone(),
      )..show(parent: Component(), effect: alert);
      enemyWorldPosition = UnitMarkerLayer.worldPositionFor(5, 4);
      layer.update(0.1);

      final origin = HexGeometry.tilePosition(
        col: 4,
        row: 4,
        hexRadius: MapConfig.defaultHexRadius,
      );
      final destination = HexGeometry.tilePosition(
        col: 5,
        row: 4,
        hexRadius: MapConfig.defaultHexRadius,
      );
      expect(layer.alertHexForTesting(alert.id), const CityHex(col: 4, row: 4));
      final offset = layer.alertGridOffsetForTesting(alert.id);
      expect(offset.x, closeTo(destination.x - origin.x, 0.001));
      expect(offset.y, closeTo(destination.y - origin.y, 0.001));
    });

    test('fails closed without a viewer identity', () {
      final fortifier = _fortifier();
      final enemy = _enemy(id: 'enemy', col: 4, row: 4);

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: [
          FortifiedUnitThreatenedEvent(
            unitId: fortifier.id,
            ownerPlayerId: fortifier.ownerPlayerId,
            targets: const [
              FortifiedUnitThreatTarget(unitId: 'enemy', col: 4, row: 4),
            ],
          ),
        ],
        state: GameClientState(units: [fortifier, enemy]),
      );

      expect(effects, isEmpty);
    });
  });
}

GameUnit _fortifier() => GameUnit(
  id: 'guard_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.warrior,
  name: 'Guard',
  col: 3,
  row: 4,
  movementPoints: 0,
  posture: UnitPosture.fortified,
);

GameUnit _enemy({required String id, required int col, required int row}) =>
    GameUnit(
      id: id,
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: col,
      row: row,
    );
