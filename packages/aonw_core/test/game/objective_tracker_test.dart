import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:test/test.dart';

void main() {
  group('GameObjectiveTracker', () {
    test(
      'returns the first early-game objectives that are still incomplete',
      () {
        final objectives =
            GameObjectiveTracker.activeEarlyGameObjectivesForPlayer(
              playerId: 'player_1',
              cities: const [],
              units: const [],
              fieldImprovements: const [],
              fogOfWar: _fog(discoveredCount: 4),
              research: ResearchState.empty,
            );

        expect(objectives.map((objective) => objective.definition.id), [
          GameObjectiveId.chooseResearch,
          GameObjectiveId.foundCapital,
          GameObjectiveId.exploreNearby,
        ]);
        expect(objectives[2].progressLabel, '4/28');
      },
    );

    test('keeps objective targets unchanged for unlimited pace', () {
      final defaultProgress = GameObjectiveTracker.progressForPlayer(
        playerId: 'player_1',
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        fogOfWar: _fog(discoveredCount: 4),
        research: ResearchState.empty,
      );
      final unlimitedProgress = GameObjectiveTracker.progressForPlayer(
        playerId: 'player_1',
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        fogOfWar: _fog(discoveredCount: 4),
        research: ResearchState.empty,
        paceBalance: PaceBalance.unlimited,
      );

      expect(_targetsById(unlimitedProgress), _targetsById(defaultProgress));
      expect(_targetFor(unlimitedProgress, GameObjectiveId.exploreNearby), 28);
      expect(_targetFor(unlimitedProgress, GameObjectiveId.exploreRegion), 70);
    });

    test('scales flexible objective targets for standard pace', () {
      final progress = GameObjectiveTracker.progressForPlayer(
        playerId: 'player_1',
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        fogOfWar: _fog(discoveredCount: 13),
        research: ResearchState.empty,
        paceBalance: PaceBalance.standard60,
      );

      expect(_targetFor(progress, GameObjectiveId.exploreNearby), 24);
      expect(_targetFor(progress, GameObjectiveId.exploreRegion), 60);
      expect(_targetFor(progress, GameObjectiveId.buildCombatForce), 3);
      expect(_targetFor(progress, GameObjectiveId.improveThreeHexes), 3);
      expect(_targetFor(progress, GameObjectiveId.foundThirdCity), 3);

      final nearbyProgress = _progressFor(
        progress,
        GameObjectiveId.exploreNearby,
      );
      expect(nearbyProgress.progressLabel, '13/24');
      expect(nearbyProgress.fraction, closeTo(13 / 24, 0.0001));
    });

    test('active objective filtering uses scaled pace targets', () {
      final objectives =
          GameObjectiveTracker.activeEarlyGameObjectivesForPlayer(
            playerId: 'player_1',
            cities: const [],
            units: const [],
            fieldImprovements: const [],
            fogOfWar: _fog(discoveredCount: 24),
            research: ResearchState.empty,
            paceBalance: PaceBalance.standard60,
          );

      expect(objectives.map((objective) => objective.definition.id), [
        GameObjectiveId.chooseResearch,
        GameObjectiveId.foundCapital,
        GameObjectiveId.queueWorker,
      ]);
    });

    test(
      'advances to worker, improvement, and second city after opening steps',
      () {
        final objectives =
            GameObjectiveTracker.activeEarlyGameObjectivesForPlayer(
              playerId: 'player_1',
              cities: [_city('capital')],
              units: const [],
              fieldImprovements: const [],
              fogOfWar: _fog(discoveredCount: 32),
              research: ResearchState(
                players: {
                  'player_1': PlayerResearchState(
                    activeTechnologyId: TechnologyId.agriculture,
                  ),
                },
              ),
            );

        expect(objectives.map((objective) => objective.definition.id), [
          GameObjectiveId.queueWorker,
          GameObjectiveId.improveFirstHex,
          GameObjectiveId.foundSecondCity,
        ]);
      },
    );

    test('continues with expansion objectives after second city', () {
      final objectives = GameObjectiveTracker.activeObjectivesForPlayer(
        playerId: 'player_1',
        cities: [_city('capital'), _city('second')],
        units: [_unit('worker', GameUnitType.worker)],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 0),
            type: FieldImprovementType.farm,
            builtByCityId: 'capital',
          ),
        ],
        fogOfWar: _fog(discoveredCount: 32),
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );

      expect(objectives.map((objective) => objective.definition.id), [
        GameObjectiveId.buildFirstBuilding,
        GameObjectiveId.improveThreeHexes,
        GameObjectiveId.foundThirdCity,
      ]);
      expect(objectives.first.definition.phase, GameObjectivePhase.expansion);
    });

    test('continues with pressure objectives after expansion goals', () {
      final objectives = GameObjectiveTracker.activeObjectivesForPlayer(
        playerId: 'player_1',
        cities: [
          _city('capital', buildings: const {CityBuildingType.granary}),
          _city('second'),
          _city('third'),
        ],
        units: [
          _unit('worker', GameUnitType.worker),
          _unit('warrior_1', GameUnitType.warrior),
          _unit('warrior_2', GameUnitType.warrior),
        ],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 0),
            type: FieldImprovementType.farm,
            builtByCityId: 'capital',
          ),
          FieldImprovement(
            hex: CityHex(col: 2, row: 0),
            type: FieldImprovementType.mine,
            builtByCityId: 'capital',
          ),
          FieldImprovement(
            hex: CityHex(col: 3, row: 0),
            type: FieldImprovementType.pasture,
            builtByCityId: 'second',
          ),
        ],
        fogOfWar: _fog(discoveredCount: 42),
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );

      expect(objectives.map((objective) => objective.definition.id), [
        GameObjectiveId.exploreRegion,
        GameObjectiveId.buildCombatForce,
      ]);
      expect(objectives.first.definition.phase, GameObjectivePhase.pressure);
    });

    test('prioritizes own domination hold as a strategic objective', () {
      final objectives = GameObjectiveTracker.activeObjectivesForPlayer(
        playerId: 'player_1',
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        fogOfWar: _fog(discoveredCount: 4),
        research: ResearchState.empty,
        dominationHoldTurnsByPlayerId: const {'player_1': 2, 'player_2': 1},
        dominationRequiredHoldTurns: 4,
      );

      expect(objectives.map((objective) => objective.definition.id), [
        GameObjectiveId.holdDomination,
        GameObjectiveId.chooseResearch,
        GameObjectiveId.foundCapital,
      ]);
      expect(objectives.first.definition.track, GameObjectiveTrack.strategic);
      expect(objectives.first.definition.phase, GameObjectivePhase.endgame);
      expect(objectives.first.progressLabel, '2/4');
    });

    test('surfaces opponent domination hold as a strategic threat', () {
      final objectives = GameObjectiveTracker.activeObjectivesForPlayer(
        playerId: 'player_1',
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        fogOfWar: _fog(discoveredCount: 4),
        research: ResearchState.empty,
        dominationHoldTurnsByPlayerId: const {'player_2': 3, 'player_3': 1},
        dominationRequiredHoldTurns: 4,
      );

      expect(objectives.map((objective) => objective.definition.id), [
        GameObjectiveId.breakDominationHold,
        GameObjectiveId.chooseResearch,
        GameObjectiveId.foundCapital,
      ]);
      expect(objectives.first.definition.track, GameObjectiveTrack.strategic);
      expect(objectives.first.definition.tone, GameObjectiveTone.warning);
      expect(objectives.first.progressLabel, '3/4');
    });

    test('uses score pressure when domination cannot finish before cap', () {
      final objectives = GameObjectiveTracker.activeObjectivesForPlayer(
        playerId: 'player_1',
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        fogOfWar: _fog(discoveredCount: 4),
        research: ResearchState.empty,
        dominationHoldTurnsByPlayerId: const {'player_1': 4},
        dominationRequiredHoldTurns: 10,
        scoreByPlayerId: const {'player_1': 94, 'player_2': 88},
        scoreAdviceByPlayerId: const {
          'player_1': GameObjectiveAdvice.protectLead,
        },
        scoreRemainingTurns: 5,
      );

      expect(objectives.map((objective) => objective.definition.id), [
        GameObjectiveId.holdScoreLead,
        GameObjectiveId.chooseResearch,
        GameObjectiveId.foundCapital,
      ]);
      expect(objectives.first.advice, GameObjectiveAdvice.protectLead);
    });

    test('keeps domination priority when hold can finish before cap', () {
      final objectives = GameObjectiveTracker.activeObjectivesForPlayer(
        playerId: 'player_1',
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        fogOfWar: _fog(discoveredCount: 4),
        research: ResearchState.empty,
        dominationHoldTurnsByPlayerId: const {'player_1': 8},
        dominationRequiredHoldTurns: 10,
        scoreByPlayerId: const {'player_1': 94, 'player_2': 88},
        scoreAdviceByPlayerId: const {
          'player_1': GameObjectiveAdvice.protectLead,
        },
        scoreRemainingTurns: 2,
      );

      expect(objectives.map((objective) => objective.definition.id), [
        GameObjectiveId.holdDomination,
        GameObjectiveId.chooseResearch,
        GameObjectiveId.foundCapital,
      ]);
      expect(objectives.first.progressLabel, '8/10');
    });

    test('surfaces score lead hold when score cap is close', () {
      final objectives = GameObjectiveTracker.activeObjectivesForPlayer(
        playerId: 'player_1',
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        fogOfWar: _fog(discoveredCount: 4),
        research: ResearchState.empty,
        scoreByPlayerId: const {'player_1': 94, 'player_2': 88},
        scoreAdviceByPlayerId: const {
          'player_1': GameObjectiveAdvice.protectLead,
        },
        scoreRemainingTurns: 2,
      );

      expect(objectives.map((objective) => objective.definition.id), [
        GameObjectiveId.holdScoreLead,
        GameObjectiveId.chooseResearch,
        GameObjectiveId.foundCapital,
      ]);
      expect(objectives.first.definition.track, GameObjectiveTrack.strategic);
      expect(objectives.first.definition.tone, GameObjectiveTone.victory);
      expect(objectives.first.advice, GameObjectiveAdvice.protectLead);
      expect(objectives.first.progressLabel, '3/5');
    });

    test('surfaces score catch-up when a rival leads near score cap', () {
      final objectives = GameObjectiveTracker.activeObjectivesForPlayer(
        playerId: 'player_1',
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        fogOfWar: _fog(discoveredCount: 4),
        research: ResearchState.empty,
        scoreByPlayerId: const {'player_1': 80, 'player_2': 94},
        scoreAdviceByPlayerId: const {
          'player_1': GameObjectiveAdvice.unlockTechnology,
        },
        scoreRemainingTurns: 5,
      );

      expect(objectives.map((objective) => objective.definition.id), [
        GameObjectiveId.overtakeScoreLeader,
        GameObjectiveId.chooseResearch,
        GameObjectiveId.foundCapital,
      ]);
      expect(objectives.first.definition.track, GameObjectiveTrack.strategic);
      expect(objectives.first.definition.tone, GameObjectiveTone.warning);
      expect(objectives.first.advice, GameObjectiveAdvice.unlockTechnology);
      expect(objectives.first.progressLabel, '80/95');
    });

    test('surfaces own active map objective hold as strategic pressure', () {
      final objectives = GameObjectiveTracker.activeObjectivesForPlayer(
        playerId: 'player_1',
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        fogOfWar: _fog(discoveredCount: 4),
        research: ResearchState.empty,
        mapObjectiveProgress: [
          _mapObjectiveProgress(
            controllingPlayerId: 'player_1',
            holdTurns: 2,
            requiredHoldTurns: 4,
          ),
        ],
      );

      expect(objectives.map((objective) => objective.definition.id), [
        GameObjectiveId.secureMapObjective,
        GameObjectiveId.chooseResearch,
        GameObjectiveId.foundCapital,
      ]);
      expect(objectives.first.definition.track, GameObjectiveTrack.strategic);
      expect(objectives.first.progressLabel, '2/4');
      expect(objectives.first.advice, GameObjectiveAdvice.claimTerritory);
    });

    test('prioritizes breaking rival map objective holds', () {
      final objectives = GameObjectiveTracker.activeObjectivesForPlayer(
        playerId: 'player_1',
        cities: const [],
        units: const [],
        fieldImprovements: const [],
        fogOfWar: _fog(discoveredCount: 4),
        research: ResearchState.empty,
        mapObjectiveProgress: [
          _mapObjectiveProgress(
            controllingPlayerId: 'player_1',
            holdTurns: 2,
            requiredHoldTurns: 4,
          ),
          _mapObjectiveProgress(
            id: 'holy_1',
            controllingPlayerId: 'player_2',
            holdTurns: 2,
            requiredHoldTurns: 3,
            victoryPoints: 4,
          ),
        ],
      );

      expect(objectives.map((objective) => objective.definition.id), [
        GameObjectiveId.breakMapObjectiveHold,
        GameObjectiveId.chooseResearch,
        GameObjectiveId.foundCapital,
      ]);
      expect(objectives.first.definition.tone, GameObjectiveTone.warning);
      expect(objectives.first.progressLabel, '2/3');
      expect(objectives.first.advice, GameObjectiveAdvice.trainUnit);
    });

    test('counts queued workers and improvements built by owned cities', () {
      final progress = GameObjectiveTracker.earlyGameProgressForPlayer(
        playerId: 'player_1',
        cities: [
          _city(
            'capital',
            productionQueue: CityProductionQueue.unit(
              unitType: GameUnitType.worker,
              investedProduction: 2,
            ),
          ),
          _city('second'),
        ],
        units: const [],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 0),
            type: FieldImprovementType.farm,
            builtByCityId: 'capital',
          ),
          FieldImprovement(
            hex: CityHex(col: 3, row: 0),
            type: FieldImprovementType.mine,
            builtByCityId: 'enemy_city',
          ),
        ],
        fogOfWar: _fog(discoveredCount: 32),
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );

      expect(
        _progressFor(progress, GameObjectiveId.queueWorker).completed,
        true,
      );
      expect(
        _progressFor(progress, GameObjectiveId.improveFirstHex).currentValue,
        1,
      );
      expect(
        _progressFor(progress, GameObjectiveId.foundSecondCity).completed,
        true,
      );
    });
  });
}

