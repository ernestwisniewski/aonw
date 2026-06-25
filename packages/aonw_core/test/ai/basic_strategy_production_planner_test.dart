import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/production_scorer.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_production_planner.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyProductionPlanner', () {
    test(
      'plans production in deterministic city order and skips unchanged',
      () {
        final scorer = _ScriptedProductionScorer(<String, CityProductionTarget>{
          'city_a': const UnitProductionTarget(GameUnitType.worker),
          'city_b': const BuildingProductionTarget(CityBuildingType.granary),
          'city_c': const ProjectProductionTarget(CityProjectType.wealth),
        });
        final view = _view(
          cities: [
            _city('city_b', col: 1),
            _city(
              'city_c',
              col: 2,
              productionQueue: CityProductionQueue.project(
                projectType: CityProjectType.wealth,
              ),
            ),
            _city('city_a'),
            _city(
              'city_d',
              col: 3,
              productionQueue: CityProductionQueue.unit(
                unitType: GameUnitType.warrior,
                investedProduction: 0,
              ),
            ),
            _city(
              'city_recon_queue',
              col: 4,
              productionQueue: CityProductionQueue.unit(
                unitType: GameUnitType.scout,
                investedProduction: 0,
              ),
            ),
          ],
          units: [
            GameUnit.produced(
              id: 'scout_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.scout,
              col: 0,
              row: 1,
            ),
          ],
        );

        final commands = BasicStrategyProductionPlanner(
          scorer: scorer,
        ).plan(view, _context(view), _assessment, hasPlannedResearch: true);

        expect(scorer.cityIds, ['city_a', 'city_b', 'city_c']);
        expect(commands, const [
          StartUnitProductionCommand('city_a', GameUnitType.worker),
          StartBuildingCommand('city_b', CityBuildingType.granary),
        ]);
        expect(scorer.planStates.first.hasPlannedResearch, isTrue);
        expect(scorer.planStates.first.reconCount, 2);
        expect(scorer.planStates[1].workerCount, _assessment.workerCount + 1);
      },
    );

    test(
      'does not ask scorer when all cities have non-reassignable queues',
      () {
        final scorer = _ScriptedProductionScorer(
          <String, CityProductionTarget>{},
        );
        final view = _view(
          cities: [
            _city(
              'city_a',
              productionQueue: CityProductionQueue.unit(
                unitType: GameUnitType.warrior,
                investedProduction: 0,
              ),
            ),
          ],
        );

        final commands = BasicStrategyProductionPlanner(
          scorer: scorer,
        ).plan(view, _context(view), _assessment, hasPlannedResearch: false);

        expect(scorer.cityIds, isEmpty);
        expect(commands, isEmpty);
      },
    );
  });
}

GameView _view({
  required List<GameCity> cities,
  List<GameUnit> units = const [],
}) {
  return GameView(
    forPlayerId: 'player_1',
    turn: 1,
    ownUnits: units,
    ownCities: cities,
    ownResearch: PlayerResearchState.empty,
    ownImprovements: const [],
    visibleEnemyUnits: const [],
    rememberedEnemyCities: const [],
    visibility: const FogVisibilityQuery(
      playerId: 'player_1',
      state: FogOfWarState.empty,
    ),
    mapData: _mapData,
    ruleset: _ruleset,
  );
}

GameCity _city(String id, {int col = 0, CityProductionQueue? productionQueue}) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: id,
    center: CityHex(col: col, row: 0),
    productionQueue: productionQueue,
  );
}

AiContext _context(GameView view) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 7,
    ),
  );
}

final class _ScriptedProductionScorer extends AiProductionScorer {
  _ScriptedProductionScorer(this.targetsByCityId);

  final Map<String, CityProductionTarget> targetsByCityId;
  final cityIds = <String>[];
  final planStates = <AiProductionPlanState>[];

  @override
  AiProductionRecommendation recommend({
    required GameCity city,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiProductionPlanState planState,
  }) {
    cityIds.add(city.id);
    planStates.add(planState);
    final target = targetsByCityId[city.id];
    if (target == null) {
      throw StateError('Missing scripted production target for ${city.id}');
    }
    return AiProductionRecommendation(
      cityId: city.id,
      target: target,
      score: 1,
      reason: 'scripted',
    );
  }
}

const _assessment = AiEmpireAssessment(
  playerId: 'player_1',
  cityCount: 5,
  workerCount: 0,
  settlerCount: 0,
  militaryCount: 0,
  visibleEnemyMilitaryCount: 0,
  goldReserve: 0,
  netGoldPerTurn: 0,
  desiredCityCount: 0,
  desiredWorkerCount: 0,
  desiredMilitaryCount: 0,
);

final _mapData = MapData(cols: 0, rows: 0, tiles: const []);
final _ruleset = GameRuleset.standard();
