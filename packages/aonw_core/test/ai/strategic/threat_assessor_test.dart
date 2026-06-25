import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ThreatAssessor', () {
    test('ranks a closer equally armed rival higher', () {
      final mapData = _map(7, 7);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'own_warrior',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'near_warrior',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'far_warrior',
            ownerPlayerId: 'player_3',
            type: GameUnitType.warrior,
            col: 6,
            row: 6,
          ),
        ],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 0, row: 1)],
          ),
        ],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: _allHexesIn(mapData),
            ),
          },
        ),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 4,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 4,
        rng: AiRng.fromTurn(turn: 4, playerId: 'player_1', baseSeed: 1),
      );
      final assessment = AiEmpireAssessment.fromView(view, context);

      final scores = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      expect(scores.first.playerId, 'player_2');
      expect(scores.first.score, greaterThan(scores.last.score));
    });

    test('keeps a recently aggressive rival in threat memory', () {
      final mapData = _map(4, 4);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'own_warrior',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
        ],
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 8,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
        recentHostilePlayerIds: const {'player_2'},
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 8,
        rng: AiRng.fromTurn(turn: 8, playerId: 'player_1', baseSeed: 1),
      );
      final assessment = AiEmpireAssessment.fromView(view, context);

      final scores = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      expect(scores.single.playerId, 'player_2');
      expect(scores.single.rival.recentlyHostile, isTrue);
      expect(scores.single.rival.isHostile, isTrue);
      expect(scores.single.score, greaterThan(1.3));
    });

    test('drops stale threat memory after explicit neutral relation', () {
      final mapData = _map(4, 4);
      final diplomacy = DiplomacyState.empty.setStatus(
        'player_1',
        'player_2',
        DiplomaticRelationStatus.neutral,
      );
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'own_warrior',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
        ],
        runtimeState: GameRuntimeState(diplomacy: diplomacy),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 8,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
        recentHostilePlayerIds: const {'player_2'},
        pressureTargetPlayerIds: const {'player_2'},
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 8,
        rng: AiRng.fromTurn(turn: 8, playerId: 'player_1', baseSeed: 1),
      );
      final assessment = AiEmpireAssessment.fromView(view, context);

      final scores = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      expect(scores, isEmpty);
    });

    test('keeps current attack intent despite explicit neutral relation', () {
      final mapData = _map(4, 4);
      final diplomacy = DiplomacyState.empty.setStatus(
        'player_1',
        'player_2',
        DiplomaticRelationStatus.neutral,
      );
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'own_warrior',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'attacker',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
        ],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: _allHexesIn(mapData),
            ),
          },
        ),
        runtimeState: GameRuntimeState(diplomacy: diplomacy),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 8,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
        activeHostilePlayerIds: const {'player_2'},
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 8,
        rng: AiRng.fromTurn(turn: 8, playerId: 'player_1', baseSeed: 1),
      );
      final assessment = AiEmpireAssessment.fromView(view, context);

      final scores = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      expect(scores.single.playerId, 'player_2');
      expect(scores.single.rival.isHostile, isTrue);
      expect(scores.single.rival.recentlyHostile, isFalse);
    });

    test('treats active diplomatic war as hostile threat context', () {
      final mapData = _map(6, 6);
      final diplomacy = DiplomacyState.empty.setStatus(
        'player_1',
        'player_2',
        DiplomaticRelationStatus.war,
      );
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'own_warrior',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
          GameCity(
            id: 'enemy_city',
            ownerPlayerId: 'player_2',
            name: 'Enemy City',
            center: CityHex(col: 5, row: 5),
          ),
        ],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: _allHexesIn(mapData),
            ),
          },
        ),
        runtimeState: GameRuntimeState(diplomacy: diplomacy),
      );
      final view = GameView.fromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 10,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: mapData,
        turn: 10,
        rng: AiRng.fromTurn(turn: 10, playerId: 'player_1', baseSeed: 1),
      );
      final assessment = AiEmpireAssessment.fromView(view, context);

      final scores = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      expect(scores.single.playerId, 'player_2');
      expect(scores.single.rival.isHostile, isTrue);
      expect(scores.single.rival.recentlyHostile, isFalse);
      expect(scores.single.score, greaterThan(0.6));
    });

    test('adds strategic pressure for a runaway score leader', () {
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 2,
        workerCount: 2,
        settlerCount: 0,
        militaryCount: 2,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 10,
        netGoldPerTurn: 1,
        desiredCityCount: 3,
        desiredWorkerCount: 2,
        desiredMilitaryCount: 2,
      );
      final scoreRace = ScoreRaceAnalysis(
        playerId: 'player_1',
        player: _score('player_1', totalCityScore: 80),
        leader: _score('player_2', totalCityScore: 160),
        runnerUp: _score('player_1', totalCityScore: 80),
        turn: 54,
        turnLimit: 60,
        remainingTurns: 6,
        pressureWindowTurns: 9,
      );

      final scores = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: const [
          RivalSnapshot(
            playerId: 'player_2',
            rememberedCityCount: 0,
            visibleUnitCount: 0,
            visibleMilitaryCount: 0,
            militaryPower: 0,
            nearestDistance: 99,
            isHostile: false,
          ),
          RivalSnapshot(
            playerId: 'player_3',
            rememberedCityCount: 1,
            visibleUnitCount: 0,
            visibleMilitaryCount: 0,
            militaryPower: 0,
            nearestDistance: 8,
            isHostile: false,
          ),
        ],
        scoreRace: scoreRace,
      );

      expect(scores.first.playerId, 'player_2');
      expect(scores.first.score, greaterThan(scores.last.score));
    });
  });
}

EmpireScoreBreakdown _score(String playerId, {required int totalCityScore}) {
  return EmpireScoreBreakdown(
    playerId: playerId,
    cityScore: totalCityScore,
    populationScore: 0,
    territoryScore: 0,
    buildingScore: 0,
    unitScore: 0,
    technologyScore: 0,
    improvementScore: 0,
    goldScore: 0,
  );
}

MapData _map(int cols, int rows) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
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

Set<HexCoordinate> _allHexesIn(MapData mapData) {
  return {
    for (final tile in mapData.tiles)
      HexCoordinate(col: tile.col, row: tile.row),
  };
}