GameCity _city(
  String id, {
  CityProductionQueue? productionQueue,
  Set<CityBuildingType> buildings = const {},
}) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: id,
    center: const CityHex(col: 0, row: 0),
    buildings: buildings,
    productionQueue: productionQueue,
  );
}

GameUnit _unit(String id, GameUnitType type) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: type,
    name: type.defaultNameToken,
    col: 0,
    row: 0,
  );
}

MapObjectiveProgress _mapObjectiveProgress({
  String id = 'pass_1',
  required String controllingPlayerId,
  required int holdTurns,
  int requiredHoldTurns = 3,
  int victoryPoints = 3,
}) {
  return MapObjectiveProgress(
    definition: MapObjectiveDefinition(
      id: id,
      type: MapObjectiveType.strategicPass,
      hex: const CityHex(col: 2, row: 1),
      requiredHoldTurns: requiredHoldTurns,
      victoryPoints: victoryPoints,
    ),
    controllingPlayerId: controllingPlayerId,
    holdTurns: holdTurns,
  );
}

FogOfWarState _fog({required int discoveredCount}) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: {
          for (var i = 0; i < discoveredCount; i++)
            HexCoordinate(col: i, row: 0),
        },
      ),
    },
  );
}

GameObjectiveProgress _progressFor(
  List<GameObjectiveProgress> progress,
  GameObjectiveId id,
) {
  return progress.singleWhere((objective) => objective.definition.id == id);
}

Map<GameObjectiveId, int> _targetsById(List<GameObjectiveProgress> progress) {
  return {
    for (final objective in progress)
      objective.definition.id: objective.definition.targetValue,
  };
}

int _targetFor(List<GameObjectiveProgress> progress, GameObjectiveId id) {
  return _progressFor(progress, id).definition.targetValue;
}
