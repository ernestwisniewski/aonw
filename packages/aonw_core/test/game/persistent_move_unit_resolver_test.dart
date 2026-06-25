import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentMoveUnitResolver', () {
    test('moves a controlled unit and emits UnitMovedEvent', () {
      final state = PersistentGameState(
        playerColors: const {'player_1': 0xff0000},
        fogOfWar: FogOfWarState(
          players: {'player_1': PlayerFogOfWar(playerId: 'player_1')},
        ),
        units: [
          GameUnit(
            id: 'commander_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.commander,
            name: 'Commander',
            col: 0,
            row: 0,
          ),
        ],
      );

      final result = const PersistentMoveUnitResolver().resolve(
        state: state,
        command: const MoveUnitCommand('commander_1', 1, 0),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 3, rows: 1),
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(result.state.units.single.col, 1);
      expect(result.state.units.single.row, 0);
      expect(result.state.units.single.movementPoints, 4);
      expect(result.state.units.single.queuedPath, isNull);
      expect(
        result.state.fogOfWar.isVisible(
          'player_1',
          const HexCoordinate(col: 1, row: 0),
        ),
        isTrue,
      );
      expect(result.events.single, isA<UnitMovedEvent>());
      final movedEvent = result.events.single as UnitMovedEvent;
      expect(movedEvent.unitId, 'commander_1');
      expect(movedEvent.fromCol, 0);
      expect(movedEvent.fromRow, 0);
      expect(movedEvent.toCol, 1);
      expect(movedEvent.toRow, 0);
    });

    test('rejects moves into foreign city centers', () {
      final state = PersistentGameState(
        units: [
          GameUnit(
            id: 'commander_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.commander,
            name: 'Commander',
            col: 0,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'enemy_city',
            ownerPlayerId: 'player_2',
            name: 'Enemy',
            center: CityHex(col: 1, row: 0),
          ),
        ],
      );

      final result = const PersistentMoveUnitResolver().resolve(
        state: state,
        command: const MoveUnitCommand('commander_1', 1, 0),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 3, rows: 1),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'move_target_is_foreign_city_center');
      expect(result.state, state);
    });

    test('partially moves and queues remaining path', () {
      final state = PersistentGameState(
        units: [
          GameUnit(
            id: 'commander_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.commander,
            name: 'Commander',
            col: 0,
            row: 0,
            movementPoints: 2,
          ),
        ],
      );

      final result = const PersistentMoveUnitResolver().resolve(
        state: state,
        command: const MoveUnitCommand('commander_1', 4, 0),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 5, rows: 1),
      );

      final moved = result.state.units.single;
      expect(result.accepted, isTrue);
      expect(moved.col, 2);
      expect(moved.row, 0);
      expect(moved.movementPoints, 0);
      expect(moved.queuedPath?.targetCol, 4);
      expect(moved.queuedPath?.targetRow, 0);
      expect(result.events.single, isA<UnitMovedEvent>());
    });

    test(
      'artifact carrier can spend its turn entering adjacent rough city',
      () {
        final carrier = GameUnit(
          id: 'carrier_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: 'Scout',
          col: 0,
          row: 0,
          carriedArtifactId: 'artifact_1',
        );
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 1, row: 0),
        );
        final state = PersistentGameState(units: [carrier], cities: [city]);

        final result = const PersistentMoveUnitResolver().resolve(
          state: state,
          command: const MoveUnitCommand('carrier_1', 1, 0),
          actorPlayerId: 'player_1',
          mapDefinition: _mapDefinition(
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
        expect(result.accepted, isTrue);
        expect(result.reason, isNull);
        expect(moved.col, 1);
        expect(moved.row, 0);
        expect(moved.movementPoints, 0);
        expect(moved.queuedPath, isNull);
        expect(result.events.single, isA<UnitMovedEvent>());
      },
    );

    test('lets warriors spend their movement entering snowy forest tundra', () {
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final state = PersistentGameState(units: [warrior]);

      final result = const PersistentMoveUnitResolver().resolve(
        state: state,
        command: const MoveUnitCommand('warrior_1', 1, 0),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(
          cols: 2,
          rows: 1,
          terrainOverrides: {
            (col: 1, row: 0): [
              TerrainType.snow,
              TerrainType.forest,
              TerrainType.river,
              TerrainType.tundra,
            ],
          },
        ),
      );

      final moved = result.state.units.single;
      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(moved.col, 1);
      expect(moved.row, 0);
      expect(moved.movementPoints, 0);
      expect(moved.queuedPath, isNull);
    });

    test('allows cavalry to enter five-cost snowy forest hills', () {
      final cavalry = GameUnit(
        id: 'cavalry_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.cavalry,
        name: 'Cavalry',
        col: 0,
        row: 0,
      );
      final state = PersistentGameState(units: [cavalry]);

      final result = const PersistentMoveUnitResolver().resolve(
        state: state,
        command: const MoveUnitCommand('cavalry_1', 1, 0),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(
          cols: 2,
          rows: 1,
          terrainOverrides: {
            (col: 1, row: 0): [
              TerrainType.snow,
              TerrainType.forest,
              TerrainType.hills,
            ],
          },
        ),
      );

      final moved = result.state.units.single;
      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(moved.col, 1);
      expect(moved.row, 0);
      expect(moved.movementPoints, 0);
      expect(moved.queuedPath, isNull);
    });

    test('queues path when unit has no movement points', () {
      final state = PersistentGameState(
        units: [
          GameUnit(
            id: 'commander_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.commander,
            name: 'Commander',
            col: 0,
            row: 0,
            movementPoints: 0,
          ),
        ],
      );

      final result = const PersistentMoveUnitResolver().resolve(
        state: state,
        command: const MoveUnitCommand('commander_1', 2, 0),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 3, rows: 1),
      );

      final queued = result.state.units.single;
      expect(result.accepted, isTrue);
      expect(queued.col, 0);
      expect(queued.row, 0);
      expect(queued.queuedPath?.targetCol, 2);
      expect(queued.queuedPath?.targetRow, 0);
      expect(result.events, isEmpty);
    });

    test('rejects movement for another player unit', () {
      final state = PersistentGameState(
        units: [
          GameUnit(
            id: 'commander_2',
            ownerPlayerId: 'player_2',
            type: GameUnitType.commander,
            name: 'Commander',
            col: 0,
            row: 0,
          ),
        ],
      );

      final result = const PersistentMoveUnitResolver().resolve(
        state: state,
        command: const MoveUnitCommand('commander_2', 1, 0),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 2, rows: 1),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'unit_not_controlled');
      expect(result.state, state);
    });

    test('rejects occupied target', () {
      final state = PersistentGameState(
        units: [
          GameUnit(
            id: 'commander_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.commander,
            name: 'Commander',
            col: 0,
            row: 0,
          ),
          GameUnit(
            id: 'commander_2',
            ownerPlayerId: 'player_2',
            type: GameUnitType.commander,
            name: 'Commander',
            col: 1,
            row: 0,
          ),
        ],
      );

      final result = const PersistentMoveUnitResolver().resolve(
        state: state,
        command: const MoveUnitCommand('commander_1', 1, 0),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 2, rows: 1),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'move_target_occupied');
    });

    test('accepts hidden occupied target as a blocked scouting move', () {
      final unit = GameUnit(
        id: 'commander_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.commander,
        name: 'Commander',
        col: 0,
        row: 0,
      );
      final blocker = GameUnit(
        id: 'commander_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.commander,
        name: 'Commander',
        col: 1,
        row: 0,
      );
      final state = PersistentGameState(
        units: [unit, blocker],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {const HexCoordinate(col: 0, row: 0)},
            ),
          },
        ),
      );

      final result = const PersistentMoveUnitResolver().resolve(
        state: state,
        command: const MoveUnitCommand('commander_1', 1, 0),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 2, rows: 1),
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(result.events, isEmpty);
      expect(result.state.units.first, unit);
    });

    test(
      'moves toward a hidden occupied target when approach is reachable',
      () {
        final unit = GameUnit(
          id: 'commander_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.commander,
          name: 'Commander',
          col: 0,
          row: 0,
        );
        final blocker = GameUnit(
          id: 'commander_2',
          ownerPlayerId: 'player_2',
          type: GameUnitType.commander,
          name: 'Commander',
          col: 2,
          row: 0,
        );
        final state = PersistentGameState(
          units: [unit, blocker],
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                visibleHexes: {const HexCoordinate(col: 0, row: 0)},
              ),
            },
          ),
        );

        final result = const PersistentMoveUnitResolver().resolve(
          state: state,
          command: const MoveUnitCommand('commander_1', 2, 0),
          actorPlayerId: 'player_1',
          mapDefinition: _mapDefinition(cols: 3, rows: 2),
        );
        final moved = result.state.units.firstWhere(
          (unit) => unit.id == 'commander_1',
        );

        expect(result.accepted, isTrue);
        expect(result.reason, isNull);
        expect(moved.col == 0 && moved.row == 0, isFalse);
        expect(moved.col == 2 && moved.row == 0, isFalse);
        expect(
          HexDistance.between(
            HexCoordinate(col: moved.col, row: moved.row),
            const HexCoordinate(col: 2, row: 0),
          ),
          lessThan(2),
        );
        expect(result.events.single, isA<UnitMovedEvent>());
      },
    );

    test(
      'moves toward a visible opponent-occupied target when approach is reachable',
      () {
        final unit = GameUnit(
          id: 'commander_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.commander,
          name: 'Commander',
          col: 0,
          row: 0,
        );
        final blocker = GameUnit(
          id: 'commander_2',
          ownerPlayerId: 'player_2',
          type: GameUnitType.commander,
          name: 'Commander',
          col: 2,
          row: 0,
        );
        final state = PersistentGameState(
          units: [unit, blocker],
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                visibleHexes: {
                  const HexCoordinate(col: 0, row: 0),
                  const HexCoordinate(col: 1, row: 0),
                  const HexCoordinate(col: 2, row: 0),
                },
              ),
            },
          ),
        );

        final result = const PersistentMoveUnitResolver().resolve(
          state: state,
          command: const MoveUnitCommand('commander_1', 2, 0),
          actorPlayerId: 'player_1',
          mapDefinition: _mapDefinition(cols: 3, rows: 2),
        );
        final moved = result.state.units.firstWhere(
          (unit) => unit.id == 'commander_1',
        );

        expect(result.accepted, isTrue);
        expect(result.reason, isNull);
        expect(moved.col == 0 && moved.row == 0, isFalse);
        expect(moved.col == 2 && moved.row == 0, isFalse);
        expect(result.events.single, isA<UnitMovedEvent>());
      },
    );

    test('accepts path blocked by a hidden intermediate unit', () {
      final unit = GameUnit(
        id: 'commander_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.commander,
        name: 'Commander',
        col: 0,
        row: 0,
      );
      final blocker = GameUnit(
        id: 'enemy_scout',
        ownerPlayerId: 'player_2',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 1,
        row: 0,
      );
      final state = PersistentGameState(
        units: [unit, blocker],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {
                const HexCoordinate(col: 0, row: 0),
                const HexCoordinate(col: 2, row: 0),
              },
            ),
          },
        ),
      );

      final result = const PersistentMoveUnitResolver().resolve(
        state: state,
        command: const MoveUnitCommand('commander_1', 2, 0),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 3, rows: 1),
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(result.events, isEmpty);
      expect(result.state.units.first, unit);
    });

    test('partially moves toward a distant occupied target', () {
      final state = PersistentGameState(
        units: [
          GameUnit(
            id: 'commander_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.commander,
            name: 'Commander',
            col: 0,
            row: 0,
            movementPoints: 2,
          ),
          GameUnit(
            id: 'commander_2',
            ownerPlayerId: 'player_2',
            type: GameUnitType.commander,
            name: 'Commander',
            col: 4,
            row: 0,
          ),
        ],
      );

      final result = const PersistentMoveUnitResolver().resolve(
        state: state,
        command: const MoveUnitCommand('commander_1', 4, 0),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 5, rows: 1),
      );

      final moved = result.state.units.firstWhere(
        (unit) => unit.id == 'commander_1',
      );
      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(moved.col, 2);
      expect(moved.row, 0);
      expect(moved.queuedPath?.targetCol, 3);
      expect(moved.queuedPath?.targetRow, 0);
    });
  });
}

MapDefinition _mapDefinition({
  required int cols,
  required int rows,
  Map<({int col, int row}), List<TerrainType>> terrainOverrides = const {},
}) {
  return MapDefinition(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          _tile(
            col,
            row,
            terrains:
                terrainOverrides[(col: col, row: row)] ??
                const [TerrainType.grassland],
          ),
    ],
  );
}

MapTileDefinition _tile(
  int col,
  int row, {
  List<TerrainType> terrains = const [TerrainType.grassland],
}) {
  return MapTileDefinition(
    col: col,
    row: row,
    terrains: terrains,
    resources: const [],
    height: 0,
  );
}
