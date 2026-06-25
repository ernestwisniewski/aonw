import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WarGoal', () {
    test('supports copyWith and value equality', () {
      final goal = WarGoal(
        targetPlayerId: 'player_2',
        kind: WarGoalKind.captureCity,
        targetCity: const CityHex(col: 4, row: 1),
        targetHex: const HexCoordinate(col: 4, row: 1),
        turnsBudget: 6,
        assignedUnitIds: const ['warrior_1'],
        priority: 3.5,
      );

      final same = goal.copyWith();
      final updated = goal.copyWith(
        kind: WarGoalKind.harass,
        assignedUnitIds: const ['warrior_1', 'archer_1'],
      );

      expect(same, goal);
      expect(updated.kind, WarGoalKind.harass);
      expect(updated.assignedUnitIds, const ['warrior_1', 'archer_1']);
      expect(updated.targetCity, goal.targetCity);
    });
  });

  group('TargetabilityScorer', () {
    test('prefers weaker and closer rivals', () {
      final assessment = _assessment(militaryCount: 3);
      final scores = const TargetabilityScorer().rank(
        assessment: assessment,
        rivals: const [
          RivalSnapshot(
            playerId: 'strong_far',
            rememberedCityCount: 1,
            visibleUnitCount: 3,
            visibleMilitaryCount: 3,
            militaryPower: 18,
            nearestDistance: 8,
            isHostile: false,
          ),
          RivalSnapshot(
            playerId: 'weak_close',
            rememberedCityCount: 1,
            visibleUnitCount: 1,
            visibleMilitaryCount: 1,
            militaryPower: 4,
            nearestDistance: 3,
            isHostile: false,
          ),
        ],
        context: _context(
          _openMap(cols: 2, rows: 2),
          CivilizationProfiles.poland,
        ),
      );

      expect(scores.first.playerId, 'weak_close');
    });

    test('boosts priority targets in target ranking', () {
      final assessment = _assessment(militaryCount: 3);
      final scores = const TargetabilityScorer().rank(
        assessment: assessment,
        rivals: const [
          RivalSnapshot(
            playerId: 'human',
            rememberedCityCount: 1,
            visibleUnitCount: 1,
            visibleMilitaryCount: 1,
            militaryPower: 4,
            nearestDistance: 4,
            isHostile: false,
          ),
          RivalSnapshot(
            playerId: 'other_ai',
            rememberedCityCount: 1,
            visibleUnitCount: 1,
            visibleMilitaryCount: 1,
            militaryPower: 4,
            nearestDistance: 4,
            isHostile: false,
          ),
        ],
        context: _context(
          _openMap(cols: 2, rows: 2),
          CivilizationProfiles.poland,
        ),
        priorityTargetPlayerIds: const {'human'},
      );

      expect(scores.first.playerId, 'human');
      expect(scores.first.priorityTarget, isTrue);
      expect(scores.last.priorityTarget, isFalse);
    });

    test('civilization belligerence scales targetability', () {
      final mapData = _openMap(cols: 2, rows: 2);
      const rival = RivalSnapshot(
        playerId: 'target',
        rememberedCityCount: 1,
        visibleUnitCount: 1,
        visibleMilitaryCount: 1,
        militaryPower: 4,
        nearestDistance: 3,
        isHostile: false,
      );

      final germanScore = const TargetabilityScorer()
          .rank(
            assessment: _assessment(militaryCount: 2),
            rivals: const [rival],
            context: _context(
              mapData,
              CivilizationProfiles.all[PlayerCountry.germany]!,
            ),
          )
          .single
          .score;
      final canadianScore = const TargetabilityScorer()
          .rank(
            assessment: _assessment(militaryCount: 2),
            rivals: const [rival],
            context: _context(
              mapData,
              CivilizationProfiles.all[PlayerCountry.canada]!,
            ),
          )
          .single
          .score;

      expect(germanScore, greaterThan(canadianScore));
    });
  });

  group('WarGoalGenerator', () {
    test(
      'creates an opportunistic capture goal for an aggressive civilization',
      () {
        final mapData = _openMap(cols: 6, rows: 2);
        final state = _warGoalState(mapData);
        final view = _view(state, mapData);
        final context = _context(
          mapData,
          CivilizationProfiles.all[PlayerCountry.germany]!,
        );
        final assessment = _postOpeningAssessment(militaryCount: 2);
        final threats = const ThreatAssessor().assess(
          assessment: assessment,
          rivals: RivalSnapshot.fromView(view),
        );

        final goals = const WarGoalGenerator().generate(
          view: view,
          context: context,
          assessment: assessment,
          threats: threats,
          mode: StrategicMode.consolidate,
        );

        expect(goals, hasLength(1));
        expect(goals.single.targetPlayerId, 'player_2');
        expect(goals.single.kind, WarGoalKind.captureCity);
        expect(goals.single.targetCity, const CityHex(col: 5, row: 0));
        expect(goals.single.assignedUnitIds, contains('warrior_1'));
      },
    );

    test('easy avoids opportunistic war that veryHard still accepts', () {
      final mapData = _openMap(cols: 6, rows: 2);
      final state = _warGoalState(mapData);
      final view = _view(state, mapData);
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
      final assessment = _postOpeningAssessment(militaryCount: 2);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final easyGoals = const WarGoalGenerator().generate(
        view: view,
        context: _context(mapData, profile, difficulty: AiDifficulty.easy),
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.consolidate,
      );
      final veryHardGoals = const WarGoalGenerator().generate(
        view: view,
        context: _context(mapData, profile, difficulty: AiDifficulty.veryHard),
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.consolidate,
      );

      expect(easyGoals, isEmpty);
      expect(veryHardGoals, hasLength(1));
      expect(veryHardGoals.single.kind, WarGoalKind.captureCity);
    });

    test(
      'delays opportunistic capture while still building the third city',
      () {
        final mapData = _openMap(cols: 6, rows: 2);
        final state = _warGoalState(mapData);
        final view = _view(state, mapData);
        final context = _context(
          mapData,
          CivilizationProfiles.all[PlayerCountry.germany]!,
        );
        final assessment = AiEmpireAssessment.fromView(view, context);
        final threats = const ThreatAssessor().assess(
          assessment: assessment,
          rivals: RivalSnapshot.fromView(view),
        );

        final goals = const WarGoalGenerator().generate(
          view: view,
          context: context,
          assessment: assessment,
          threats: threats,
          mode: StrategicMode.consolidate,
        );

        expect(goals, isEmpty);
      },
    );

    test(
      'does not open the same opportunistic goal for a peaceful civilization',
      () {
        final mapData = _openMap(cols: 6, rows: 2);
        final state = _warGoalState(mapData);
        final view = _view(state, mapData);
        final context = _context(
          mapData,
          CivilizationProfiles.all[PlayerCountry.canada]!,
        );
        final assessment = _postOpeningAssessment(militaryCount: 2);
        final threats = const ThreatAssessor().assess(
          assessment: assessment,
          rivals: RivalSnapshot.fromView(view),
        );

        final goals = const WarGoalGenerator().generate(
          view: view,
          context: context,
          assessment: assessment,
          threats: threats,
          mode: StrategicMode.consolidate,
        );

        expect(goals, isEmpty);
      },
    );

    test('pressures a priority target once the army can support conquest', () {
      final mapData = _openMap(cols: 7, rows: 2);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          GameUnit.produced(
            id: 'spearman_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.spearman,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'spearman_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.spearman,
            col: 1,
            row: 1,
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
            id: 'second_city',
            ownerPlayerId: 'player_1',
            name: 'Second City',
            center: CityHex(col: 0, row: 1),
          ),
          GameCity(
            id: 'human_city',
            ownerPlayerId: 'player_2',
            name: 'Human City',
            center: CityHex(col: 6, row: 0),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(
        state,
        mapData,
        pressureTargetPlayerIds: const {'player_2'},
      );
      final context = _context(
        mapData,
        CivilizationProfiles.all[PlayerCountry.canada]!,
      );
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 2,
        workerCount: 2,
        settlerCount: 0,
        militaryCount: 4,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 16,
        netGoldPerTurn: 2,
        desiredCityCount: 4,
        desiredWorkerCount: 2,
        desiredMilitaryCount: 3,
      );
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final goals = const WarGoalGenerator().generate(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.consolidate,
      );

      expect(goals, hasLength(1));
      expect(goals.single.targetPlayerId, 'player_2');
      expect(goals.single.kind, WarGoalKind.captureCity);
      expect(goals.single.targetCity, const CityHex(col: 6, row: 0));
      expect(goals.single.assignedUnitIds, contains('warrior_1'));
    });

    test('keeps pressure on a priority target with parity-sized army', () {
      final mapData = _openMap(cols: 9, rows: 5);
      final state = PersistentGameState(
        units: [
          for (var index = 0; index < 5; index++)
            GameUnit.produced(
              id: 'warrior_$index',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: index,
              row: 0,
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
            center: CityHex(col: 1, row: 1),
          ),
          GameCity(
            id: 'third',
            ownerPlayerId: 'player_1',
            name: 'Third',
            center: CityHex(col: 2, row: 2),
          ),
          GameCity(
            id: 'fourth',
            ownerPlayerId: 'player_1',
            name: 'Fourth',
            center: CityHex(col: 3, row: 3),
          ),
          GameCity(
            id: 'fifth',
            ownerPlayerId: 'player_1',
            name: 'Fifth',
            center: CityHex(col: 4, row: 4),
          ),
          GameCity(
            id: 'human_city',
            ownerPlayerId: 'player_2',
            name: 'Human City',
            center: CityHex(col: 8, row: 2),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(
        state,
        mapData,
        pressureTargetPlayerIds: const {'player_2'},
      );
      final context = _context(
        mapData,
        CivilizationProfiles.all[PlayerCountry.canada]!,
      );
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 5,
        workerCount: 5,
        settlerCount: 0,
        militaryCount: 5,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 40,
        netGoldPerTurn: 5,
        desiredCityCount: 5,
        desiredWorkerCount: 5,
        desiredMilitaryCount: 5,
      );
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final goals = const WarGoalGenerator().generate(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.consolidate,
      );

      expect(goals, hasLength(1));
      expect(goals.single.targetPlayerId, 'player_2');
      expect(goals.single.kind, WarGoalKind.captureCity);
      expect(goals.single.targetCity, const CityHex(col: 8, row: 2));
    });

    test(
      'does not generate war goals for explicit neutral pressure target',
      () {
        final mapData = _openMap(cols: 7, rows: 5);
        final diplomacy = DiplomacyState.empty.setStatus(
          'player_1',
          'player_2',
          DiplomaticRelationStatus.neutral,
        );
        final state = PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 1,
            ),
            GameUnit.produced(
              id: 'neutral_warrior',
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
              center: CityHex(col: 0, row: 0),
            ),
            GameCity(
              id: 'neutral_city',
              ownerPlayerId: 'player_2',
              name: 'Neutral City',
              center: CityHex(col: 6, row: 1),
            ),
          ],
          fogOfWar: _fog(mapData),
          runtimeState: GameRuntimeState(diplomacy: diplomacy),
        );
        final view = _view(
          state,
          mapData,
          recentHostilePlayerIds: const {'player_2'},
          pressureTargetPlayerIds: const {'player_2'},
        );
        const assessment = AiEmpireAssessment(
          playerId: 'player_1',
          cityCount: 1,
          workerCount: 1,
          settlerCount: 0,
          militaryCount: 2,
          visibleEnemyMilitaryCount: 0,
          goldReserve: 20,
          netGoldPerTurn: 2,
          desiredCityCount: 2,
          desiredWorkerCount: 1,
          desiredMilitaryCount: 2,
        );
        final context = _context(
          mapData,
          CivilizationProfiles.all[PlayerCountry.germany]!,
        );
        final threats = const ThreatAssessor().assess(
          assessment: assessment,
          rivals: RivalSnapshot.fromView(view),
        );

        final goals = const WarGoalGenerator().generate(
          view: view,
          context: context,
          assessment: assessment,
          threats: threats,
          mode: StrategicMode.military,
        );

        expect(threats, isEmpty);
        expect(goals, isEmpty);
      },
    );

    test(
      'keeps active war pressure offensive against a larger visible army',
      () {
        final mapData = _openMap(cols: 12, rows: 5);
        final diplomacy = DiplomacyState.empty.setStatus(
          'player_1',
          'player_2',
          DiplomaticRelationStatus.war,
        );
        final state = PersistentGameState(
          units: [
            for (var index = 0; index < 5; index++)
              GameUnit.produced(
                id: 'warrior_$index',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                col: index,
                row: 0,
              ),
            for (var index = 0; index < 6; index++)
              GameUnit.produced(
                id: 'enemy_$index',
                ownerPlayerId: 'player_2',
                type: GameUnitType.warrior,
                col: index + 3,
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
            GameCity(
              id: 'second',
              ownerPlayerId: 'player_1',
              name: 'Second',
              center: CityHex(col: 1, row: 1),
            ),
            GameCity(
              id: 'third',
              ownerPlayerId: 'player_1',
              name: 'Third',
              center: CityHex(col: 2, row: 2),
            ),
            GameCity(
              id: 'fourth',
              ownerPlayerId: 'player_1',
              name: 'Fourth',
              center: CityHex(col: 3, row: 3),
            ),
            GameCity(
              id: 'fifth',
              ownerPlayerId: 'player_1',
              name: 'Fifth',
              center: CityHex(col: 4, row: 4),
            ),
            GameCity(
              id: 'human_city',
              ownerPlayerId: 'player_2',
              name: 'Human City',
              center: CityHex(col: 11, row: 2),
            ),
          ],
          fogOfWar: _fog(mapData),
          runtimeState: GameRuntimeState(diplomacy: diplomacy),
        );
        final view = _view(
          state,
          mapData,
          pressureTargetPlayerIds: const {'player_2'},
        );
        final context = _context(
          mapData,
          CivilizationProfiles.all[PlayerCountry.canada]!,
        );
        const assessment = AiEmpireAssessment(
          playerId: 'player_1',
          cityCount: 5,
          workerCount: 5,
          settlerCount: 0,
          militaryCount: 5,
          visibleEnemyMilitaryCount: 6,
          goldReserve: 40,
          netGoldPerTurn: 5,
          desiredCityCount: 5,
          desiredWorkerCount: 5,
          desiredMilitaryCount: 5,
        );
        final threats = const ThreatAssessor().assess(
          assessment: assessment,
          rivals: RivalSnapshot.fromView(view),
        );

        final goals = const WarGoalGenerator().generate(
          view: view,
          context: context,
          assessment: assessment,
          threats: threats,
          mode: StrategicMode.military,
        );

        expect(goals, hasLength(1));
        expect(goals.single.targetPlayerId, 'player_2');
        expect(goals.single.kind, WarGoalKind.captureCity);
        expect(goals.single.targetCity, const CityHex(col: 11, row: 2));
      },
    );

    test(
      'focuses goals on active war pressure before neutral opportunities',
      () {
        final mapData = _openMap(cols: 10, rows: 4);
        final diplomacy = DiplomacyState.empty.setStatus(
          'player_1',
          'player_2',
          DiplomaticRelationStatus.war,
        );
        final state = PersistentGameState(
          units: [
            for (var index = 0; index < 6; index++)
              GameUnit.produced(
                id: 'warrior_$index',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                col: index,
                row: 0,
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
              id: 'war_target',
              ownerPlayerId: 'player_2',
              name: 'War Target',
              center: CityHex(col: 9, row: 0),
            ),
            GameCity(
              id: 'neutral_opportunity',
              ownerPlayerId: 'player_3',
              name: 'Neutral Opportunity',
              center: CityHex(col: 2, row: 3),
            ),
          ],
          fogOfWar: _fog(mapData),
          runtimeState: GameRuntimeState(diplomacy: diplomacy),
        );
        final view = _view(
          state,
          mapData,
          pressureTargetPlayerIds: const {'player_2'},
        );
        final context = _context(
          mapData,
          CivilizationProfiles.all[PlayerCountry.germany]!,
        );
        const assessment = AiEmpireAssessment(
          playerId: 'player_1',
          cityCount: 3,
          workerCount: 3,
          settlerCount: 0,
          militaryCount: 6,
          visibleEnemyMilitaryCount: 0,
          goldReserve: 30,
          netGoldPerTurn: 4,
          desiredCityCount: 3,
          desiredWorkerCount: 3,
          desiredMilitaryCount: 5,
        );
        final threats = const ThreatAssessor().assess(
          assessment: assessment,
          rivals: RivalSnapshot.fromView(view),
        );

        final goals = const WarGoalGenerator(maxGoals: 2).generate(
          view: view,
          context: context,
          assessment: assessment,
          threats: threats,
          mode: StrategicMode.military,
        );

        expect(goals, hasLength(1));
        expect(goals.single.targetPlayerId, 'player_2');
        expect(goals.single.kind, WarGoalKind.captureCity);
        expect(goals.single.targetCity, const CityHex(col: 9, row: 0));
      },
    );

    test('does not assign units reserved for city defense', () {
      final mapData = _openMap(cols: 6, rows: 2);
      final state = _warGoalState(mapData);
      final view = _view(state, mapData);
      final context = _context(
        mapData,
        CivilizationProfiles.all[PlayerCountry.germany]!,
      );
      final assessment = _postOpeningAssessment(militaryCount: 2);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final goals = const WarGoalGenerator().generate(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.consolidate,
        reservedUnitIds: const ['warrior_1'],
      );

      expect(goals, hasLength(1));
      expect(goals.single.assignedUnitIds, isNot(contains('warrior_1')));
      expect(goals.single.assignedUnitIds, contains('warrior_2'));
    });

    test('captures a nearby city when active expansion is boxed in', () {
      final mapData = _openMap(cols: 6, rows: 3);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 1,
            row: 1,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          GameUnit.produced(
            id: 'spearman_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.spearman,
            col: 0,
            row: 2,
          ),
          GameUnit.produced(
            id: 'enemy_guard',
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
            center: CityHex(col: 0, row: 1),
          ),
          GameCity(
            id: 'enemy_city',
            ownerPlayerId: 'player_2',
            name: 'Enemy City',
            center: CityHex(col: 4, row: 1),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(
        state,
        mapData,
        recentHostilePlayerIds: const {'player_2'},
      );
      final context = _context(
        mapData,
        CivilizationProfiles.poland,
        difficulty: AiDifficulty.veryHard,
      );
      final assessment = AiEmpireAssessment.fromView(view, context);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final goals = const WarGoalGenerator().generate(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.military,
        citySitePlan: CitySitePlan.empty,
        reservedUnitIds: const ['warrior_1'],
      );

      expect(goals, hasLength(1));
      expect(goals.single.targetPlayerId, 'player_2');
      expect(goals.single.kind, WarGoalKind.captureCity);
      expect(goals.single.targetCity, const CityHex(col: 4, row: 1));
      expect(goals.single.assignedUnitIds, isNot(contains('warrior_1')));
      expect(goals.single.assignedUnitIds, contains('warrior_2'));
    });

    test('boxed expansion targets the city closest to expansion anchors', () {
      final mapData = _openMap(cols: 8, rows: 6);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 0,
            row: 4,
          ),
          GameUnit.produced(
            id: 'spearman_near_far_city',
            ownerPlayerId: 'player_1',
            type: GameUnitType.spearman,
            col: 6,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'enemy_far_guard',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 7,
            row: 0,
          ),
          GameUnit.produced(
            id: 'enemy_close_guard',
            ownerPlayerId: 'player_3',
            type: GameUnitType.warrior,
            col: 2,
            row: 5,
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
            id: 'far_enemy_city',
            ownerPlayerId: 'player_2',
            name: 'Far Enemy City',
            center: CityHex(col: 7, row: 0),
          ),
          GameCity(
            id: 'close_enemy_city',
            ownerPlayerId: 'player_3',
            name: 'Close Enemy City',
            center: CityHex(col: 1, row: 5),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(
        state,
        mapData,
        recentHostilePlayerIds: const {'player_2', 'player_3'},
      );
      final context = _context(
        mapData,
        CivilizationProfiles.poland,
        difficulty: AiDifficulty.veryHard,
      );
      final assessment = AiEmpireAssessment.fromView(view, context);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final goals = const WarGoalGenerator(maxGoals: 2).generate(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.military,
        citySitePlan: CitySitePlan.empty,
      );

      expect(goals, isNotEmpty);
      expect(goals.first.targetPlayerId, 'player_3');
      expect(goals.first.kind, WarGoalKind.captureCity);
      expect(goals.first.targetCity, const CityHex(col: 1, row: 5));
      expect(goals.first.targetHex, const HexCoordinate(col: 1, row: 5));
    });

    test('creates a defensive reinforcement goal for a recent aggressor', () {
      final mapData = _openMap(cols: 6, rows: 2);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'home_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'reserve',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 4,
            row: 1,
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
        fogOfWar: _fog(mapData),
      );
      final view = _view(
        state,
        mapData,
        recentHostilePlayerIds: const {'player_2'},
      );
      final context = _context(
        mapData,
        CivilizationProfiles.poland,
        difficulty: AiDifficulty.veryHard,
      );
      final assessment = AiEmpireAssessment.fromView(view, context);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final goals = const WarGoalGenerator().generate(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.consolidate,
        reservedUnitIds: const ['home_guard'],
      );

      expect(goals, hasLength(1));
      expect(goals.single.targetPlayerId, 'player_2');
      expect(goals.single.kind, WarGoalKind.defend);
      expect(goals.single.targetHex, const HexCoordinate(col: 0, row: 0));
      expect(goals.single.assignedUnitIds, const ['reserve']);
    });

    test('keeps hostile pressure defensive before military surplus', () {
      final mapData = _openMap(cols: 6, rows: 2);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'home_guard',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'enemy_warrior',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 3,
            row: 0,
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
        fogOfWar: _fog(mapData),
      );
      final view = _view(
        state,
        mapData,
        recentHostilePlayerIds: const {'player_2'},
      );
      final context = _context(
        mapData,
        CivilizationProfiles.all[PlayerCountry.japan]!,
      );
      final assessment = AiEmpireAssessment.fromView(view, context);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final goals = const WarGoalGenerator().generate(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.military,
      );

      expect(goals, hasLength(1));
      expect(goals.single.kind, WarGoalKind.defend);
      expect(goals.single.targetHex, const HexCoordinate(col: 0, row: 0));
    });

    test('counterattacks a recent aggressor when clearly ahead on units', () {
      final mapData = _openMap(cols: 6, rows: 2);
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 1,
          ),
          GameUnit.produced(
            id: 'spearman_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.spearman,
            col: 1,
            row: 0,
          ),
          GameUnit.produced(
            id: 'enemy_warrior',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 3,
            row: 0,
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
            id: 'enemy_city',
            ownerPlayerId: 'player_2',
            name: 'Enemy City',
            center: CityHex(col: 5, row: 0),
          ),
        ],
        fogOfWar: _fog(mapData),
      );
      final view = _view(
        state,
        mapData,
        recentHostilePlayerIds: const {'player_2'},
      );
      final context = _context(
        mapData,
        CivilizationProfiles.poland,
        difficulty: AiDifficulty.veryHard,
      );
      final assessment = AiEmpireAssessment.fromView(view, context);
      final threats = const ThreatAssessor().assess(
        assessment: assessment,
        rivals: RivalSnapshot.fromView(view),
      );

      final goals = const WarGoalGenerator().generate(
        view: view,
        context: context,
        assessment: assessment,
        threats: threats,
        mode: StrategicMode.consolidate,
      );

      expect(goals, hasLength(1));
      expect(goals.single.targetPlayerId, 'player_2');
      expect(goals.single.kind, WarGoalKind.captureCity);
      expect(goals.single.targetCity, const CityHex(col: 5, row: 0));
      expect(goals.single.assignedUnitIds, contains('warrior_1'));
    });
  });
}

