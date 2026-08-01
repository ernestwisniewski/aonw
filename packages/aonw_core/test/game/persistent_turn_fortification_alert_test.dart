import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('DomainTurnMovementProcessor fortification alerts', () {
    test('keeps fortified unit idle and healing without a visible enemy', () {
      final warrior = GameUnit.startingWarrior(ownerPlayerId: 'player_1')
          .copyWith(movementPoints: 0, posture: UnitPosture.fortified)
          .copyWithHitPoints(7);
      final enemy = GameUnit.startingWarrior(
        ownerPlayerId: 'player_2',
        col: 4,
        row: 4,
      );

      final result = _reset([warrior, enemy]);
      final updated = result.state.units.first;

      expect(updated.posture, UnitPosture.fortified);
      expect(updated.movementPoints, 0);
      expect(updated.hitPoints, 8);
      expect(result.events, isEmpty);
    });

    test('heals a threatened fortified unit without restoring movement', () {
      final warrior = GameUnit.startingWarrior(ownerPlayerId: 'player_1')
          .copyWith(movementPoints: 0, posture: UnitPosture.fortified)
          .copyWithHitPoints(7);
      final enemy = GameUnit.startingWarrior(
        ownerPlayerId: 'player_2',
        col: 2,
        row: 0,
      );

      final result = _reset([warrior, enemy]);
      final updated = result.state.units.first;

      expect(updated.posture, UnitPosture.fortified);
      expect(updated.movementPoints, 0);
      expect(updated.hitPoints, 8);
    });

    test('keeps a fully healed unit fortified without movement', () {
      final warrior = GameUnit.startingWarrior(ownerPlayerId: 'player_1')
          .copyWith(movementPoints: 0, posture: UnitPosture.fortified)
          .copyWithHitPoints(9);

      final updated = _reset([warrior]).state.units.single;

      expect(updated.posture, UnitPosture.fortified);
      expect(updated.movementPoints, 0);
      expect(updated.hitPoints, isNull);
    });

    test('emits visible targets in stable identity order', () {
      final warrior = GameUnit.startingWarrior(
        ownerPlayerId: 'player_1',
      ).copyWith(movementPoints: 0, posture: UnitPosture.fortified);
      final laterEnemy = _unit(id: 'enemy_b', owner: 'player_2', col: 2);
      final earlierEnemy = _unit(id: 'enemy_a', owner: 'player_2', col: 1);

      final result = _reset([warrior, laterEnemy, earlierEnemy]);
      final alert = result.events
          .whereType<FortifiedUnitThreatenedEvent>()
          .single;

      expect(result.state.units.first.posture, UnitPosture.fortified);
      expect(result.state.units.first.movementPoints, 0);
      expect(alert.unitId, warrior.id);
      expect(alert.ownerPlayerId, 'player_1');
      expect(alert.targets, const [
        FortifiedUnitThreatTarget(unitId: 'enemy_a', col: 1, row: 0),
        FortifiedUnitThreatTarget(unitId: 'enemy_b', col: 2, row: 0),
      ]);
    });

    test('emits alerts before automatic movement events', () {
      final fortifier = _fortifier(id: 'fortifier', owner: 'player_1', row: 0);
      final enemy = _unit(id: 'enemy', owner: 'player_2', col: 1);
      final mover =
          _unit(
            id: 'mover',
            owner: 'player_1',
            col: 0,
            row: 2,
            movementPoints: 0,
          ).copyWithQueuedPath(
            QueuedMovePath(
              targetCol: 1,
              targetRow: 2,
              steps: const [
                UnitMovementStep(
                  col: 0,
                  row: 2,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 1,
                  row: 2,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
          );

      final result = _reset([mover, enemy, fortifier]);

      expect(result.events, hasLength(2));
      expect(result.events.first, isA<FortifiedUnitThreatenedEvent>());
      expect(result.events.last, isA<UnitMovedEvent>());
    });

    test('orders multiple alerts by owner and unit identity', () {
      final result = DomainTurnMovementProcessor.resetForPlayers(
        state: DomainState.snapshot(
          units: [
            _fortifier(id: 'unit_z', owner: 'player_1', row: 2),
            _unit(id: 'enemy', owner: 'player_3', col: 1, row: 1),
            _fortifier(id: 'unit_b', owner: 'player_2', row: 1),
            _fortifier(id: 'unit_a', owner: 'player_1', row: 0),
          ],
        ),
        playerIds: const ['player_2', 'player_1'],
        mapData: _mapData(),
      );

      expect(
        result.events.whereType<FortifiedUnitThreatenedEvent>().map(
          (event) => event.unitId,
        ),
        ['unit_a', 'unit_z', 'unit_b'],
      );
    });
  });
}

DomainTurnMovementResult _reset(List<GameUnit> units) {
  return DomainTurnMovementProcessor.resetForPlayers(
    state: DomainState.snapshot(units: units),
    playerIds: const ['player_1'],
    mapData: _mapData(),
  );
}

GameUnit _fortifier({
  required String id,
  required String owner,
  required int row,
}) {
  return _unit(
    id: id,
    owner: owner,
    col: 0,
    row: row,
    movementPoints: 0,
    posture: UnitPosture.fortified,
  );
}

GameUnit _unit({
  required String id,
  required String owner,
  required int col,
  int row = 0,
  int? movementPoints,
  UnitPosture posture = UnitPosture.active,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: owner,
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: col,
    row: row,
    movementPoints: movementPoints,
    posture: posture,
  );
}

WorldMap _mapData() {
  return WorldMap(
    cols: 5,
    rows: 5,
    tiles: [
      for (var row = 0; row < 5; row++)
        for (var col = 0; col < 5; col++)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
