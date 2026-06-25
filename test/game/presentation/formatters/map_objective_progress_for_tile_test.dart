import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/map_objective_progress_for_tile.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns objective progress for the inspected tile', () {
    const objective = MapObjectiveDefinition(
      id: 'holy_1',
      type: MapObjectiveType.holySite,
      hex: CityHex(col: 1, row: 0),
      requiredHoldTurns: 3,
      victoryPoints: 2,
      goldPerTurn: 1,
    );
    final progress = mapObjectiveProgressForTile(
      mapData: _map(objective),
      tileData: _tile(1),
      gameState: GameState(
        units: [
          GameUnit.produced(
            id: 'guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
        ],
        mapObjectiveHoldStatesByObjectiveId: const {
          'holy_1': MapObjectiveHoldState(
            objectiveId: 'holy_1',
            playerId: 'player_1',
            holdTurns: 2,
          ),
        },
      ),
    );

    expect(progress?.definition.id, 'holy_1');
    expect(progress?.controllingPlayerId, 'player_1');
    expect(progress?.holdTurns, 2);
    expect(progress?.completed, isFalse);
  });

  test('returns null when the tile has no map objective', () {
    expect(
      mapObjectiveProgressForTile(
        mapData: _map(
          const MapObjectiveDefinition(
            id: 'pass_1',
            type: MapObjectiveType.strategicPass,
            hex: CityHex(col: 1, row: 0),
          ),
        ),
        tileData: _tile(0),
        gameState: const GameState(),
      ),
      isNull,
    );
  });
}

MapData _map(MapObjectiveDefinition objective) {
  return MapData(
    cols: 2,
    rows: 1,
    objectives: [objective],
    tiles: [_tile(0), _tile(1)],
  );
}

TileData _tile(int col) {
  return TileData(
    col: col,
    row: 0,
    terrains: const [TerrainType.grassland],
    resources: const [],
    height: 0,
  );
}
