import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StartingUnits starting units', () {
    test('each player starts with a warrior and detached settler', () {
      const players = [
        Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4),
        Player(id: 'p2', name: 'Bob', colorValue: 0xFFc45050),
      ];
      final units = StartingUnits.unitsForPlayers(players);

      expect(units.length, 4);
      for (final player in players) {
        final warrior = units.singleWhere(
          (unit) => unit.id == 'warrior_${player.id}',
        );
        final settler = units.singleWhere(
          (unit) => unit.id == 'settler_${player.id}',
        );

        expect(warrior.type, GameUnitType.warrior);
        expect(warrior.ownerPlayerId, player.id);
        expect(warrior.army, isEmpty);
        expect(settler.type, GameUnitType.settler);
        expect(settler.ownerPlayerId, player.id);
        expect(
          '${settler.col}:${settler.row}',
          isNot('${warrior.col}:${warrior.row}'),
        );
      }
    });

    test('seeded starts keep sites stable but shuffle player assignments', () {
      const players = [
        Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4),
        Player(id: 'p2', name: 'Bob', colorValue: 0xFFc45050),
        Player(id: 'p3', name: 'Celina', colorValue: 0xFF50a050),
        Player(id: 'p4', name: 'Darek', colorValue: 0xFFc4a020),
      ];
      final mapData = _flatMap(cols: 8, rows: 8);

      final firstSeed = StartingUnits.unitsForPlayers(
        players,
        mapData: mapData,
        startPositionSeed: 11,
      );
      final sameSeed = StartingUnits.unitsForPlayers(
        players,
        mapData: mapData,
        startPositionSeed: 11,
      );
      final otherSeed = StartingUnits.unitsForPlayers(
        players,
        mapData: mapData,
        startPositionSeed: 12,
      );

      final firstAssignments = _warriorPositionsByPlayer(firstSeed);
      final sameAssignments = _warriorPositionsByPlayer(sameSeed);
      final otherAssignments = _warriorPositionsByPlayer(otherSeed);

      expect(firstAssignments, sameAssignments);
      expect(firstAssignments.values.toSet(), hasLength(players.length));
      expect(otherAssignments.values.toSet(), firstAssignments.values.toSet());
      expect(otherAssignments['p1'], isNot(firstAssignments['p1']));
    });
  });
}

MapData _flatMap({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

Map<String, String> _warriorPositionsByPlayer(List<GameUnit> units) {
  return {
    for (final unit in units.where((unit) => unit.type == GameUnitType.warrior))
      unit.ownerPlayerId: '${unit.col}:${unit.row}',
  };
}
