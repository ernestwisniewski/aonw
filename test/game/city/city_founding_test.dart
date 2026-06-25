import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 5,
  rows: 5,
  tiles: [
    for (var row = 0; row < 5; row++)
      for (var col = 0; col < 5; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

TileData _tile(MapData map, int col, int row) => map.tileAt(col, row)!;

GameCity _city({
  required int centerCol,
  required int centerRow,
  List<CityHex> controlledHexes = const [],
}) => GameCity(
  id: 'city_${centerCol}_$centerRow',
  ownerPlayerId: 'player_1',
  name: 'City',
  center: CityHex(col: centerCol, row: centerRow),
  controlledHexes: controlledHexes,
);

GameUnit _commander({List<ArmyTroop> army = const []}) =>
    GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: 2,
      row: 2,
      army: army,
    );

GameUnit _standaloneSettler() => GameUnit.produced(
  id: 'settler_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.settler,
  col: 2,
  row: 2,
);

void main() {
  group('CityFoundingRules', () {
    test('allows a commander with settlers to start on a valid city tile', () {
      final map = _map();
      final commander = _commander(
        army: const [ArmyTroop(type: TroopType.settler, count: 1)],
      );

      expect(
        CityFoundingRules.canStart(
          unit: commander,
          centerTile: _tile(map, 2, 2),
          cities: const [],
        ),
        isTrue,
      );
    });

    test('allows a standalone settler to start on a valid city tile', () {
      final map = _map();

      expect(
        CityFoundingRules.canStart(
          unit: _standaloneSettler(),
          centerTile: _tile(map, 2, 2),
          cities: const [],
        ),
        isTrue,
      );
    });

    test('rejects starting without settlers', () {
      final map = _map();

      expect(
        CityFoundingRules.startFailure(
          unit: _commander(),
          centerTile: _tile(map, 2, 2),
          cities: const [],
        ),
        CityFoundingFailure.noSettlers,
      );
    });

    test(
      'controlled city hexes must be outside center and within radius two',
      () {
        final map = _map();
        final draft = CityFoundingDraft(
          unitId: 'commander_player_1',
          ownerPlayerId: 'player_1',
          center: const CityHex(col: 2, row: 2),
        );

        expect(
          CityFoundingRules.isControlledHexCandidate(
            draft: draft,
            tile: _tile(map, 2, 2),
            mapData: map,
            cities: const [],
          ),
          isFalse,
        );
        expect(
          CityFoundingRules.isControlledHexCandidate(
            draft: draft,
            tile: _tile(map, 3, 2),
            mapData: map,
            cities: const [],
          ),
          isTrue,
        );
        expect(
          CityFoundingRules.isControlledHexCandidate(
            draft: draft,
            tile: _tile(map, 4, 4),
            mapData: map,
            cities: const [],
          ),
          isFalse,
        );
      },
    );

    test('allows controlled hex candidates on mountain and water tiles', () {
      final map = MapData(
        cols: 5,
        rows: 5,
        tiles: [
          for (var row = 0; row < 5; row++)
            for (var col = 0; col < 5; col++)
              TileData(
                col: col,
                row: row,
                terrains: col == 3 && row == 2
                    ? const [TerrainType.mountain]
                    : col == 2 && row == 3
                    ? const [TerrainType.ocean]
                    : const [TerrainType.plains],
                resources: const [],
                height: 0,
              ),
        ],
      );
      final draft = CityFoundingDraft(
        unitId: 'commander_player_1',
        ownerPlayerId: 'player_1',
        center: const CityHex(col: 2, row: 2),
      );

      expect(
        CityFoundingRules.isControlledHexCandidate(
          draft: draft,
          tile: _tile(map, 3, 2),
          mapData: map,
          cities: const [],
        ),
        isTrue,
      );
      expect(
        CityFoundingRules.isControlledHexCandidate(
          draft: draft,
          tile: _tile(map, 2, 3),
          mapData: map,
          cities: const [],
        ),
        isTrue,
      );
    });

    test(
      'rejects controlled hex that is controlled hex of existing city (rule b)',
      () {
        final map = _map();
        final draft = CityFoundingDraft(
          unitId: 'commander_player_1',
          ownerPlayerId: 'player_1',
          center: const CityHex(col: 2, row: 2),
        );
        final existingCity = _city(
          centerCol: 0,
          centerRow: 0,
          controlledHexes: const [CityHex(col: 3, row: 2)],
        );

        expect(
          CityFoundingRules.isControlledHexCandidate(
            draft: draft,
            tile: _tile(map, 3, 2),
            mapData: map,
            cities: [existingCity],
          ),
          isFalse,
        );
      },
    );

    test('rejects controlled hex that is center of existing city (rule c)', () {
      final map = _map();
      final draft = CityFoundingDraft(
        unitId: 'commander_player_1',
        ownerPlayerId: 'player_1',
        center: const CityHex(col: 2, row: 2),
      );
      final existingCity = _city(centerCol: 3, centerRow: 2);

      expect(
        CityFoundingRules.isControlledHexCandidate(
          draft: draft,
          tile: _tile(map, 3, 2),
          mapData: map,
          cities: [existingCity],
        ),
        isFalse,
      );
    });

    test(
      'rejects start when draft center is controlled hex of existing city (rule d)',
      () {
        final map = _map();
        final commander = _commander(
          army: const [ArmyTroop(type: TroopType.settler, count: 1)],
        );
        final existingCity = _city(
          centerCol: 0,
          centerRow: 0,
          controlledHexes: const [CityHex(col: 2, row: 2)],
        );

        expect(
          CityFoundingRules.startFailure(
            unit: commander,
            centerTile: _tile(map, 2, 2),
            cities: [existingCity],
          ),
          CityFoundingFailure.centerOccupied,
        );
      },
    );

    test('rejects start when center neighbors an existing city', () {
      final map = _map();
      final commander = _commander(
        army: const [ArmyTroop(type: TroopType.settler, count: 1)],
      );
      final existingCity = _city(centerCol: 3, centerRow: 2);

      expect(
        CityFoundingRules.startFailure(
          unit: commander,
          centerTile: _tile(map, 2, 2),
          cities: [existingCity],
        ),
        CityFoundingFailure.tooCloseToCity,
      );
      expect(
        CityFoundingRules.canStart(
          unit: commander,
          centerTile: _tile(map, 2, 2),
          cities: [existingCity],
        ),
        isFalse,
      );
    });

    test('rejects start at distance two from an existing city', () {
      final map = _map();
      final commander = _commander(
        army: const [ArmyTroop(type: TroopType.settler, count: 1)],
      );
      final existingCity = _city(centerCol: 4, centerRow: 2);

      expect(
        CityFoundingRules.startFailure(
          unit: commander,
          centerTile: _tile(map, 2, 2),
          cities: [existingCity],
        ),
        CityFoundingFailure.tooCloseToCity,
      );
    });

    test('allows start at distance three from an existing city', () {
      final map = _map();
      final commander = _commander(
        army: const [ArmyTroop(type: TroopType.settler, count: 1)],
      );
      final existingCity = _city(centerCol: 4, centerRow: 4);

      expect(
        CityFoundingRules.startFailure(
          unit: commander,
          centerTile: _tile(map, 2, 2),
          cities: [existingCity],
        ),
        isNull,
      );
    });

    test('allows controlled hex candidate when no cities conflict', () {
      final map = _map();
      final draft = CityFoundingDraft(
        unitId: 'commander_player_1',
        ownerPlayerId: 'player_1',
        center: const CityHex(col: 2, row: 2),
      );
      final unrelatedCity = _city(
        centerCol: 0,
        centerRow: 0,
        controlledHexes: const [CityHex(col: 0, row: 1)],
      );

      expect(
        CityFoundingRules.isControlledHexCandidate(
          draft: draft,
          tile: _tile(map, 3, 2),
          mapData: map,
          cities: [unrelatedCity],
        ),
        isTrue,
      );
    });

    test('draft cannot confirm disconnected controlled hexes', () {
      final draft = CityFoundingDraft(
        unitId: 'commander_player_1',
        ownerPlayerId: 'player_1',
        center: const CityHex(col: 2, row: 2),
        controlledHexes: const [
          CityHex(col: 4, row: 2),
          CityHex(col: 0, row: 2),
        ],
      );

      expect(draft.hasRequiredControlledHexes, isTrue);
      expect(draft.hasConnectedTerritory, isFalse);
      expect(draft.canConfirm, isFalse);
      expect(
        CityFoundingRules.confirmFailure(draft),
        CityFoundingFailure.invalidControlledHexes,
      );
    });

    test(
      'draft can confirm controlled hexes connected by another controlled hex',
      () {
        final draft = CityFoundingDraft(
          unitId: 'commander_player_1',
          ownerPlayerId: 'player_1',
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [
            CityHex(col: 3, row: 2),
            CityHex(col: 4, row: 2),
          ],
        );

        expect(draft.canConfirm, isTrue);
        expect(CityFoundingRules.confirmFailure(draft), isNull);
      },
    );
  });

  group('GameUnit settlers', () {
    test('consumeSettler removes one settler from commander army', () {
      final commander = _commander(
        army: const [
          ArmyTroop(type: TroopType.warrior, count: 10),
          ArmyTroop(type: TroopType.settler, count: 2),
        ],
      );

      final updated = commander.consumeSettler();

      expect(updated.troopCount(TroopType.settler), 1);
      expect(updated.troopCount(TroopType.warrior), 10);
    });
  });
}
