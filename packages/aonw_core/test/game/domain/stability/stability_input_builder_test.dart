import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/stability/stability_input_builder.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

void main() {
  test('forPlayer sums building, technology, luxury and artifact sources', () {
    final mapData = MapData(
      cols: 1,
      rows: 1,
      tiles: const [
        TileData(
          col: 0,
          row: 0,
          terrains: [TerrainType.grassland],
          resources: [ResourceType.silk],
          height: 0,
        ),
      ],
    );
    final state = PersistentGameState(
      cities: const [
        GameCity(
          id: 'city-a',
          ownerPlayerId: 'a',
          name: 'A',
          center: CityHex(col: 0, row: 0),
          buildings: {CityBuildingType.townHall},
        ),
      ],
      artifacts: const [
        WorldArtifact(
          id: 'art-a',
          type: WorldArtifactType.heroSword,
          location: WorldArtifactLocation.stored(cityId: 'city-a'),
        ),
      ],
      research: ResearchState(
        players: {
          'a': PlayerResearchState(
            unlockedTechnologyIds: {
              TechnologyId.law,
              TechnologyId.civilService,
            },
          ),
        },
      ),
    );

    final inputs = StabilityInputBuilder.forPlayer(
      state: state,
      playerId: 'a',
      mapData: mapData,
    );

    // standard ruleset: +1 per order building, +2 per order tech, +1 per unique
    // luxury, +1 per stored artifact.
    expect(inputs.buildingSources, 1);
    expect(inputs.techSources, 4);
    expect(inputs.luxurySources, 1);
    expect(inputs.artifactSources, 1);
  });

  test('forPlayer skips the luxury scan when includeLuxuries is false', () {
    final mapData = MapData(
      cols: 1,
      rows: 1,
      tiles: const [
        TileData(
          col: 0,
          row: 0,
          terrains: [TerrainType.grassland],
          resources: [ResourceType.silk],
          height: 0,
        ),
      ],
    );
    const state = PersistentGameState(
      cities: [
        GameCity(
          id: 'city-a',
          ownerPlayerId: 'a',
          name: 'A',
          center: CityHex(col: 0, row: 0),
        ),
      ],
    );

    final inputs = StabilityInputBuilder.forPlayer(
      state: state,
      playerId: 'a',
      mapData: mapData,
      includeLuxuries: false,
    );

    expect(inputs.luxurySources, 0);
  });
}
