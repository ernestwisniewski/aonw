import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BalanceTelemetryAnalyzer', () {
    test('records milestone turns and victory outcome', () {
      final report = const BalanceTelemetryAnalyzer().analyze(
        playerIds: const ['player_1', 'player_2'],
        samples: [
          BalanceTelemetryTurnSample(turn: 1, state: _state()),
          BalanceTelemetryTurnSample(
            turn: 3,
            state: _state(unlockedTechs: const {TechnologyId.agriculture}),
          ),
          BalanceTelemetryTurnSample(
            turn: 6,
            state: _state(buildings: const {CityBuildingType.granary}),
          ),
          BalanceTelemetryTurnSample(turn: 8, state: _state(secondCity: true)),
          BalanceTelemetryTurnSample(
            turn: 9,
            state: _state(firstContact: true),
          ),
          BalanceTelemetryTurnSample(
            turn: 10,
            state: _state(),
            dominationByPlayerId: const {
              'player_1': BalanceTelemetryDominationSample(
                controlPercent: 45,
                requiredControlPercent: 50,
                holdTurns: 0,
                requiredHoldTurns: 3,
              ),
            },
            events: const [
              UnitAttackedEvent(
                attackerUnitId: 'warrior_1',
                attackerOwnerPlayerId: 'player_1',
                defenderUnitId: 'warrior_2',
                defenderOwnerPlayerId: 'player_2',
              ),
            ],
          ),
          BalanceTelemetryTurnSample(
            turn: 12,
            state: _state(),
            dominationByPlayerId: const {
              'player_1': BalanceTelemetryDominationSample(
                controlPercent: 50,
                requiredControlPercent: 50,
                holdTurns: 1,
                requiredHoldTurns: 3,
              ),
            },
            outcome: const GameOutcome.conquest('player_1'),
          ),
        ],
      );

      final player = report.player('player_1');
      expect(player.firstTechnologyTurn, 3);
      expect(player.firstBuildingTurn, 6);
      expect(player.secondCityTurn, 8);
      expect(player.firstContactTurn, 9);
      expect(player.firstCombatTurn, 10);
      expect(player.firstDominationThresholdTurn, 12);
      expect(player.maxDominationControlPercent, 50);
      expect(player.maxDominationHoldTurns, 1);
      expect(report.victoryTurn, 12);
      expect(report.victoryCondition, GameOutcomeCondition.conquest);
      expect(report.winnerPlayerId, 'player_1');
    });

    test('counts dead-turn runs from commands, events, and state progress', () {
      final base = _state();
      final explored = _state(discoveredHexes: 3);

      final report = const BalanceTelemetryAnalyzer().analyze(
        playerIds: const ['player_1'],
        samples: [
          BalanceTelemetryTurnSample(turn: 1, state: base),
          BalanceTelemetryTurnSample(turn: 2, state: base),
          BalanceTelemetryTurnSample(turn: 3, state: base),
          BalanceTelemetryTurnSample(
            turn: 4,
            state: base,
            meaningfulCommandsByPlayerId: const {'player_1': 1},
          ),
          BalanceTelemetryTurnSample(turn: 5, state: explored),
          BalanceTelemetryTurnSample(turn: 6, state: explored),
          BalanceTelemetryTurnSample(turn: 7, state: explored),
          BalanceTelemetryTurnSample(turn: 8, state: explored),
        ],
      );

      final player = report.player('player_1');
      expect(player.deadTurnCount, 5);
      expect(player.longestDeadTurnStreak, 3);
      expect(player.deadTurnRuns, [
        const BalanceTelemetryDeadTurnRun(
          playerId: 'player_1',
          startTurn: 2,
          endTurn: 3,
        ),
        const BalanceTelemetryDeadTurnRun(
          playerId: 'player_1',
          startTurn: 6,
          endTurn: 8,
        ),
      ]);
      expect(report.findings.map((finding) => finding.code), [
        'dead_turn_streak',
      ]);
    });

    test('counts objective-aware action diagnostics by advice and target', () {
      final report = const BalanceTelemetryAnalyzer().analyze(
        playerIds: const ['player_1'],
        samples: [
          BalanceTelemetryTurnSample(turn: 1, state: _state()),
          BalanceTelemetryTurnSample(
            turn: 2,
            state: _state(),
            objectiveActionByPlayerId: const {
              'player_1': BalanceTelemetryObjectiveActionSample(
                advice: GameObjectiveAdvice.improveField,
                target: BalanceTelemetryObjectiveActionTarget.unit,
              ),
            },
          ),
          BalanceTelemetryTurnSample(
            turn: 3,
            state: _state(),
            objectiveActionByPlayerId: const {
              'player_1': BalanceTelemetryObjectiveActionSample(
                advice: GameObjectiveAdvice.collectGold,
                target: BalanceTelemetryObjectiveActionTarget.cityProduction,
              ),
            },
          ),
        ],
      );

      final player = report.player('player_1');
      expect(player.objectiveActionSampleCount, 2);
      expect(player.objectiveActionAdviceCounts, {
        GameObjectiveAdvice.improveField: 1,
        GameObjectiveAdvice.collectGold: 1,
      });
      expect(player.objectiveActionTargetCounts, {
        BalanceTelemetryObjectiveActionTarget.unit: 1,
        BalanceTelemetryObjectiveActionTarget.cityProduction: 1,
      });
    });

    test('records final pace metrics from the latest analyzed sample', () {
      final report =
          const BalanceTelemetryAnalyzer(
            targets: BalanceTelemetryTuningTargets(
              firstTechnologyMaxTurn: 99,
              firstBuildingMaxTurn: 99,
              secondCityMaxTurn: 5,
              firstContactMaxTurn: 99,
              firstCombatMaxTurn: 99,
              maxDeadTurnStreak: 99,
            ),
          ).analyze(
            playerIds: const ['player_1'],
            samples: [
              BalanceTelemetryTurnSample(turn: 1, state: _state()),
              BalanceTelemetryTurnSample(
                turn: 2,
                state: _state(
                  unlockedTechs: const {
                    TechnologyId.agriculture,
                    TechnologyId.mining,
                  },
                  secondCity: true,
                ),
                endPaceByPlayerId: const {
                  'player_1': BalanceTelemetryEndPaceSample(
                    completedTechnologyCount: 2,
                    sciencePerTurn: 14,
                    cityCount: 2,
                    unitCount: 3,
                    gold: 25,
                    netGoldPerTurn: 4,
                  ),
                },
              ),
            ],
          );

      final player = report.player('player_1');
      expect(player.finalTechnologyCount, 2);
      expect(player.finalSciencePerTurn, 14);
      expect(player.finalCityCount, 2);
      expect(player.finalUnitCount, 3);
      expect(player.finalGold, 25);
      expect(player.finalNetGoldPerTurn, 4);
    });

    test('emits final pace findings outside tuning ranges', () {
      final report =
          const BalanceTelemetryAnalyzer(
            targets: BalanceTelemetryTuningTargets(
              firstTechnologyMaxTurn: 99,
              firstBuildingMaxTurn: 99,
              secondCityMaxTurn: 99,
              firstContactMaxTurn: 99,
              firstCombatMaxTurn: 99,
              maxDeadTurnStreak: 99,
              finalTechnologyMinCount: 2,
              finalTechnologyMaxCount: 3,
              finalScienceMinPerTurn: 10,
              finalScienceMaxPerTurn: 20,
              finalCityMinCount: 2,
              finalCityMaxCount: 4,
            ),
          ).analyze(
            playerIds: const ['player_1'],
            samples: [
              BalanceTelemetryTurnSample(
                turn: 1,
                state: _state(),
                endPaceByPlayerId: const {
                  'player_1': BalanceTelemetryEndPaceSample(
                    completedTechnologyCount: 1,
                    sciencePerTurn: 25,
                    cityCount: 1,
                    unitCount: 2,
                    gold: 0,
                    netGoldPerTurn: 0,
                  ),
                },
              ),
            ],
          );

      expect(report.findings.map((finding) => finding.code), [
        'low_final_technology_count',
        'high_final_science_per_turn',
        'low_final_city_count',
      ]);
    });

    test('suppresses low final pace findings for military winners', () {
      final report =
          const BalanceTelemetryAnalyzer(
            targets: BalanceTelemetryTuningTargets(
              firstTechnologyMaxTurn: 99,
              firstBuildingMaxTurn: 99,
              secondCityMaxTurn: 99,
              firstContactMaxTurn: 99,
              firstCombatMaxTurn: 99,
              maxDeadTurnStreak: 99,
              finalTechnologyMinCount: 2,
              finalScienceMinPerTurn: 10,
              finalCityMinCount: 2,
              finalCityMaxCount: 6,
            ),
          ).analyze(
            playerIds: const ['player_1', 'player_2'],
            samples: [
              BalanceTelemetryTurnSample(
                turn: 12,
                state: _state(),
                endPaceByPlayerId: const {
                  'player_1': BalanceTelemetryEndPaceSample(
                    completedTechnologyCount: 3,
                    sciencePerTurn: 12,
                    cityCount: 7,
                    unitCount: 8,
                    gold: 0,
                    netGoldPerTurn: 0,
                  ),
                  'player_2': BalanceTelemetryEndPaceSample(
                    completedTechnologyCount: 1,
                    sciencePerTurn: 5,
                    cityCount: 1,
                    unitCount: 2,
                    gold: 0,
                    netGoldPerTurn: 0,
                  ),
                },
                outcome: const GameOutcome.conquest('player_1'),
              ),
            ],
          );

      expect(report.findings, isEmpty);
    });

    test('emits late milestone findings after target windows', () {
      final report =
          const BalanceTelemetryAnalyzer(
            targets: BalanceTelemetryTuningTargets(
              firstTechnologyMaxTurn: 3,
              firstBuildingMaxTurn: 3,
              secondCityMaxTurn: 3,
              firstContactMaxTurn: 3,
              firstCombatMaxTurn: 3,
              dominationThresholdMaxTurn: 3,
              maxDeadTurnStreak: 10,
            ),
          ).analyze(
            playerIds: const ['player_1'],
            samples: [
              BalanceTelemetryTurnSample(turn: 1, state: _state()),
              BalanceTelemetryTurnSample(turn: 5, state: _state()),
            ],
          );

      expect(report.findings.map((finding) => finding.code), [
        'late_first_technology',
        'late_first_building',
        'late_second_city',
        'late_first_contact',
        'late_first_combat',
        'late_domination_threshold',
      ]);
    });

    test(
      'does not warn about missing milestones before target windows close',
      () {
        final report =
            const BalanceTelemetryAnalyzer(
              targets: BalanceTelemetryTuningTargets(
                firstTechnologyMaxTurn: 5,
                firstBuildingMaxTurn: 5,
                secondCityMaxTurn: 5,
                firstContactMaxTurn: 5,
                firstCombatMaxTurn: 5,
              ),
            ).analyze(
              playerIds: const ['player_1'],
              samples: [BalanceTelemetryTurnSample(turn: 2, state: _state())],
            );

        expect(report.findings, isEmpty);
      },
    );

    test('exposes tuning target windows per pace profile', () {
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.standard60,
        ).firstBuildingMaxTurn,
        20,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.standard60,
        ).secondCityMaxTurn,
        16,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.standard60,
        ).firstContactMaxTurn,
        24,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.standard60,
        ).firstCombatMaxTurn,
        36,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.standard60,
        ).dominationThresholdMaxTurn,
        0,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.standard60,
        ).finalTechnologyMaxCount,
        42,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.standard60,
        ).finalTechnologyMinCount,
        15,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.standard60,
        ).finalScienceMinPerTurn,
        6,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.long120,
        ).firstBuildingMaxTurn,
        23,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.long120,
        ).secondCityMaxTurn,
        24,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.long120,
        ).firstContactMaxTurn,
        32,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.long120,
        ).firstCombatMaxTurn,
        60,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.long120,
        ).dominationThresholdMaxTurn,
        0,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.long120,
        ).finalTechnologyMinCount,
        22,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.long120,
        ).finalScienceMinPerTurn,
        10,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.normal90,
        ).firstBuildingMaxTurn,
        21,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.normal90,
        ).secondCityMaxTurn,
        20,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.normal90,
        ).firstContactMaxTurn,
        28,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.normal90,
        ).firstCombatMaxTurn,
        48,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.normal90,
        ).finalTechnologyMinCount,
        18,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(
          PaceProfile.long120,
        ).finalScienceMaxPerTurn,
        70,
      );
      expect(
        BalanceTelemetryTuningTargets.forPaceProfile(PaceProfile.unlimited),
        BalanceTelemetryTuningTargets.standard,
      );
    });
  });

  group('BalanceTelemetryObjectiveActionDiagnostics', () {
    test('samples score-chaser objective actions from real score gaps', () {
      for (final scenario in [
        _ScoreChaserScenario(
          name: 'production gap',
          state: _state(
            units: const [],
            cities: [
              _city('city_1', 'player_1'),
              _city(
                'city_2',
                'player_2',
                col: 5,
                buildings: const {
                  CityBuildingType.granary,
                  CityBuildingType.monument,
                  CityBuildingType.marketplace,
                },
              ),
            ],
          ),
          advice: GameObjectiveAdvice.constructBuilding,
          target: BalanceTelemetryObjectiveActionTarget.cityProduction,
        ),
        _ScoreChaserScenario(
          name: 'research gap',
          state: _state(
            units: const [],
            cities: [
              _city('city_1', 'player_1', productionQueued: true),
              _city('city_2', 'player_2', col: 5),
            ],
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(),
                'player_2': PlayerResearchState(
                  unlockedTechnologyIds: {
                    TechnologyId.agriculture,
                    TechnologyId.writing,
                  },
                ),
              },
            ),
          ),
          advice: GameObjectiveAdvice.unlockTechnology,
          target: BalanceTelemetryObjectiveActionTarget.research,
        ),
        _ScoreChaserScenario(
          name: 'economy gap',
          state: _state(
            units: const [],
            cities: [
              _city('city_1', 'player_1'),
              _city('city_2', 'player_2', col: 5),
            ],
            playerGold: const {'player_1': 0, 'player_2': 250},
          ),
          advice: GameObjectiveAdvice.collectGold,
          target: BalanceTelemetryObjectiveActionTarget.cityProduction,
        ),
      ]) {
        final samples =
            BalanceTelemetryObjectiveActionDiagnostics.scorePressureSamplesFor(
              state: scenario.state,
              playerIds: const ['player_1', 'player_2'],
            );

        expect(
          samples['player_1'],
          BalanceTelemetryObjectiveActionSample(
            advice: scenario.advice,
            target: scenario.target,
          ),
          reason: scenario.name,
        );
      }
    });

    test('resolves unit, city production, research and none targets', () {
      expect(
        BalanceTelemetryObjectiveActionDiagnostics.targetFor(
          state: _state(
            units: [_unit('worker_1', 'player_1', type: GameUnitType.worker)],
            cities: const [],
            research: _activeResearch(),
          ),
          playerId: 'player_1',
          advice: GameObjectiveAdvice.improveField,
        ),
        BalanceTelemetryObjectiveActionTarget.unit,
      );
      expect(
        BalanceTelemetryObjectiveActionDiagnostics.targetFor(
          state: _state(
            units: [_unit('warrior_1', 'player_1', movementPoints: 0)],
            cities: [_city('city_1', 'player_1')],
            research: _activeResearch(),
          ),
          playerId: 'player_1',
          advice: GameObjectiveAdvice.collectGold,
        ),
        BalanceTelemetryObjectiveActionTarget.cityProduction,
      );
      expect(
        BalanceTelemetryObjectiveActionDiagnostics.targetFor(
          state: _state(
            units: const [],
            cities: [_city('city_1', 'player_1', productionQueued: true)],
          ),
          playerId: 'player_1',
          advice: GameObjectiveAdvice.unlockTechnology,
        ),
        BalanceTelemetryObjectiveActionTarget.research,
      );
      expect(
        BalanceTelemetryObjectiveActionDiagnostics.targetFor(
          state: _state(
            units: const [],
            cities: [_city('city_1', 'player_1', productionQueued: true)],
            research: _activeResearch(),
          ),
          playerId: 'player_1',
          advice: GameObjectiveAdvice.trainUnit,
        ),
        BalanceTelemetryObjectiveActionTarget.none,
      );
    });
  });
}

