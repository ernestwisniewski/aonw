import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/terrain.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class StartingUnits {
  static List<GameUnit> warriorsForPlayers(
    List<Player> players, {
    MapData? mapData,
    int? startPositionSeed,
  }) {
    if (players.isEmpty) return const [];

    final positions = _startingPositions(
      players.length,
      mapData,
      startPositionSeed: startPositionSeed,
    );
    return [
      for (var i = 0; i < players.length; i++)
        GameUnit.startingWarrior(
          ownerPlayerId: players[i].id,
          col: positions[i].col,
          row: positions[i].row,
        ),
    ];
  }

  static List<GameUnit> unitsForPlayers(
    List<Player> players, {
    MapData? mapData,
    int? startPositionSeed,
  }) {
    if (players.isEmpty) return const [];

    final positions = _startingPositions(
      players.length,
      mapData,
      startPositionSeed: startPositionSeed,
    );
    final used = {
      for (final position in positions) _key(position.col, position.row),
    };
    final units = <GameUnit>[];

    for (var i = 0; i < players.length; i++) {
      final player = players[i];
      final warriorPosition = positions[i];
      final settlerPosition = _settlerPosition(warriorPosition, mapData, used);
      used.add(_key(settlerPosition.col, settlerPosition.row));

      units
        ..add(
          GameUnit.startingWarrior(
            ownerPlayerId: player.id,
            col: warriorPosition.col,
            row: warriorPosition.row,
          ),
        )
        ..add(
          GameUnit.produced(
            id: 'settler_${player.id}',
            ownerPlayerId: player.id,
            type: GameUnitType.settler,
            col: settlerPosition.col,
            row: settlerPosition.row,
          ),
        );
    }

    return units;
  }

  static List<({int col, int row})> _startingPositions(
    int count,
    MapData? mapData, {
    int? startPositionSeed,
  }) {
    if (mapData == null || mapData.tiles.isEmpty) {
      return _shuffledPositions([
        for (var i = 0; i < count; i++) _fallbackPosition(i),
      ], startPositionSeed);
    }

    final used = <String>{};
    final anchors = _anchors(mapData, count);
    final positions = <({int col, int row})>[];

    for (var i = 0; i < count; i++) {
      final anchor = anchors[i];
      final position =
          _nearestFreeTile(mapData, anchor, used, preferLand: true) ??
          _nearestFreeTile(mapData, anchor, used, preferLand: false) ??
          _nearestTile(mapData, anchor, preferLand: true) ??
          _nearestTile(mapData, anchor, preferLand: false) ??
          _fallbackPosition(i);
      used.add(_key(position.col, position.row));
      positions.add(position);
    }

    return _shuffledPositions(positions, startPositionSeed);
  }

  static List<({int col, int row})> _anchors(MapData mapData, int count) {
    final cols = mapData.cols > 0 ? mapData.cols : 1;
    final rows = mapData.rows > 0 ? mapData.rows : 1;
    final base = <({int col, int row})>[
      (col: cols ~/ 4, row: rows ~/ 4),
      (col: 3 * cols ~/ 4, row: 3 * rows ~/ 4),
      (col: 3 * cols ~/ 4, row: rows ~/ 4),
      (col: cols ~/ 4, row: 3 * rows ~/ 4),
      (col: cols ~/ 2, row: rows ~/ 2),
    ];

    return [for (var i = 0; i < count; i++) base[i % base.length]];
  }

  static ({int col, int row})? _nearestFreeTile(
    MapData mapData,
    ({int col, int row}) anchor,
    Set<String> used, {
    required bool preferLand,
  }) {
    for (final tile in _tilesByDistance(mapData, anchor)) {
      if (used.contains(_key(tile.col, tile.row))) continue;
      if (preferLand && !_canStartingUnitEnter(tile)) continue;
      return (col: tile.col, row: tile.row);
    }

    return null;
  }

  static ({int col, int row}) _settlerPosition(
    ({int col, int row}) escortPosition,
    MapData? mapData,
    Set<String> used,
  ) {
    if (mapData == null || mapData.tiles.isEmpty) {
      const offsets = [
        (col: 2, row: 0),
        (col: 0, row: 2),
        (col: 2, row: 1),
        (col: 1, row: 2),
        (col: -1, row: 0),
        (col: 0, row: -1),
      ];
      for (final offset in offsets) {
        final candidate = (
          col: escortPosition.col + offset.col,
          row: escortPosition.row + offset.row,
        );
        if (!used.contains(_key(candidate.col, candidate.row))) {
          return candidate;
        }
      }
      return (col: escortPosition.col + 1, row: escortPosition.row);
    }

    return _nearestFreeTile(mapData, escortPosition, used, preferLand: true) ??
        _nearestFreeTile(mapData, escortPosition, used, preferLand: false) ??
        _nearestTile(mapData, escortPosition, preferLand: true) ??
        _nearestTile(mapData, escortPosition, preferLand: false) ??
        escortPosition;
  }

  static ({int col, int row})? _nearestTile(
    MapData mapData,
    ({int col, int row}) anchor, {
    required bool preferLand,
  }) {
    for (final tile in _tilesByDistance(mapData, anchor)) {
      if (preferLand && !_canStartingUnitEnter(tile)) continue;
      return (col: tile.col, row: tile.row);
    }

    return null;
  }

  static bool _canStartingUnitEnter(TileData tile) {
    return !UnitMovementCostRules.costToEnter(
      TileTerrainProfileRules.fromTile(tile),
    ).blocked;
  }

  static List<TileData> _tilesByDistance(
    MapData mapData,
    ({int col, int row}) anchor,
  ) => List<TileData>.of(mapData.tiles)
    ..sort((a, b) {
      final distance = _distanceFrom(
        a,
        anchor,
      ).compareTo(_distanceFrom(b, anchor));
      if (distance != 0) return distance;

      final row = a.row.compareTo(b.row);
      if (row != 0) return row;
      return a.col.compareTo(b.col);
    });

  static int _distanceFrom(TileData tile, ({int col, int row}) anchor) {
    final dc = tile.col - anchor.col;
    final dr = tile.row - anchor.row;
    return dc * dc + dr * dr;
  }

  static ({int col, int row}) _fallbackPosition(int index) {
    const base = <({int col, int row})>[
      (col: 0, row: 0),
      (col: 1, row: 0),
      (col: 0, row: 1),
      (col: 1, row: 1),
    ];
    if (index < base.length) return base[index];
    return (col: index, row: 0);
  }

  static String _key(int col, int row) => '$col:$row';

  static List<({int col, int row})> _shuffledPositions(
    List<({int col, int row})> positions,
    int? seed,
  ) {
    if (seed == null || positions.length < 2) return positions;

    final shuffled = List<({int col, int row})>.of(positions);
    final rng = _StartingPositionRng(seed);
    for (var i = shuffled.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final current = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = current;
    }
    return shuffled;
  }
}

final class _StartingPositionRng {
  static const int _mask32 = 0xFFFFFFFF;
  static const int _multiplier = 1664525;
  static const int _increment = 1013904223;

  int _state;

  _StartingPositionRng(int seed) : _state = _mix(seed);

  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0) {
      throw RangeError.range(maxExclusive, 1, null, 'maxExclusive');
    }
    _state = (_multiplier * _state + _increment) & _mask32;
    return _state % maxExclusive;
  }

  static int _mix(int value) {
    var hash = value & _mask32;
    hash = (hash ^ (hash >>> 16)) & _mask32;
    hash = (hash * 0x7FEB352D) & _mask32;
    hash = (hash ^ (hash >>> 15)) & _mask32;
    hash = (hash * 0x846CA68B) & _mask32;
    return (hash ^ (hash >>> 16)) & _mask32;
  }
}
