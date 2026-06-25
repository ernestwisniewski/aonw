import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_objective_summary.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_modes.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudObjectiveSummary', () {
    test('is empty without an active player', () {
      final summary = HudObjectiveSummary.fromGameState(
        state: const GameState(),
        activePlayerId: '',
        modes: const HudPanelModes(objectives: true),
        cityProductionOpen: false,
        resourceBreakdownOpen: false,
      );

      expect(summary.activeObjectives, isEmpty);
      expect(summary.showOverlay, isFalse);
    });

    test('shows objective overlay when objectives panel is active', () {
      final summary = HudObjectiveSummary.fromGameState(
        state: const GameState(),
        activePlayerId: 'player_1',
        modes: const HudPanelModes(objectives: true),
        cityProductionOpen: false,
        resourceBreakdownOpen: false,
      );

      expect(summary.activeObjectives, hasLength(3));
      expect(summary.showOverlay, isTrue);
    });

    test('passes pace balance to objective targets', () {
      final summary = HudObjectiveSummary.fromGameState(
        state: GameState(fogOfWar: _fog(discoveredCount: 4)),
        activePlayerId: 'player_1',
        modes: const HudPanelModes(objectives: true),
        cityProductionOpen: false,
        resourceBreakdownOpen: false,
        paceBalance: PaceBalance.standard60,
      );

      expect(
        summary.activeObjectives[2].definition.id,
        GameObjectiveId.exploreNearby,
      );
      expect(summary.activeObjectives[2].progressLabel, '4/24');
    });

    test('prepends domination pressure objective when hold is active', () {
      final summary = HudObjectiveSummary.fromGameState(
        state: const GameState(dominationHoldTurnsByPlayerId: {'player_2': 2}),
        activePlayerId: 'player_1',
        modes: const HudPanelModes(objectives: true),
        cityProductionOpen: false,
        resourceBreakdownOpen: false,
        dominationRequiredHoldTurns: 4,
      );

      expect(
        summary.activeObjectives.map((objective) => objective.definition.id),
        [
          GameObjectiveId.breakDominationHold,
          GameObjectiveId.chooseResearch,
          GameObjectiveId.foundCapital,
        ],
      );
      expect(summary.activeObjectives.first.progressLabel, '2/4');
      expect(summary.showOverlay, isTrue);
    });

    test('prepends score pressure objective when score cap is close', () {
      const activeScore = EmpireScoreBreakdown(
        playerId: 'player_1',
        cityScore: 40,
        populationScore: 12,
        territoryScore: 6,
        buildingScore: 0,
        unitScore: 10,
        technologyScore: 0,
        improvementScore: 5,
        goldScore: 7,
      );
      const leaderScore = EmpireScoreBreakdown(
        playerId: 'player_2',
        cityScore: 40,
        populationScore: 12,
        territoryScore: 6,
        buildingScore: 8,
        unitScore: 10,
        technologyScore: 12,
        improvementScore: 5,
        goldScore: 2,
      );
      final summary = HudObjectiveSummary.fromGameState(
        state: const GameState(),
        activePlayerId: 'player_1',
        modes: const HudPanelModes(objectives: true),
        cityProductionOpen: false,
        resourceBreakdownOpen: false,
        scoreByPlayerId: {
          'player_1': activeScore.total,
          'player_2': leaderScore.total,
        },
        scoreAdviceByPlayerId: const {
          'player_1': GameObjectiveAdvice.unlockTechnology,
        },
        scoreBreakdownByPlayerId: const {
          'player_1': activeScore,
          'player_2': leaderScore,
        },
        scoreRemainingTurns: 5,
      );

      expect(
        summary.activeObjectives.map((objective) => objective.definition.id),
        [
          GameObjectiveId.overtakeScoreLeader,
          GameObjectiveId.chooseResearch,
          GameObjectiveId.foundCapital,
        ],
      );
      expect(summary.activeObjectives.first.progressLabel, '80/96');
      expect(
        summary.activeObjectives.first.advice,
        GameObjectiveAdvice.unlockTechnology,
      );
      expect(
        summary.scoreBreakdown?.mode,
        HudObjectiveScoreBreakdownMode.catchUp,
      );
      expect(summary.scoreBreakdown?.delta, 15);
      expect(
        summary.scoreBreakdown?.rows.first.advice,
        GameObjectiveAdvice.unlockTechnology,
      );
      expect(summary.scoreBreakdown?.rows.first.delta, 12);
      expect(summary.showOverlay, isTrue);
    });

    test('prepends map objective pressure when a rival hold is active', () {
      final summary = HudObjectiveSummary.fromGameState(
        state: GameState(
          units: [
            GameUnit.startingWarrior(ownerPlayerId: 'player_2', col: 2, row: 1),
          ],
          mapObjectiveHoldStatesByObjectiveId: const {
            'pass_1': MapObjectiveHoldState(
              objectiveId: 'pass_1',
              playerId: 'player_2',
              holdTurns: 2,
            ),
          },
        ),
        mapData: MapData(
          cols: 4,
          rows: 4,
          tiles: const [],
          objectives: const [
            MapObjectiveDefinition(
              id: 'pass_1',
              type: MapObjectiveType.strategicPass,
              hex: CityHex(col: 2, row: 1),
              requiredHoldTurns: 3,
              victoryPoints: 3,
            ),
          ],
        ),
        activePlayerId: 'player_1',
        modes: const HudPanelModes(objectives: true),
        cityProductionOpen: false,
        resourceBreakdownOpen: false,
      );

      expect(
        summary.activeObjectives.map((objective) => objective.definition.id),
        [
          GameObjectiveId.breakMapObjectiveHold,
          GameObjectiveId.chooseResearch,
          GameObjectiveId.foundCapital,
        ],
      );
      expect(summary.activeObjectives.first.progressLabel, '2/3');
      expect(summary.showOverlay, isTrue);
    });

    test('continues objectives after early-game goals', () {
      final summary = HudObjectiveSummary.fromGameState(
        state: GameState(
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
              center: CityHex(col: 1, row: 0),
            ),
          ],
          units: [
            GameUnit(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              name: 'Worker',
              col: 0,
              row: 0,
            ),
          ],
          fieldImprovements: const [
            FieldImprovement(
              hex: CityHex(col: 1, row: 0),
              type: FieldImprovementType.farm,
              builtByCityId: 'capital',
            ),
          ],
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                discoveredHexes: {
                  for (var i = 0; i < 32; i++) HexCoordinate(col: i, row: 0),
                },
              ),
            },
          ),
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        ),
        activePlayerId: 'player_1',
        modes: const HudPanelModes(objectives: true),
        cityProductionOpen: false,
        resourceBreakdownOpen: false,
      );

      expect(
        summary.activeObjectives.map((objective) => objective.definition.id),
        [
          GameObjectiveId.buildFirstBuilding,
          GameObjectiveId.improveThreeHexes,
          GameObjectiveId.foundThirdCity,
        ],
      );
      expect(summary.showOverlay, isTrue);
    });

    test('hides objective overlay behind competing panels', () {
      final summary = HudObjectiveSummary.fromGameState(
        state: const GameState(),
        activePlayerId: 'player_1',
        modes: const HudPanelModes(objectives: true, technology: true),
        cityProductionOpen: false,
        resourceBreakdownOpen: false,
      );

      expect(summary.activeObjectives, isNotEmpty);
      expect(summary.showOverlay, isFalse);
    });
  });
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
