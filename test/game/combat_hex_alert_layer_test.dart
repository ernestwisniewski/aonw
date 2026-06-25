import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/combat_hex_alert_layer.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CombatHexAlertLayer', () {
    test('shows attacked city hex through the owners next submitted turn', () {
      final layer = CombatHexAlertLayer();
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 2, row: 3),
      );

      layer.show(
        parent: parent,
        effect: const ShowCombatHexAlertEffect(
          id: 'city:city_1',
          cityId: 'city_1',
          ownerPlayerId: 'player_1',
          col: 2,
          row: 3,
          kind: CombatHexAlertKind.attacked,
        ),
      );

      expect(layer.hasAlertForTesting('city_1'), isTrue);
      expect(layer.alertHexForTesting('city_1'), city.center);

      layer.syncState(
        parent: parent,
        state: const GameState(cities: [city]),
      );

      expect(layer.hasAlertForTesting('city_1'), isTrue);

      layer.syncState(
        parent: parent,
        state: const GameState(
          cities: [city],
          submittedPlayerIds: {'player_1'},
        ),
      );

      expect(layer.hasAlertForTesting('city_1'), isTrue);

      layer.syncState(
        parent: parent,
        state: const GameState(cities: [city]),
      );

      expect(layer.hasAlertForTesting('city_1'), isTrue);

      layer.syncState(
        parent: parent,
        state: const GameState(
          cities: [city],
          submittedPlayerIds: {'player_1'},
        ),
      );

      expect(layer.hasAlertForTesting('city_1'), isFalse);
    });

    test('keeps alert if the attack arrived after owner already submitted', () {
      final layer = CombatHexAlertLayer();
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 2, row: 3),
      );

      layer
        ..show(
          parent: parent,
          effect: const ShowCombatHexAlertEffect(
            id: 'city:city_1',
            cityId: 'city_1',
            ownerPlayerId: 'player_1',
            col: 2,
            row: 3,
            kind: CombatHexAlertKind.attacked,
            ownerSubmittedAtAttack: true,
          ),
        )
        ..syncState(
          parent: parent,
          state: const GameState(
            cities: [city],
            submittedPlayerIds: {'player_1'},
          ),
        );

      expect(layer.hasAlertForTesting('city_1'), isTrue);

      layer.syncState(
        parent: parent,
        state: const GameState(cities: [city]),
      );

      expect(layer.hasAlertForTesting('city_1'), isTrue);

      layer.syncState(
        parent: parent,
        state: const GameState(
          cities: [city],
          submittedPlayerIds: {'player_1'},
        ),
      );

      expect(layer.hasAlertForTesting('city_1'), isFalse);
    });

    test('keeps unit hex alerts attached to the living unit', () {
      final layer = CombatHexAlertLayer();
      final parent = Component();

      layer.show(
        parent: parent,
        effect: const ShowCombatHexAlertEffect(
          id: 'attacker:unit_1',
          unitId: 'unit_1',
          ownerPlayerId: 'player_1',
          col: 4,
          row: 5,
          kind: CombatHexAlertKind.attacker,
        ),
      );

      expect(layer.hasAlertForTesting('attacker:unit_1'), isTrue);
      expect(
        layer.alertHexForTesting('attacker:unit_1'),
        const CityHex(col: 4, row: 5),
      );

      layer.syncState(
        parent: parent,
        state: GameState(units: [_movedUnit]),
      );

      expect(layer.hasAlertForTesting('attacker:unit_1'), isTrue);
      expect(
        layer.alertHexForTesting('attacker:unit_1'),
        const CityHex(col: 6, row: 7),
      );

      layer.syncState(
        parent: parent,
        state: const GameState(submittedPlayerIds: {'player_1'}),
      );

      expect(layer.hasAlertForTesting('attacker:unit_1'), isFalse);
    });

    test('removes unit hex alerts when the unit disappears', () {
      final layer = CombatHexAlertLayer();
      final parent = Component();

      layer
        ..show(
          parent: parent,
          effect: const ShowCombatHexAlertEffect(
            id: 'defender:unit_1',
            unitId: 'unit_1',
            ownerPlayerId: 'player_1',
            col: 4,
            row: 5,
            kind: CombatHexAlertKind.attacked,
          ),
        )
        ..syncState(parent: parent, state: const GameState());

      expect(layer.hasAlertForTesting('defender:unit_1'), isFalse);
      expect(layer.alertCountAtHexForTesting(const CityHex(col: 4, row: 5)), 0);
    });

    test(
      'keeps attacked border and attacker glow separate on the same hex',
      () {
        final layer = CombatHexAlertLayer();
        final parent = Component();
        const hex = CityHex(col: 4, row: 5);

        layer
          ..show(
            parent: parent,
            effect: const ShowCombatHexAlertEffect(
              id: 'attacker:unit_1',
              unitId: 'unit_1',
              ownerPlayerId: 'player_1',
              col: 4,
              row: 5,
              kind: CombatHexAlertKind.attacker,
            ),
          )
          ..show(
            parent: parent,
            effect: const ShowCombatHexAlertEffect(
              id: 'defender:unit_1',
              unitId: 'unit_1',
              ownerPlayerId: 'player_1',
              col: 4,
              row: 5,
              kind: CombatHexAlertKind.attacked,
            ),
          );

        expect(layer.alertCountAtHexForTesting(hex), 2);
        expect(layer.alertKindsAtHexForTesting(hex), {
          CombatHexAlertKind.attacker,
          CombatHexAlertKind.attacked,
        });
      },
    );

    test('removes stale alerts when the city disappears or changes owner', () {
      final layer = CombatHexAlertLayer();
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 2, row: 3),
      );

      layer
        ..show(
          parent: parent,
          effect: const ShowCombatHexAlertEffect(
            id: 'city:city_1',
            cityId: 'city_1',
            ownerPlayerId: 'player_1',
            col: 2,
            row: 3,
            kind: CombatHexAlertKind.attacked,
          ),
        )
        ..syncState(parent: parent, state: const GameState());

      expect(layer.hasAlertForTesting('city_1'), isFalse);

      layer
        ..show(
          parent: parent,
          effect: const ShowCombatHexAlertEffect(
            id: 'city:city_1',
            cityId: 'city_1',
            ownerPlayerId: 'player_1',
            col: 2,
            row: 3,
            kind: CombatHexAlertKind.attacked,
          ),
        )
        ..syncState(
          parent: parent,
          state: GameState(cities: [city.copyWith(ownerPlayerId: 'player_2')]),
        );

      expect(layer.hasAlertForTesting('city_1'), isFalse);
    });
  });
}

final _movedUnit = GameUnit(
  id: 'unit_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.warrior,
  name: 'Warrior',
  col: 6,
  row: 7,
);
