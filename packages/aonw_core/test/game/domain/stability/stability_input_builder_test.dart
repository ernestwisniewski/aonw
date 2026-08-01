import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/stability/stability_input_builder.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

void main() {
  test('forPlayer sums building, technology, luxury and artifact sources', () {
    final mapData = WorldMap(
      cols: 1,
      rows: 1,
      tiles: [
        WorldTile(
          col: 0,
          row: 0,
          terrains: [TerrainType.grassland],
          resources: [ResourceType.silk],
          height: 0,
        ),
      ],
    );
    final state = DomainState.snapshot(
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

    expect(inputs.buildingSources, 1);
    expect(inputs.techSources, 4);
    expect(inputs.luxurySources, 1);
    expect(inputs.artifactSources, 1);
  });

  test('forPlayer skips the luxury scan when includeLuxuries is false', () {
    final mapData = WorldMap(
      cols: 1,
      rows: 1,
      tiles: [
        WorldTile(
          col: 0,
          row: 0,
          terrains: [TerrainType.grassland],
          resources: [ResourceType.silk],
          height: 0,
        ),
      ],
    );
    final state = DomainState.snapshot(
      cities: [
        const GameCity(
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
