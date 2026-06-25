import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentUnitDetachmentResolver', () {
    test(
      'detaches a controlled troop into the first available visible hex',
      () {
        final state = PersistentGameState(
          playerColors: const {'player_1': 0xff0000},
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                visibleHexes: {
                  const HexCoordinate(col: 1, row: 1),
                  const HexCoordinate(col: 2, row: 1),
                },
              ),
            },
          ),
          units: [
            _commander(
              army: const [ArmyTroop(type: TroopType.warrior, count: 2)],
            ),
          ],
        );

        final result = const PersistentUnitDetachmentResolver().detachTroop(
          state: state,
          command: const DetachTroopCommand('commander_1', TroopType.warrior),
          actorPlayerId: 'player_1',
          mapDefinition: _mapDefinition(cols: 4, rows: 4),
        );

        expect(result.accepted, isTrue);
        expect(result.reason, isNull);
        expect(result.state.units, hasLength(2));

        final source = result.state.units.firstWhere(
          (unit) => unit.id == 'commander_1',
        );
        final detached = result.state.units.firstWhere(
          (unit) => unit.id == 'commander_1_warrior_1',
        );
        expect(source.troopCount(TroopType.warrior), 1);
        expect(detached.ownerPlayerId, 'player_1');
        expect(detached.type, GameUnitType.warrior);
        expect(detached.name, GameUnitType.warrior.defaultNameToken);
        expect(detached.col, 2);
        expect(detached.row, 1);
        expect(detached.movementPoints, 3);
        expect(
          result.state.fogOfWar.isVisible(
            'player_1',
            const HexCoordinate(col: 2, row: 1),
          ),
          isTrue,
        );
      },
    );

    test(
      'skips occupied destination and uses the next visible passable hex',
      () {
        final state = PersistentGameState(
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                visibleHexes: {
                  const HexCoordinate(col: 1, row: 1),
                  const HexCoordinate(col: 2, row: 1),
                  const HexCoordinate(col: 2, row: 2),
                },
              ),
            },
          ),
          units: [
            _commander(
              army: const [ArmyTroop(type: TroopType.archer, count: 1)],
            ),
            GameUnit(
              id: 'blocker',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              name: 'Blocker',
              col: 2,
              row: 1,
            ),
          ],
        );

        final result = const PersistentUnitDetachmentResolver().detachTroop(
          state: state,
          command: const DetachTroopCommand('commander_1', TroopType.archer),
          actorPlayerId: 'player_1',
          mapDefinition: _mapDefinition(cols: 4, rows: 4),
        );

        final detached = result.state.units.firstWhere(
          (unit) => unit.id == 'commander_1_archer_1',
        );
        expect(result.accepted, isTrue);
        expect(detached.col, 2);
        expect(detached.row, 2);
        expect(detached.type, GameUnitType.archer);
      },
    );

    test('rejects detachment for another player unit', () {
      final state = PersistentGameState(
        units: [
          _commander(
            ownerPlayerId: 'player_2',
            army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
          ),
        ],
      );

      final result = const PersistentUnitDetachmentResolver().detachTroop(
        state: state,
        command: const DetachTroopCommand('commander_1', TroopType.warrior),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 4, rows: 4),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'unit_not_controlled');
      expect(result.state, state);
    });

    test('rejects detachment when troop type is not available', () {
      final state = PersistentGameState(
        units: [
          _commander(
            army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
          ),
        ],
      );

      final result = const PersistentUnitDetachmentResolver().detachTroop(
        state: state,
        command: const DetachTroopCommand('commander_1', TroopType.archer),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 4, rows: 4),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'troop_not_available');
      expect(result.state, state);
    });

    test('rejects detachment when no visible destination is available', () {
      final state = PersistentGameState(
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {const HexCoordinate(col: 1, row: 1)},
            ),
          },
        ),
        units: [
          _commander(
            army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
          ),
        ],
      );

      final result = const PersistentUnitDetachmentResolver().detachTroop(
        state: state,
        command: const DetachTroopCommand('commander_1', TroopType.warrior),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 4, rows: 4),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'detachment_destination_unavailable');
      expect(result.state, state);
    });
  });
}

GameUnit _commander({
  String ownerPlayerId = 'player_1',
  List<ArmyTroop> army = const [],
}) {
  return GameUnit(
    id: 'commander_1',
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.commander,
    name: 'Commander',
    col: 1,
    row: 1,
    army: army,
  );
}

MapDefinition _mapDefinition({required int cols, required int rows}) {
  return MapDefinition(
    cols: cols,
    rows: rows,
    mapName: 'duel',
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          MapTileDefinition(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
