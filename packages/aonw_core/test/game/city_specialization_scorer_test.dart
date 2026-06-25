import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CitySpecializationScorer', () {
    test('scores coastal cities toward commerce', () {
      const city = GameCity(
        id: 'coast_city',
        ownerPlayerId: 'player_1',
        name: 'Coast',
        center: CityHex(col: 0, row: 0),
      );

      final bestFit = CitySpecializationScorer.bestLocalFit(
        city: city,
        mapData: _map(const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.coast],
            resources: [],
            height: 0,
          ),
        ]),
        research: ResearchState.empty,
      );

      expect(bestFit, CitySpecializationType.commerce);
    });

    test('ignores strategic resources until their reveal technology', () {
      const city = GameCity(
        id: 'oil_city',
        ownerPlayerId: 'player_1',
        name: 'Oil',
        center: CityHex(col: 0, row: 0),
      );
      final mapData = _map(const [
        TileData(
          col: 0,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [ResourceType.oil],
          height: 0,
        ),
      ]);

      final hiddenScores = CitySpecializationScorer.localScores(
        city: city,
        mapData: mapData,
        research: ResearchState.empty,
      );
      final revealedScores = CitySpecializationScorer.localScores(
        city: city,
        mapData: mapData,
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.combustion},
            ),
          },
        ),
      );

      expect(hiddenScores, isEmpty);
      expect(
        revealedScores[CitySpecializationType.military],
        greaterThan(revealedScores[CitySpecializationType.industry]!),
      );
    });
  });
}

MapData _map(List<TileData> tiles) {
  return MapData(cols: 1, rows: 1, tiles: tiles);
}
