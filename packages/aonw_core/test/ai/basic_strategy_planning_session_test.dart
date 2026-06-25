import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_planning_session.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyPlanningSession', () {
    test('runs command phases and records notes, commands and used units', () {
      final session = BasicStrategyPlanningSession(
        view: GameView(
          forPlayerId: 'player_1',
          turn: 1,
          ownUnits: const [],
          ownCities: const [],
          ownResearch: PlayerResearchState.empty,
          ownImprovements: const [],
          visibleEnemyUnits: const [],
          rememberedEnemyCities: const [],
          visibility: const FogVisibilityQuery(
            playerId: '',
            state: FogOfWarState.empty,
          ),
          mapData: MapData(cols: 0, rows: 0, tiles: const []),
          ruleset: GameRuleset.standard(),
        ),
      );

      final commands = session.runCommandPhase(
        'move',
        () => const [MoveUnitCommand('scout', 1, 1)],
        notesFor: (commands) => ['planned ${commands.length} move'],
      );

      expect(commands, hasLength(1));
      expect(session.commands, commands);
      expect(session.notes, ['planned 1 move']);
      expect(session.usedUnitIds, {'scout'});
      expect(
        session.finish(strategyId: 'basic').debug?.metrics.keys,
        contains('basic.moveMicros'),
      );
    });
  });

  group('BasicStrategyCommandAnalysis', () {
    test('extracts unit ids from strategy commands', () {
      expect(
        BasicStrategyCommandAnalysis.unitIdsUsedBy([
          const MoveUnitCommand('scout', 1, 1),
          const FoundCityCommand('settler'),
          const AttackHexCommand('warrior', 2, 2),
          const EndTurnCommand('player_1'),
        ]),
        {'scout', 'settler', 'warrior'},
      );
    });
  });
}