PersistentGameState _state({
  Set<TechnologyId> unlockedTechs = const {},
  Set<CityBuildingType> buildings = const {},
  bool secondCity = false,
  bool firstContact = false,
  int discoveredHexes = 0,
  List<GameUnit>? units,
  List<GameCity>? cities,
  ResearchState? research,
  Map<String, int> playerGold = const {},
}) {
  return PersistentGameState(
    playerGold: playerGold,
    units:
        units ??
        [
          _unit('warrior_1', 'player_1'),
          _unit('warrior_2', 'player_2', col: 4, row: 0),
        ],
    cities:
        cities ??
        [
          _city('city_1', 'player_1', buildings: buildings),
          if (secondCity) _city('city_2', 'player_1', col: 2),
          _city('city_3', 'player_2', col: 5),
        ],
    fogOfWar: FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(
          playerId: 'player_1',
          discoveredHexes: {
            for (var col = 0; col < discoveredHexes; col++)
              HexCoordinate(col: col, row: 0),
          },
          visibleHexes: firstContact
              ? {const HexCoordinate(col: 4, row: 0)}
              : const {},
        ),
      },
    ),
    research:
        research ??
        ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: unlockedTechs,
            ),
          },
        ),
  );
}

class _ScoreChaserScenario {
  const _ScoreChaserScenario({
    required this.name,
    required this.state,
    required this.advice,
    required this.target,
  });

  final String name;
  final PersistentGameState state;
  final GameObjectiveAdvice advice;
  final BalanceTelemetryObjectiveActionTarget target;
}

GameUnit _unit(
  String id,
  String ownerPlayerId, {
  int col = 0,
  int row = 0,
  GameUnitType type = GameUnitType.warrior,
  int? movementPoints,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: row,
    movementPoints: movementPoints,
  );
}

GameCity _city(
  String id,
  String ownerPlayerId, {
  int col = 0,
  int row = 0,
  Set<CityBuildingType> buildings = const {},
  bool productionQueued = false,
}) {
  return GameCity(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: CityHex(col: col, row: row),
    buildings: buildings,
    productionQueue: productionQueued
        ? CityProductionQueue.building(
            buildingType: CityBuildingType.granary,
            investedProduction: 0,
          )
        : null,
  );
}

ResearchState _activeResearch() {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(
        activeTechnologyId: TechnologyId.agriculture,
      ),
    },
  );
}
