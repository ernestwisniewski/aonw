import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsNode', () {
    test('records visits and average score', () {
      final node = MctsNode(state: _state())
        ..record(0.25)
        ..record(0.75);

      expect(node.visits, 2);
      expect(node.averageScore, 0.5);
    });

    test('prefers unvisited children with UCB1', () {
      final root = MctsNode(state: _state())..record(0.2);
      root
          .addChild(action: const EndPlanningAction(), state: _state())
          .record(0.2);
      final unvisited = root.addChild(
        action: const CommandMctsAction(
          SelectTechnologyCommand('player_1', TechnologyId.agriculture),
        ),
        state: _state(),
      );

      expect(root.bestChildByUcb(explorationConstant: 1.4), same(unvisited));
    });
  });
}

SimulatedState _state() {
  return SimulatedState.fromView(_view(), maxPlanningDepth: 3);
}

GameView _view() {
  final mapData = MapData(cols: 1, rows: 1, tiles: const []);
  return GameView.fromPersistentState(
    const PersistentGameState(),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}
