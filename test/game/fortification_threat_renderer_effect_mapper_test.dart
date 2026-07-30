import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_event_renderer_effect_mapper.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fortification threat renderer effects', () {
    test('shows blue threat borders while focusing the fortifier', () {
      final fortifier = _fortifier();
      final state = GameState(
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
      final camera = effects.last as SmoothCameraEffect;
      expect((camera.col, camera.row), (3, 4));
      expect(camera.duration, 0.85);
    });

    test('keeps the marker attached to the detected unit', () {
      final fortifier = _fortifier();
      final enemy = _enemy(id: 'enemy', col: 4, row: 4);
      final previousState = GameState(
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
      expect((alert.col, alert.row), (5, 4));
      expect(effects.last, isA<SmoothCameraEffect>());
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
        state: GameState(units: [fortifier, enemy]),
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
