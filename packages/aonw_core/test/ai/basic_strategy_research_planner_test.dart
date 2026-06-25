import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_research_planner.dart';
import 'package:aonw_core/ai/technology_scorer.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyResearchPlanner', () {
    test('selects the technology returned by the scorer', () {
      final scorer = _RecordingTechnologyScorer(TechnologyId.agriculture);
      final view = _view();

      final commands = BasicStrategyResearchPlanner(
        technologyScorer: scorer,
      ).plan(view, _context(view), _assessment);

      expect(scorer.calls, 1);
      expect(commands, [
        const SelectTechnologyCommand('player_1', TechnologyId.agriculture),
      ]);
    });

    test('does not ask the scorer while research is already active', () {
      final scorer = _RecordingTechnologyScorer(TechnologyId.agriculture);
      final view = _view(
        research: PlayerResearchState(activeTechnologyId: TechnologyId.mining),
      );

      final commands = BasicStrategyResearchPlanner(
        technologyScorer: scorer,
      ).plan(view, _context(view), _assessment);

      expect(scorer.calls, 0);
      expect(commands, isEmpty);
    });

    test('returns no command when no technology is available', () {
      final scorer = _RecordingTechnologyScorer(null);
      final view = _view();

      final commands = BasicStrategyResearchPlanner(
        technologyScorer: scorer,
      ).plan(view, _context(view), _assessment);

      expect(scorer.calls, 1);
      expect(commands, isEmpty);
    });
  });
}

GameView _view({PlayerResearchState research = PlayerResearchState.empty}) {
  return GameView(
    forPlayerId: 'player_1',
    turn: 1,
    ownUnits: const [],
    ownCities: const [],
    ownResearch: research,
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

final class _RecordingTechnologyScorer extends AiTechnologyScorer {
  _RecordingTechnologyScorer(this.pick);

  final TechnologyId? pick;
  var calls = 0;

  @override
  TechnologyId? pickTechnology({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    StrategicMode? mode,
  }) {
    calls++;
    return pick;
  }
}

const _assessment = AiEmpireAssessment(
  playerId: 'player_1',
  cityCount: 0,
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
