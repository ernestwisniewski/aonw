import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CitySitePlanner', () {
    test('populates ranking and assigns settlers to distinct slots', () {
      final mapData = _openMap(cols: 7, rows: 5);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_west',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 1,
            row: 2,
          ),
          GameUnit.produced(
            id: 'settler_east',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 5,
            row: 2,
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const CitySitePlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
      );

      expect(plan.candidates, isNotEmpty);
      expect(plan.candidates.length, lessThanOrEqualTo(10));
      expect(plan.settlerAssignments.keys, {'settler_east', 'settler_west'});
      expect(
        plan.settlerAssignments['settler_east'],
        isNot(plan.settlerAssignments['settler_west']),
      );
    });

    test('greedy ranking pushes second site away from first', () {
      final mapData = _openMap(cols: 8, rows: 5);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 0,
            row: 1,
          ),
          GameUnit.produced(
            id: 'settler_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 2,
            row: 2,
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(
        mapData,
        civProfile: const CivilizationProfileRegistry().profileFor(
          PlayerCountry.spain,
        ),
      );
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const CitySitePlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
        maxCandidates: 2,
      );

      expect(plan.candidates, hasLength(2));
      final distance = HexDistance.between(
        HexCoordinate(
          col: plan.candidates[0].center.col,
          row: plan.candidates[0].center.row,
        ),
        HexCoordinate(
          col: plan.candidates[1].center.col,
          row: plan.candidates[1].center.row,
        ),
      );
      expect(distance, greaterThanOrEqualTo(4));
    });

    test('does not rank city centers too close to existing cities', () {
      final mapData = _openMap(cols: 5, rows: 5);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 2,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 2, row: 2),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const CitySitePlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
      );

      expect(plan.candidates, isNotEmpty);
      for (final candidate in plan.candidates) {
        final distance = HexDistance.between(
          HexCoordinate(col: candidate.center.col, row: candidate.center.row),
          const HexCoordinate(col: 2, row: 2),
        );
        expect(distance, greaterThanOrEqualTo(3));
      }
      expect(
        plan.settlerAssignments['settler_1'],
        isNot(const CityHex(col: 2, row: 1)),
      );
    });

    test('assigns settlers by site utility instead of nearest slot only', () {
      final mapData = _openMap(cols: 7, rows: 3);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 1,
            row: 1,
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = CitySitePlanner(
        siteScorer: _ScriptedSiteScorer({
          const CityHex(col: 2, row: 1): 10,
          const CityHex(col: 4, row: 1): 12,
        }),
      ).compute(view: view, context: context, assessment: assessment);

      expect(
        plan.settlerAssignments['settler_1'],
        const CityHex(col: 4, row: 1),
      );
    });

    test('does not chase a marginally better distant third-city slot', () {
      final mapData = _openMap(cols: 10, rows: 5);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 3,
            row: 2,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
          GameCity(
            id: 'second',
            ownerPlayerId: 'player_1',
            name: 'Second',
            center: CityHex(col: 7, row: 4),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = CitySitePlanner(
        siteScorer: _ScriptedSiteScorer({
          const CityHex(col: 4, row: 2): 10,
          const CityHex(col: 8, row: 2): 12,
        }),
      ).compute(view: view, context: context, assessment: assessment);

      expect(
        plan.settlerAssignments['settler_1'],
        const CityHex(col: 4, row: 2),
      );
    });

    test('assigns partially discovered sites so settlers can reveal them', () {
      final mapData = _openMap(cols: 7, rows: 7);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 3,
            row: 3,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
        ],
        fogOfWar: _fogForHexes({
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 3, row: 3),
          const HexCoordinate(col: 3, row: 2),
          const HexCoordinate(col: 3, row: 4),
          const HexCoordinate(col: 2, row: 3),
          const HexCoordinate(col: 4, row: 3),
          const HexCoordinate(col: 2, row: 2),
          const HexCoordinate(col: 4, row: 4),
        }),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const CitySitePlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
      );

      expect(plan.candidates, isNotEmpty);
      expect(plan.settlerAssignments, contains('settler_1'));
    });

    test('uses strategic map knowledge for undiscovered city sites', () {
      final mapData = _openMap(cols: 8, rows: 5);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 1,
            row: 2,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
        ],
        fogOfWar: _fogForHexes({
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 0, row: 1),
        }),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const CitySitePlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
      );

      final assigned = plan.settlerAssignments['settler_1'];
      expect(assigned, isNotNull);
      expect({
        const CityHex(col: 0, row: 0),
        const CityHex(col: 0, row: 1),
      }, isNot(contains(assigned)));
    });

    test(
      'prioritizes city sites that claim missing revealed strategic resources',
      () {
        final oilScore = _scoreStrategicResourceTestSite(
          center: const CityHex(col: 3, row: 2),
        );
        final hillScore = _scoreStrategicResourceTestSite(
          center: const CityHex(col: 1, row: 2),
        );

        expect(oilScore, greaterThan(hillScore));
      },
    );

    test('does not add missing-resource pressure for active imports', () {
      final missingOilScore = _scoreStrategicResourceTestSite(
        center: const CityHex(col: 3, row: 2),
      );
      final importedOilScore = _scoreStrategicResourceTestSite(
        center: const CityHex(col: 3, row: 2),
        runtimeState: const GameRuntimeState(
          resourceTradeAgreements: [
            ResourceTradeAgreement(
              id: 'oil_import',
              exporterPlayerId: 'player_2',
              importerPlayerId: 'player_1',
              resource: ResourceType.oil,
              goldPerTurn: 2,
              remainingTurns: 5,
            ),
          ],
        ),
      );

      expect(importedOilScore, lessThan(missingOilScore));
    });

    test('assigns known sites outside the current visible corridor', () {
      final mapData = _openMap(cols: 8, rows: 5);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 1,
            row: 2,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
          GameCity(
            id: 'second',
            ownerPlayerId: 'player_1',
            name: 'Second',
            center: CityHex(col: 4, row: 4),
          ),
        ],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              discoveredHexes: {
                for (final tile in mapData.tiles)
                  HexCoordinate(col: tile.col, row: tile.row),
              },
              visibleHexes: {
                const HexCoordinate(col: 0, row: 0),
                const HexCoordinate(col: 1, row: 2),
                const HexCoordinate(col: 1, row: 1),
                const HexCoordinate(col: 1, row: 3),
              },
            ),
          },
        ),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const CitySitePlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
      );

      expect(plan.candidates, isNotEmpty);
      expect(plan.settlerAssignments, contains('settler_1'));
    });
  });
}

