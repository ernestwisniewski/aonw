import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('builds one indexed map view and shares it with AI planning', () {
    final mapData = _CountingMapData();
    final strategy = _MapViewCapturingStrategy();

    EconomySimulation.run(
      config: EconomySimulationConfig(
        turns: 1,
        strategyOverride: strategy,
        mapData: mapData,
      ),
    );

    expect(mapData.indexedReadViewCalls, 1);
    expect(strategy.gameViews, hasLength(1));
    expect(strategy.contextViews, hasLength(1));
    expect(strategy.gameViews.single, same(mapData.indexedView));
    expect(strategy.contextViews.single, same(mapData.indexedView));
  });

  test('validates tiles before map metadata like canonical freezing', () {
    final mapData = MapData(
      cols: 0,
      rows: 1,
      tiles: const [
        TileData(col: 0, row: 0, terrains: [], resources: [], height: 0),
      ],
    );

    expect(
      () => EconomySimulation.run(
        config: EconomySimulationConfig(turns: 0, mapData: mapData),
      ),
      throwsA(
        isA<WorldMapException>().having(
          (error) => error.message,
          'message',
          'Tile terrains must not be empty',
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

final class _CountingMapData extends MapData {
  _CountingMapData()
    : super(
        cols: 9,
        rows: 9,
        mapName: 'counting_economy_simulation',
        tiles: [
          for (var row = 0; row < 9; row++)
            for (var col = 0; col < 9; col++)
              TileData(
                col: col,
                row: row,
                terrains: const [TerrainType.grassland],
                resources: const [],
                height: 0,
              ),
        ],
      );

  int indexedReadViewCalls = 0;
  MapReadView? indexedView;

  @override
  MapReadView indexedReadView() {
    indexedReadViewCalls += 1;
    return indexedView = super.indexedReadView();
  }
}
