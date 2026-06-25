import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('DefensiveStancePlanner', () {
    test('assigns the nearest military unit to a threatened city', () {
      final mapData = _openMap(cols: 9, rows: 3);
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'home_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          _unit(
            id: 'far_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 8,
            row: 1,
          ),
          _unit(
            id: 'enemy_1',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 3,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 1, row: 1),
          ),
          GameCity(
            id: 'remote',
            ownerPlayerId: 'player_1',
            name: 'Remote',
            center: CityHex(col: 8, row: 1),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final plan = const DefensiveStancePlanner(threatRange: 3).compute(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.consolidate,
      );

      expect(plan.defenses.keys, {'capital', 'remote'});
      final defense = plan.defenses['capital']!;
      expect(defense.primaryThreatPlayerId, 'player_2');
      expect(defense.threatLevel, greaterThan(0));
      expect(defense.assignedUnitIds, const ['home_guard']);
      expect(plan.defenses['remote']!.threatLevel, 0);
      expect(plan.defenses['remote']!.assignedUnitIds, const ['far_guard']);
    });

    test('caps low-risk garrisons during offensive military pressure', () {
      final mapData = _openMap(cols: 9, rows: 3);
      final state = PersistentGameState(
        units: [
          for (var index = 0; index < 8; index++)
            _unit(
              id: 'guard_$index',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: index,
              row: 0,
            ),
          _unit(
            id: 'enemy_1',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 4,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'City 1',
            center: CityHex(col: 1, row: 1),
          ),
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_1',
            name: 'City 2',
            center: CityHex(col: 3, row: 1),
          ),
          GameCity(
            id: 'city_3',
            ownerPlayerId: 'player_1',
            name: 'City 3',
            center: CityHex(col: 5, row: 1),
          ),
          GameCity(
            id: 'city_4',
            ownerPlayerId: 'player_1',
            name: 'City 4',
            center: CityHex(col: 7, row: 1),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(
        state,
        mapData,
        pressureTargetPlayerIds: const ['player_2'],
      );
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final plan = const DefensiveStancePlanner(threatRange: 5).compute(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.military,
      );
      final assignedDefenders = [
        for (final defense in plan.defenses.values) ...defense.assignedUnitIds,
      ];

      expect(plan.defenses.length, lessThan(4));
      expect(assignedDefenders.length, lessThanOrEqualTo(2));
      expect(assignedDefenders, isNotEmpty);
    });

    test('caps wartime garrisons even when mode is still consolidating', () {
      final mapData = _openMap(cols: 12, rows: 4);
      final state = PersistentGameState(
        units: [
          for (var index = 0; index < 14; index++)
            _unit(
              id: 'guard_$index',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: index % 12,
              row: index ~/ 12,
            ),
          for (var index = 0; index < 2; index++)
            _unit(
              id: 'enemy_$index',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 5 + index,
              row: 3,
            ),
        ],
        cities: [
          for (var index = 0; index < 6; index++)
            GameCity(
              id: 'city_$index',
              ownerPlayerId: 'player_1',
              name: 'City $index',
              center: CityHex(col: index * 2, row: 2),
            ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(
        state,
        mapData,
        pressureTargetPlayerIds: const ['player_2'],
      );
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final plan = const DefensiveStancePlanner(threatRange: 5).compute(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.consolidate,
      );
      final assignedDefenders = {
        for (final defense in plan.defenses.values) ...defense.assignedUnitIds,
      };

      expect(assignedDefenders.length, lessThanOrEqualTo(2));
      expect(14 - assignedDefenders.length, greaterThanOrEqualTo(12));
    });

    test('leaves most of a mature wartime army free for offense', () {
      final mapData = _openMap(cols: 14, rows: 4);
      final state = PersistentGameState(
        units: [
          for (var index = 0; index < 13; index++)
            _unit(
              id: 'guard_$index',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: index,
              row: 0,
            ),
          for (var index = 0; index < 8; index++)
            _unit(
              id: 'enemy_$index',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: index + 3,
              row: 2,
            ),
        ],
        cities: [
          for (var index = 0; index < 6; index++)
            GameCity(
              id: 'city_$index',
              ownerPlayerId: 'player_1',
              name: 'City $index',
              center: CityHex(col: index * 2 + 1, row: 1),
            ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(
        state,
        mapData,
        pressureTargetPlayerIds: const ['player_2'],
      );
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final plan = const DefensiveStancePlanner(threatRange: 5).compute(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.military,
      );
      final assignedDefenders = {
        for (final defense in plan.defenses.values) ...defense.assignedUnitIds,
      };

      expect(assignedDefenders.length, lessThanOrEqualTo(3));
      expect(13 - assignedDefenders.length, greaterThanOrEqualTo(10));
    });

    test('keeps a defense entry when no garrison is available', () {
      final mapData = _openMap(cols: 5, rows: 3);
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'enemy_1',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 3,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 1, row: 1),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final plan = const DefensiveStancePlanner(threatRange: 3).compute(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.consolidate,
      );

      expect(plan.defenses.keys, {'capital'});
      expect(plan.defenses['capital']!.assignedUnitIds, isEmpty);
    });

    test('reserves a baseline garrison for a lone early city', () {
      final mapData = _openMap(cols: 5, rows: 3);
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'home_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 3,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 1, row: 1),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const DefensiveStancePlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
        threats: const [],
        mode: StrategicMode.consolidate,
      );

      expect(plan.defenses.keys, {'capital'});
      expect(plan.defenses['capital']!.threatLevel, 0);
      expect(plan.defenses['capital']!.assignedUnitIds, const ['home_guard']);
    });

    test('reserves baseline garrisons for a fragile two-city opening', () {
      final mapData = _openMap(cols: 8, rows: 3);
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'capital_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          _unit(
            id: 'frontier_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 7,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 1, row: 1),
          ),
          GameCity(
            id: 'frontier',
            ownerPlayerId: 'player_1',
            name: 'Frontier',
            center: CityHex(col: 7, row: 1),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(
        mapData,
        profile: CivilizationProfiles.all[PlayerCountry.netherlands]!,
      );
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const DefensiveStancePlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
        threats: const [],
        mode: StrategicMode.expand,
      );

      expect(plan.defenses.keys, {'capital', 'frontier'});
      expect(plan.defenses['capital']!.assignedUnitIds, const [
        'capital_guard',
      ]);
      expect(plan.defenses['frontier']!.assignedUnitIds, const [
        'frontier_guard',
      ]);
    });

    test('keeps scouts free when regular garrisons are available', () {
      final mapData = _openMap(cols: 8, rows: 3);
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'near_scout',
            ownerPlayerId: 'player_1',
            type: GameUnitType.scout,
            col: 1,
            row: 1,
          ),
          _unit(
            id: 'capital_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 4,
            row: 1,
          ),
          _unit(
            id: 'frontier_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 7,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 1, row: 1),
          ),
          GameCity(
            id: 'frontier',
            ownerPlayerId: 'player_1',
            name: 'Frontier',
            center: CityHex(col: 7, row: 1),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(
        mapData,
        profile: CivilizationProfiles.all[PlayerCountry.netherlands]!,
      );
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const DefensiveStancePlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
        threats: const [],
        mode: StrategicMode.expand,
      );

      expect(plan.defenses['capital']!.assignedUnitIds, const [
        'capital_guard',
      ]);
      expect(plan.defenses['frontier']!.assignedUnitIds, const [
        'frontier_guard',
      ]);
      expect(
        plan.defenses.values.expand((defense) => defense.assignedUnitIds),
        isNot(contains('near_scout')),
      );
    });

    test('marks an ungarrisoned second city as needing defense production', () {
      final mapData = _openMap(cols: 8, rows: 3);
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'capital_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 1, row: 1),
          ),
          GameCity(
            id: 'frontier',
            ownerPlayerId: 'player_1',
            name: 'Frontier',
            center: CityHex(col: 7, row: 1),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(
        mapData,
        profile: CivilizationProfiles.all[PlayerCountry.netherlands]!,
      );
      final assessment = AiEmpireAssessment.fromView(view, context);

      final plan = const DefensiveStancePlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
        threats: const [],
        mode: StrategicMode.expand,
      );

      expect(plan.defenses.keys, {'capital', 'frontier'});
      expect(plan.defenses['capital']!.assignedUnitIds, const [
        'capital_guard',
      ]);
      expect(plan.defenses['frontier']!.assignedUnitIds, isEmpty);
    });

    test(
      'garrisons a city after a recent attack even without visible enemies',
      () {
        final mapData = _openMap(cols: 7, rows: 3);
        final state = PersistentGameState(
          units: [
            _unit(
              id: 'home_guard',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 1,
            ),
            _unit(
              id: 'remote_guard',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 6,
              row: 1,
            ),
          ],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 1, row: 1),
            ),
            GameCity(
              id: 'remote',
              ownerPlayerId: 'player_1',
              name: 'Remote',
              center: CityHex(col: 6, row: 1),
            ),
          ],
          fogOfWar: _fog(mapData),
        );
        final view = _view(
          state,
          mapData,
          recentHostilePlayerIds: const {'player_2'},
        );
        final context = _context(mapData);
        final assessment = AiEmpireAssessment.fromView(view, context);
        final threats = const ThreatAssessor().assess(
          assessment: assessment,
          rivals: RivalSnapshot.fromView(view),
        );

        final plan = const DefensiveStancePlanner().compute(
          view: view,
          context: context,
          assessment: assessment,
          threats: threats,
          mode: StrategicMode.consolidate,
        );

        expect(plan.defenses.keys, {'capital', 'remote'});
        expect(plan.defenses['capital']!.primaryThreatPlayerId, 'player_2');
        expect(plan.defenses['capital']!.assignedUnitIds, const ['home_guard']);
        expect(plan.defenses['capital']!.threatLevel, greaterThan(0));
        expect(plan.defenses['remote']!.assignedUnitIds, const [
          'remote_guard',
        ]);
      },
    );

    test('treats a pending city attack as an urgent defense assignment', () {
      final mapData = _openMap(cols: 6, rows: 3);
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'home_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          _unit(
            id: 'reserve_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 2,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 1, row: 1),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(
        state,
        mapData,
        pendingCityAttackThreats: const [
          PendingCityAttackThreat(
            attackerPlayerId: 'player_2',
            attackerUnitId: 'enemy_attacker',
            attackerHex: HexCoordinate(col: 3, row: 1),
            cityId: 'capital',
            cityCenter: CityHex(col: 1, row: 1),
          ),
        ],
      );
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final plan = const DefensiveStancePlanner().compute(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.consolidate,
      );

      final defense = plan.defenses['capital']!;
      expect(defense.primaryThreatPlayerId, 'player_2');
      expect(defense.threatLevel, greaterThanOrEqualTo(24));
      expect(defense.assignedUnitIds, const ['home_guard', 'reserve_guard']);
    });

    test('StrategicPlanner publishes defensive stances', () {
      final mapData = _openMap(cols: 5, rows: 3);
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'home_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          _unit(
            id: 'enemy_1',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 3,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 1, row: 1),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(mapData);

      final plan = const StrategicPlanner().build(view: view, context: context);

      expect(plan.defenses, contains('capital'));
      expect(plan.defenses['capital']?.assignedUnitIds, const ['home_guard']);
    });

    test('StrategicPlanner keeps defensive garrisons out of war goals', () {
      final mapData = _openMap(cols: 7, rows: 3);
      final state = PersistentGameState(
        units: [
          _unit(
            id: 'home_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          _unit(
            id: 'raider',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 5,
            row: 2,
          ),
          _unit(
            id: 'enemy_1',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 5,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 1, row: 1),
          ),
          GameCity(
            id: 'enemy_city',
            ownerPlayerId: 'player_2',
            name: 'Enemy City',
            center: CityHex(col: 6, row: 1),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(state, mapData);
      final context = _context(
        mapData,
        profile: CivilizationProfiles.all[PlayerCountry.germany]!,
      );

      final plan = const StrategicPlanner().build(view: view, context: context);
      final assignedDefenders = plan.defenses['capital']!.assignedUnitIds;
      final assignedAttackers = {
        for (final goal in plan.warGoals) ...goal.assignedUnitIds,
      };

      expect(assignedDefenders, const ['home_guard']);
      expect(plan.warGoals, isNotEmpty);
      expect(assignedAttackers, isNot(contains('home_guard')));
      expect(assignedAttackers, contains('raider'));
    });
  });
}

GameView _view(
  PersistentGameState state,
  MapData mapData, {
  Iterable<String> recentHostilePlayerIds = const [],
  Iterable<String> pressureTargetPlayerIds = const [],
  Iterable<PendingCityAttackThreat> pendingCityAttackThreats = const [],
}) {
  return GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 4,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
    recentHostilePlayerIds: recentHostilePlayerIds,
    pressureTargetPlayerIds: pressureTargetPlayerIds,
    pendingCityAttackThreats: pendingCityAttackThreats,
  );
}

AiContext _context(
  MapData mapData, {
  CivilizationProfile profile = CivilizationProfiles.poland,
}) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: mapData,
    turn: 4,
    rng: AiRng.fromTurn(turn: 4, playerId: 'player_1', baseSeed: 17),
    persona: profile.defaultPersona,
    civProfile: profile,
  );
}

GameUnit _unit({
  required String id,
  required String ownerPlayerId,
  required GameUnitType type,
  required int col,
  required int row,
}) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    col: col,
    row: row,
  );
}

FogOfWarState _fog(MapData mapData) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        visibleHexes: {
          for (final tile in mapData.tiles)
            HexCoordinate(col: tile.col, row: tile.row),
        },
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
