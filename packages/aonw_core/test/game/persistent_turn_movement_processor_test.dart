import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentTurnMovementProcessor', () {
    test('resets movement only for submitted players', () {
      final playerUnit = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
      ).copyWith(movementPoints: 0);
      final otherUnit = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 2,
        row: 2,
      ).copyWith(movementPoints: 0);

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(units: [playerUnit, otherUnit]),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 4, rows: 4),
      );

      expect(
        result.state.units
            .singleWhere((unit) => unit.id == playerUnit.id)
            .movementPoints,
        UnitMovementBalance.maxMovementPointsForType(playerUnit.type),
      );
      expect(
        result.state.units
            .singleWhere((unit) => unit.id == otherUnit.id)
            .movementPoints,
        0,
      );
    });

    test('keeps fortified unit idle and healing when no enemy is visible', () {
      final warrior = GameUnit.startingWarrior(ownerPlayerId: 'player_1')
          .copyWith(movementPoints: 0, posture: UnitPosture.fortified)
          .copyWithHitPoints(7);
      final distantEnemy = GameUnit.startingWarrior(
        ownerPlayerId: 'player_2',
        col: 4,
        row: 4,
      );

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(units: [warrior, distantEnemy]),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 5, rows: 5),
      );
      final updated = result.state.units.firstWhere(
        (unit) => unit.id == warrior.id,
      );

      expect(updated.posture, UnitPosture.fortified);
      expect(updated.movementPoints, 0);
      expect(updated.hitPoints, 8);
    });

    test('heals a threatened fortified unit without restoring movement', () {
      final warrior = GameUnit.startingWarrior(ownerPlayerId: 'player_1')
          .copyWith(movementPoints: 0, posture: UnitPosture.fortified)
          .copyWithHitPoints(7);
      final visibleEnemy = GameUnit.startingWarrior(
        ownerPlayerId: 'player_2',
        col: 2,
        row: 0,
      );

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(units: [warrior, visibleEnemy]),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 5, rows: 5),
      );
      final updated = result.state.units.firstWhere(
        (unit) => unit.id == warrior.id,
      );

      expect(updated.posture, UnitPosture.fortified);
      expect(updated.movementPoints, 0);
      expect(updated.hitPoints, 8);
    });

    test('keeps healing unit fortified without movement when fully healed', () {
      final warrior = GameUnit.startingWarrior(ownerPlayerId: 'player_1')
          .copyWith(movementPoints: 0, posture: UnitPosture.fortified)
          .copyWithHitPoints(9);

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(units: [warrior]),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 5, rows: 5),
      );
      final updated = result.state.units.single;

      expect(updated.posture, UnitPosture.fortified);
      expect(updated.movementPoints, 0);
      expect(updated.hitPoints, isNull);
    });

    test(
      'keeps a healthy threatened unit fortified and emits visible targets',
      () {
        final warrior = GameUnit.startingWarrior(
          ownerPlayerId: 'player_1',
        ).copyWith(movementPoints: 0, posture: UnitPosture.fortified);
        final laterEnemy = GameUnit(
          id: 'enemy_b',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: 2,
          row: 0,
        );
        final earlierEnemy = GameUnit(
          id: 'enemy_a',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: 1,
          row: 0,
        );

        final result = PersistentTurnMovementProcessor.resetForPlayers(
          state: PersistentGameState(
            units: [warrior, laterEnemy, earlierEnemy],
          ),
          playerIds: const ['player_1'],
          mapData: _mapData(cols: 5, rows: 5),
        );

        expect(result.state.units.first.posture, UnitPosture.fortified);
        expect(result.state.units.first.movementPoints, 0);
        final alert = result.events
            .whereType<FortifiedUnitThreatenedEvent>()
            .single;
        expect(alert.unitId, warrior.id);
        expect(alert.ownerPlayerId, 'player_1');
        expect(alert.targets, const [
          FortifiedUnitThreatTarget(unitId: 'enemy_a', col: 1, row: 0),
          FortifiedUnitThreatTarget(unitId: 'enemy_b', col: 2, row: 0),
        ]);
      },
    );

    test('emits fortification alerts before automatic movement events', () {
      final fortifier = GameUnit(
        id: 'fortifier',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 0,
        movementPoints: 0,
        posture: UnitPosture.fortified,
      );
      final enemy = GameUnit(
        id: 'enemy',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 1,
        row: 0,
      );
      final mover =
          GameUnit(
            id: 'mover',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            name: GameUnitType.warrior.defaultNameToken,
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

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(units: [mover, enemy, fortifier]),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 4, rows: 4),
      );

      expect(result.events, hasLength(2));
      expect(result.events.first, isA<FortifiedUnitThreatenedEvent>());
      expect(result.events.last, isA<UnitMovedEvent>());
    });

    test('orders multiple fortification alerts by owner and unit identity', () {
      GameUnit fortifier(String id, String ownerPlayerId, int row) => GameUnit(
        id: id,
        ownerPlayerId: ownerPlayerId,
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: row,
        movementPoints: 0,
        posture: UnitPosture.fortified,
      );

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(
          units: [
            fortifier('unit_z', 'player_1', 2),
            GameUnit(
              id: 'enemy',
              ownerPlayerId: 'player_3',
              type: GameUnitType.warrior,
              name: GameUnitType.warrior.defaultNameToken,
              col: 1,
              row: 1,
            ),
            fortifier('unit_b', 'player_2', 1),
            fortifier('unit_a', 'player_1', 0),
          ],
        ),
        playerIds: const ['player_2', 'player_1'],
        mapData: _mapData(cols: 4, rows: 4),
      );

      expect(
        result.events.whereType<FortifiedUnitThreatenedEvent>().map(
          (event) => event.unitId,
        ),
        ['unit_a', 'unit_z', 'unit_b'],
      );
    });

    test('executes queued paths on new turn', () {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1')
          .copyWith(movementPoints: 0)
          .copyWithQueuedPath(
            QueuedMovePath(
              targetCol: 2,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 0,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 2,
                ),
              ],
            ),
          );

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(units: [commander]),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 4, rows: 2),
      );
      final moved = result.state.units.single;

      expect(moved.col, 2);
      expect(moved.row, 0);
      expect(moved.queuedPath, isNull);
      expect(moved.movementPoints, 3);
    });

    test('executes merchant queued city travel on new turn', () {
      final merchant =
          GameUnit(
            id: 'merchant_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.merchant,
            name: GameUnitType.merchant.defaultNameToken,
            col: 1,
            row: 0,
            movementPoints: 0,
          ).copyWithQueuedPath(
            QueuedMovePath(
              targetCol: 3,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                UnitMovementStep(
                  col: 3,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 2,
                ),
              ],
            ),
          );
      final guard = GameUnit.startingWarrior(
        ownerPlayerId: 'player_1',
        col: 3,
        row: 0,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'city_1',
        center: CityHex(col: 3, row: 0),
        controlledHexes: [CityHex(col: 3, row: 0)],
      );

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(units: [merchant, guard], cities: [city]),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 4, rows: 1),
      );
      final moved = result.state.units.firstWhere(
        (unit) => unit.id == merchant.id,
      );

      expect(moved.col, 3);
      expect(moved.row, 0);
      expect(moved.queuedPath, isNull);
      expect(moved.merchantTradeRoute, isNull);
    });

    test(
      'advances artifact carrier queued path into adjacent rough terrain',
      () {
        final carrier =
            GameUnit(
                  id: 'carrier_1',
                  ownerPlayerId: 'player_1',
                  type: GameUnitType.scout,
                  name: 'Scout',
                  col: 0,
                  row: 0,
                  carriedArtifactId: 'artifact_1',
                )
                .copyWith(movementPoints: 0)
                .copyWithQueuedPath(
                  QueuedMovePath(
                    targetCol: 1,
                    targetRow: 0,
                    steps: const [
                      UnitMovementStep(
                        col: 0,
                        row: 0,
                        enterCost: 0,
                        cumulativeCost: 0,
                      ),
                      UnitMovementStep(
                        col: 1,
                        row: 0,
                        enterCost: 3,
                        cumulativeCost: 3,
                      ),
                    ],
                  ),
                );

        final result = PersistentTurnMovementProcessor.resetForPlayers(
          state: PersistentGameState(units: [carrier]),
          playerIds: const ['player_1'],
          mapData: _mapData(
            cols: 2,
            rows: 1,
            terrainOverrides: {
              (col: 1, row: 0): [
                TerrainType.grassland,
                TerrainType.forest,
                TerrainType.hills,
              ],
            },
          ),
        );
        final moved = result.state.units.single;

        expect(moved.col, 1);
        expect(moved.row, 0);
        expect(moved.movementPoints, 0);
        expect(moved.queuedPath, isNull);
      },
    );

    test('continues auto-exploration for scout on new turn', () {
      final scout = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: GameUnitType.scout.defaultNameToken,
        col: 1,
        row: 0,
        movementPoints: 0,
        posture: UnitPosture.autoExploring,
      );
      final fog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            discoveredHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
            },
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
            },
          ),
        },
      );

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(units: [scout], fogOfWar: fog),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 6, rows: 1),
      );
      final moved = result.state.units.single;

      expect(result.changed, isTrue);
      expect(moved.posture, UnitPosture.autoExploring);
      expect(moved.col, greaterThan(1));
      expect(
        result.state.fogOfWar.fogForPlayer('player_1').discoveredHexes.length,
        greaterThan(fog.fogForPlayer('player_1').discoveredHexes.length),
      );
    });

    test('advances multiple auto-exploring scouts in one turn reset', () {
      final firstScout = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: GameUnitType.scout.defaultNameToken,
        col: 1,
        row: 1,
        movementPoints: 0,
        posture: UnitPosture.autoExploring,
      );
      final secondScout = GameUnit(
        id: 'scout_2',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: GameUnitType.scout.defaultNameToken,
        col: 1,
        row: 2,
        movementPoints: 0,
        posture: UnitPosture.autoExploring,
      );

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(units: [firstScout, secondScout]),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 8, rows: 5),
      );
      final moved = result.state.units;

      expect(result.changed, isTrue);
      expect(moved, hasLength(2));
      expect(moved.every((unit) => unit.isAutoExploring), isTrue);
      expect(moved[0].occupies(firstScout.col, firstScout.row), isFalse);
      expect(moved[1].occupies(secondScout.col, secondScout.row), isFalse);
      expect(
        moved.map((unit) => (col: unit.col, row: unit.row)).toSet(),
        hasLength(2),
      );
    });

    test('preserves queued path when movement is partial', () {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1')
          .copyWith(movementPoints: 0)
          .copyWithQueuedPath(
            QueuedMovePath(
              targetCol: 6,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 0,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 2,
                ),
                UnitMovementStep(
                  col: 3,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 3,
                ),
                UnitMovementStep(
                  col: 4,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 4,
                ),
                UnitMovementStep(
                  col: 5,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 5,
                ),
                UnitMovementStep(
                  col: 6,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 6,
                ),
              ],
            ),
          );

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(units: [commander]),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 8, rows: 2),
      );
      final moved = result.state.units.single;

      expect(moved.col, 5);
      expect(moved.row, 0);
      expect(moved.movementPoints, 0);
      expect(moved.queuedPath?.targetCol, 6);
    });

    test('keeps auto-explore posture while advancing queued path', () {
      final scout =
          GameUnit(
            id: 'scout_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.scout,
            name: GameUnitType.scout.defaultNameToken,
            col: 0,
            row: 0,
            movementPoints: 0,
            posture: UnitPosture.autoExploring,
          ).copyWithQueuedPath(
            QueuedMovePath(
              targetCol: 6,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 0,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 2,
                ),
                UnitMovementStep(
                  col: 3,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 3,
                ),
                UnitMovementStep(
                  col: 4,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 4,
                ),
                UnitMovementStep(
                  col: 5,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 5,
                ),
                UnitMovementStep(
                  col: 6,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 6,
                ),
              ],
            ),
          );

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(units: [scout]),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 8, rows: 2),
      );
      final moved = result.state.units.single;

      expect(moved.col, 3);
      expect(moved.row, 0);
      expect(moved.posture, UnitPosture.autoExploring);
      expect(moved.queuedPath?.targetCol, 6);
    });
  });
}

MapData _mapData({
  required int cols,
  required int rows,
  Map<({int col, int row}), List<TerrainType>> terrainOverrides = const {},
}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains:
                terrainOverrides[(col: col, row: row)] ??
                const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
