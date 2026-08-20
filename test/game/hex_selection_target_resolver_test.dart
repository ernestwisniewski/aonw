import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/hex_selection/hex_selection_target.dart';
import 'package:aonw/game/presentation/engine/hex_selection/hex_selection_target_resolver.dart';
import 'package:aonw/game/presentation/widgets/theme/artifact_type_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('terrain is always first and every visible entity adds one target', () {
    final tile = WorldTile(
      col: 0,
      row: 0,
      terrains: const [TerrainType.grassland],
      resources: const [],
      height: 0,
    );
    final map = WorldMap(
      cols: 1,
      rows: 1,
      tiles: [tile],
      objectives: const [
        MapObjectiveDefinition(
          id: 'objective_1',
          type: MapObjectiveType.ruins,
          hex: HexCoord(col: 0, row: 0),
          requiredHoldTurns: 2,
        ),
      ],
    );
    final unit = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
    );
    const improvement = FieldImprovement(
      hex: CityHex(col: 0, row: 0),
      type: FieldImprovementType.farm,
    );
    final artifact = WorldArtifact.placed(
      type: WorldArtifactType.heroSword,
      col: 0,
      row: 0,
    );
    final state = GameClientState(
      activePlayerId: 'player_1',
      fogOfWar: FogOfWarState.empty.updatePlayer(
        PlayerFogOfWar(
          playerId: 'player_1',
          visibleHexes: <HexCoordinate>{const HexCoordinate(col: 0, row: 0)},
        ),
      ),
      units: [unit],
      cities: const [city],
      fieldImprovements: const [improvement],
      artifacts: [artifact],
    );

    final targets = HexSelectionTargetResolver.resolve(
      state: state,
      mapData: map,
      tile: tile,
    );

    expect(targets, [
      isA<TerrainHexSelectionTarget>(),
      isA<UnitHexSelectionTarget>(),
      isA<CityHexSelectionTarget>(),
      isA<FieldImprovementHexSelectionTarget>(),
      isA<ArtifactHexSelectionTarget>(),
      isA<ObjectiveHexSelectionTarget>(),
    ]);
    expect(targets.map((target) => target.key), [
      'terrain:0:0',
      'unit:${unit.id}',
      'city:city_1',
      'improvement:0:0',
      'artifact:${artifact.id}',
      'objective:objective_1',
    ]);
    expect(
      targets.whereType<ArtifactHexSelectionTarget>().single.icon,
      same(gameIconForArtifactType(WorldArtifactType.heroSword)),
    );
    expect(
      targets.whereType<ObjectiveHexSelectionTarget>().single.icon,
      same(GameIcons.layers),
    );
  });

  test('empty hex resolves to the mandatory terrain target only', () {
    final tile = WorldTile(
      col: 0,
      row: 0,
      terrains: const [TerrainType.grassland],
      resources: const [],
      height: 0,
    );
    final map = WorldMap(cols: 1, rows: 1, tiles: [tile]);

    final targets = HexSelectionTargetResolver.resolve(
      state: GameClientState(),
      mapData: map,
      tile: tile,
    );

    expect(targets, hasLength(1));
    expect(targets.single, isA<TerrainHexSelectionTarget>());
  });
}