GameView _view(PersistentGameState state, MapData mapData) {
  return GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

AiContext _context(
  MapData mapData, {
  CivilizationProfile civProfile = CivilizationProfiles.poland,
}) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: mapData,
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
    civProfile: civProfile,
  );
}

double _scoreStrategicResourceTestSite({
  required CityHex center,
  GameRuntimeState runtimeState = GameRuntimeState.empty,
}) {
  final mapData = _strategicResourceMap();
  final founder = GameUnit.produced(
    id: 'settler_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.settler,
    col: 2,
    row: 2,
  );
  final state = PersistentGameState(
    units: [founder],
    runtimeState: runtimeState,
    research: ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.combustion},
        ),
      },
    ),
    fogOfWar: _fog(mapData),
  );
  final view = _view(state, mapData);
  final context = _context(mapData);
  final assessment = AiEmpireAssessment.fromView(view, context);
  final score = const AiCitySiteScorer().scoreSite(
    founder: founder,
    center: center,
    view: view,
    context: context,
    assessment: assessment,
    knownCities: view.ownCities,
    reservedHexes: const {},
    requireKnownExclusionZone: false,
  );
  return score!.score;
}

FogOfWarState _fog(MapData mapData) {
  return _fogForHexes({
    for (final tile in mapData.tiles)
      HexCoordinate(col: tile.col, row: tile.row),
  });
}

FogOfWarState _fogForHexes(Set<HexCoordinate> visibleHexes) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        visibleHexes: visibleHexes,
      ),
    },
  );
}

MapData _openMap({required int cols, required int rows}) {
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

MapData _strategicResourceMap() {
  return MapData(
    cols: 5,
    rows: 5,
    tiles: [
      for (var row = 0; row < 5; row++)
        for (var col = 0; col < 5; col++)
          TileData(
            col: col,
            row: row,
            terrains: col == 1 && row == 2
                ? const [TerrainType.hills]
                : const [TerrainType.plains],
            resources: col == 3 && row == 2
                ? const [ResourceType.oil]
                : const [],
            height: 0,
          ),
    ],
  );
}

class _ScriptedSiteScorer extends AiCitySiteScorer {
  _ScriptedSiteScorer(this.scores);

  final Map<CityHex, double> scores;

  @override
  AiCitySiteScore? scoreSite({
    required GameUnit founder,
    required CityHex center,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required Iterable<GameCity> knownCities,
    required Set<CityHex> reservedHexes,
    bool requireKnownExclusionZone = true,
    bool useStrategicMapKnowledge = false,
  }) {
    final score = scores[center];
    if (score == null) return null;
    return AiCitySiteScore(
      center: center,
      controlledHexes:
          HexNeighbors.existingAround(
                HexCoordinate(col: center.col, row: center.row),
                view.mapData,
              )
              .take(CityFoundingDraft.requiredControlledHexes)
              .map((hex) => CityHex(col: hex.col, row: hex.row)),
      score: score,
      distanceFromFounder: HexDistance.between(
        HexCoordinate(col: founder.col, row: founder.row),
        HexCoordinate(col: center.col, row: center.row),
      ),
      hasKnownExclusionZone: true,
    );
  }
}
