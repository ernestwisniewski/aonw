import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/game_planning_marker_coordinator.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWithFlameGame('attack mode marks only legal unit and city target hexes', (
    game,
  ) async {
    final map = WorldMap(
      cols: 4,
      rows: 1,
      tiles: [
        for (var col = 0; col < 4; col++)
          WorldTile(
            col: col,
            row: 0,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
      ],
    );
    final grid = WorldMapGrid(mapData: map, config: MapConfig.defaultConfig);
    await game.ensureAdd(grid);
    final attacker = GameUnit(
      id: 'archer',
      ownerPlayerId: 'player_1',
      type: GameUnitType.archer,
      name: 'Archer',
      col: 0,
      row: 0,
    );
    final defender = GameUnit(
      id: 'defender',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Defender',
      col: 1,
      row: 0,
    );
    const enemyCity = GameCity(
      id: 'city',
      ownerPlayerId: 'player_2',
      name: 'City',
      center: CityHex(col: 2, row: 0),
    );
    final state = GameClientState(
      activePlayerId: 'player_1',
      units: [attacker, defender],
      cities: const [enemyCity],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              for (var col = 0; col < 4; col++) HexCoordinate(col: col, row: 0),
            },
          ),
        },
      ),
      interaction: InteractionState(
        selection: GameSelection.unit(attacker),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'archer',
        ),
      ),
    );

    GamePlanningMarkerCoordinator(grid: grid).sync(state);

    expect(grid.markersForCoordinate(0, 0).hasAny, isFalse);
    expect(grid.markersForCoordinate(1, 0).canAttackTarget, isTrue);
    expect(grid.markersForCoordinate(2, 0).canAttackTarget, isTrue);
    expect(grid.markersForCoordinate(3, 0).hasAny, isFalse);
    await game.ensureRemove(grid);
  });
}
