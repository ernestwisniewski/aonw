import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/city/city_turn_science.dart';
import 'package:aonw_core/game/domain/technology/science_yield.dart';
import 'package:test/test.dart';

void main() {
  test('combines artifact science with existing city science', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
    );
    const artifact = WorldArtifact(
      id: 'artifact_1',
      type: WorldArtifactType.astronomersTablets,
      location: WorldArtifactLocation.stored(cityId: 'city_1'),
    );
    final artifactScience = CityTurnScience.artifactFor(city, const [artifact]);
    const baseScience = ScienceYieldBreakdown(
      total: 2,
      byCityId: {'city_1': 2},
      sources: [
        ScienceYieldSource(
          cityId: 'city_1',
          amount: 2,
          label: ScienceYieldSourceLabels.cityScience,
        ),
      ],
    );

    final combined = CityTurnScience.combine(baseScience, artifactScience);

    expect(artifactScience.total, 1);
    expect(artifactScience.byCityId, {'city_1': 1});
    expect(
      artifactScience.sources.single.label,
      ScienceYieldSourceLabels.worldArtifact,
    );
    expect(combined.total, 3);
    expect(combined.byCityId, {'city_1': 3});
    expect(combined.sources, hasLength(2));
  });
}
