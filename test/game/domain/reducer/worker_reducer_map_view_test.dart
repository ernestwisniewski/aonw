import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/worker/worker_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts worker improvement through canonical map lookup', () {
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: GameUnitType.worker.defaultNameToken,
      col: 1,
      row: 1,
    );
    final state = GameState(
      activePlayerId: 'player_1',
      units: [worker],
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 1, row: 1)],
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: const {TechnologyId.agriculture},
          ),
        },
      ),
      interaction: GameInteractionState(selection: GameSelection.unit(worker)),
    );
    final MapTileLookup mapTiles = WorldMapReadView(
      WorldMap(
        cols: 2,
        rows: 2,
        tiles: [
          WorldTile(
            coordinate: const HexCoord(col: 0, row: 0),
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
          WorldTile(
            coordinate: const HexCoord(col: 1, row: 1),
            terrains: const [TerrainType.grassland],
            resources: const [ResourceType.wheat],
            height: 0,
          ),
        ],
      ),
    );

    final result = WorkerReducer.selectWorkerImprovement(
      state,
      const SelectWorkerImprovementCommand(
        'worker_1',
        FieldImprovementType.farm,
      ),
      mapTiles,
    );

    final updatedWorker = result.state.units.single;
    expect(updatedWorker.workerJob?.improvementType, FieldImprovementType.farm);
    expect(updatedWorker.workerJob?.targetHex, const CityHex(col: 1, row: 1));
    expect(updatedWorker.movementPoints, 0);
    expect(result.state.selection?.type, GameSelectionType.unit);
    expect(result.state.selection?.unit, same(updatedWorker));
    expect(
      result.state.selection?.unit?.workerJob?.improvementType,
      FieldImprovementType.farm,
    );
    expect(result.state.selection?.tile?.resources, [ResourceType.wheat]);
  });
}