PersistentGameState _warGoalState(MapData mapData) {
  return PersistentGameState(
    units: [
      GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ),
      GameUnit.produced(
        id: 'warrior_2',
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
        center: CityHex(col: 0, row: 0),
      ),
      GameCity(
        id: 'enemy_city',
        ownerPlayerId: 'player_2',
        name: 'Enemy City',
        center: CityHex(col: 5, row: 0),
      ),
    ],
    research: ResearchState(
      players: {
        'player_1': PlayerResearchState(
          activeTechnologyId: TechnologyId.agriculture,
        ),
      },
    ),
    fogOfWar: _fog(mapData),
  );
}

GameView _view(
  PersistentGameState state,
  MapData mapData, {
  Iterable<String> activeHostilePlayerIds = const [],
  Iterable<String> recentHostilePlayerIds = const [],
  Iterable<String> pressureTargetPlayerIds = const [],
}) {
  return GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 6,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
    activeHostilePlayerIds: activeHostilePlayerIds,
    recentHostilePlayerIds: recentHostilePlayerIds,
    pressureTargetPlayerIds: pressureTargetPlayerIds,
  );
}

AiContext _context(
  MapData mapData,
  CivilizationProfile profile, {
  AiDifficulty difficulty = AiDifficulty.normal,
}) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: mapData,
    turn: 6,
    rng: AiRng.fromTurn(turn: 6, playerId: 'player_1', baseSeed: 11),
    persona: profile.defaultPersona,
    difficulty: difficulty,
    civProfile: profile,
  );
}

AiEmpireAssessment _assessment({required int militaryCount}) {
  return AiEmpireAssessment(
    playerId: 'player_1',
    cityCount: 1,
    workerCount: 1,
    settlerCount: 0,
    militaryCount: militaryCount,
    visibleEnemyMilitaryCount: 0,
    goldReserve: 12,
    netGoldPerTurn: 1,
    desiredCityCount: 2,
    desiredWorkerCount: 1,
    desiredMilitaryCount: militaryCount,
  );
}

AiEmpireAssessment _postOpeningAssessment({required int militaryCount}) {
  return AiEmpireAssessment(
    playerId: 'player_1',
    cityCount: 3,
    workerCount: 3,
    settlerCount: 0,
    militaryCount: militaryCount,
    visibleEnemyMilitaryCount: 0,
    goldReserve: 16,
    netGoldPerTurn: 2,
    desiredCityCount: 3,
    desiredWorkerCount: 3,
    desiredMilitaryCount: militaryCount,
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
