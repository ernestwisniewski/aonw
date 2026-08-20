import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('shares the canonical indexed WorldMap with AI planning', () {
    final worldMap = _worldMap();
    final strategy = _MapViewCapturingStrategy();

    EconomySimulation.run(
      config: EconomySimulationConfig(
        turns: 1,
        strategyOverride: strategy,
        mapData: worldMap,
      ),
    );

    expect(strategy.gameViews, hasLength(1));
    expect(strategy.contextViews, hasLength(1));
    expect(strategy.gameViews.single, same(worldMap));
    expect(strategy.contextViews.single, same(worldMap));
  });

  test('validates tiles before map metadata like canonical freezing', () {
    expect(
      () => WorldMap(
        cols: 0,
        rows: 1,
        tiles: [
          WorldTile(col: 0, row: 0, terrains: [], resources: [], height: 0),
        ],
      ),
      throwsA(
        isA<TileTerrainSemanticsException>().having(
          (error) => error.message,
          'message',
          'Authored terrain tags must not be empty',
        ),
      ),
    );
  });
}

final class _MapViewCapturingStrategy implements AiStrategy {
  final List<MapReadView> gameViews = [];
  final List<MapReadView> contextViews = [];

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    gameViews.add(view.mapData);
    contextViews.add(context.mapData);
    return AiTurnPlan(commands: const []);
  }
}

WorldMap _worldMap() {
  return WorldMap(
    cols: 9,
    rows: 9,
    mapName: 'economy_simulation',
    tiles: [
      for (var row = 0; row < 9; row++)
        for (var col = 0; col < 9; col++)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
