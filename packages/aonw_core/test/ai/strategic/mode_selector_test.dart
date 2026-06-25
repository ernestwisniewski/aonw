import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ModeSelector', () {
    test('belligerent civilization enters military mode earlier', () {
      const registry = CivilizationProfileRegistry();
      final mapData = _map();
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 1,
        workerCount: 1,
        settlerCount: 0,
        militaryCount: 1,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 20,
        netGoldPerTurn: 4,
        desiredCityCount: 3,
        desiredWorkerCount: 1,
        desiredMilitaryCount: 1,
      );
      final expectations = EconomyExpectations.fromAssessment(assessment);
      final threats = [
        const PlayerThreatScore(
          playerId: 'player_2',
          rival: RivalSnapshot(
            playerId: 'player_2',
            rememberedCityCount: 1,
            visibleUnitCount: 1,
            visibleMilitaryCount: 1,
            militaryPower: 1.0,
            nearestDistance: 3,
            isHostile: true,
          ),
          score: 2.3,
        ),
      ];

      final germany = const ModeSelector().select(
        assessment: assessment,
        expectations: expectations,
        threats: threats,
        context: _context(mapData, registry.profileFor(PlayerCountry.germany)),
      );
      final netherlands = const ModeSelector().select(
        assessment: assessment,
        expectations: expectations,
        threats: threats,
        context: _context(
          mapData,
          registry.profileFor(PlayerCountry.netherlands),
        ),
      );

      expect(germany, StrategicMode.military);
      expect(netherlands, isNot(StrategicMode.military));
    });

    test('active war pressure overrides consolidation needs', () {
      final mapData = _map();
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 6,
        workerCount: 2,
        settlerCount: 0,
        militaryCount: 14,
        visibleEnemyMilitaryCount: 2,
        goldReserve: 24,
        netGoldPerTurn: 1,
        desiredCityCount: 6,
        desiredWorkerCount: 6,
        desiredMilitaryCount: 6,
      );
      final mode = const ModeSelector().select(
        assessment: assessment,
        expectations: EconomyExpectations.fromAssessment(assessment),
        threats: const [
          PlayerThreatScore(
            playerId: 'player_2',
            rival: RivalSnapshot(
              playerId: 'player_2',
              rememberedCityCount: 4,
              visibleUnitCount: 2,
              visibleMilitaryCount: 2,
              militaryPower: 8,
              nearestDistance: 1,
              isHostile: true,
            ),
            score: 1.1,
          ),
        ],
        context: _context(
          mapData,
          CivilizationProfiles.all[PlayerCountry.netherlands]!,
          turn: 137,
        ),
      );

      expect(mode, StrategicMode.military);
    });

    test('does not force military mode for distant unseen hostility', () {
      final mapData = _map();
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 4,
        workerCount: 1,
        settlerCount: 0,
        militaryCount: 4,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 18,
        netGoldPerTurn: 1,
        desiredCityCount: 4,
        desiredWorkerCount: 4,
        desiredMilitaryCount: 4,
      );
      final mode = const ModeSelector().select(
        assessment: assessment,
        expectations: EconomyExpectations.fromAssessment(assessment),
        threats: const [
          PlayerThreatScore(
            playerId: 'player_2',
            rival: RivalSnapshot(
              playerId: 'player_2',
              rememberedCityCount: 0,
              visibleUnitCount: 0,
              visibleMilitaryCount: 0,
              militaryPower: 0,
              nearestDistance: 99,
              isHostile: true,
            ),
            score: 0.2,
          ),
        ],
        context: _context(mapData, CivilizationProfiles.poland, turn: 80),
      );

      expect(mode, StrategicMode.consolidate);
    });

    test('negative income forces recovery before expansion', () {
      final mapData = _map();
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 2,
        workerCount: 2,
        settlerCount: 0,
        militaryCount: 2,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 3,
        netGoldPerTurn: -1,
        desiredCityCount: 5,
        desiredWorkerCount: 2,
        desiredMilitaryCount: 2,
      );

      final mode = const ModeSelector().select(
        assessment: assessment,
        expectations: EconomyExpectations.fromAssessment(assessment),
        threats: const [],
        context: _context(mapData, CivilizationProfiles.poland),
      );

      expect(mode, StrategicMode.recover);
    });

    test('uses second-city expansion to recover from one-city debt', () {
      final mapData = _map();
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 1,
        workerCount: 1,
        settlerCount: 0,
        militaryCount: 1,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 1,
        netGoldPerTurn: 0,
        desiredCityCount: 4,
        desiredWorkerCount: 1,
        desiredMilitaryCount: 1,
      );

      final mode = const ModeSelector().select(
        assessment: assessment,
        expectations: EconomyExpectations.fromAssessment(assessment),
        threats: const [],
        context: _context(mapData, CivilizationProfiles.poland, turn: 16),
        economyHealth: const EconomyHealth(
          underperformanceStreak: 2,
          cityRatio: 0.25,
          workerRatio: 1,
          militaryRatio: 1,
          goldReserveRatio: 0.12,
          scienceRatio: 1,
          sciencePerTurn: 2,
          cityBehind: true,
          workerBehind: false,
          militaryBehind: false,
          goldBehind: true,
          scienceBehind: false,
        ),
      );

      expect(mode, StrategicMode.expand);
    });

    test('uses safe second-city expansion before first worker recovery', () {
      final mapData = _map();
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 1,
        workerCount: 0,
        settlerCount: 0,
        militaryCount: 2,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 12,
        netGoldPerTurn: 2,
        desiredCityCount: 4,
        desiredWorkerCount: 1,
        desiredMilitaryCount: 1,
      );

      final mode = const ModeSelector().select(
        assessment: assessment,
        expectations: EconomyExpectations.fromAssessment(assessment),
        threats: const [],
        context: _context(mapData, CivilizationProfiles.poland, turn: 12),
      );

      expect(mode, StrategicMode.expand);
    });

    test('uses a stable two-city opening to push the third city', () {
      final mapData = _map();
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 2,
        workerCount: 1,
        settlerCount: 0,
        militaryCount: 2,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 8,
        netGoldPerTurn: 1,
        desiredCityCount: 5,
        desiredWorkerCount: 2,
        desiredMilitaryCount: 4,
      );

      final mode = const ModeSelector().select(
        assessment: assessment,
        expectations: EconomyExpectations.fromAssessment(assessment),
        threats: const [],
        context: _context(
          mapData,
          CivilizationProfiles.all[PlayerCountry.germany]!,
          turn: 32,
        ),
      );

      expect(mode, StrategicMode.expand);
    });
  });
}

AiContext _context(
  MapData mapData,
  CivilizationProfile profile, {
  int turn = 8,
}) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: mapData,
    turn: turn,
    rng: AiRng.fromTurn(turn: turn, playerId: 'player_1', baseSeed: 1),
    civProfile: profile,
    persona: profile.defaultPersona,
  );
}

MapData _map() {
  return MapData(
    cols: 2,
    rows: 2,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 0,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}
