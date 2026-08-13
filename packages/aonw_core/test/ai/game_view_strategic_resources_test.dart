import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('GameView projects only active player strategic resource state', () {
    final state = DomainState.snapshot(
      matchRules: MatchRules.standard,
      strategicResources: StrategicResourceAccounts(
        byPlayerId: {
          'player_1': StrategicResourceStockpile(
            onHand: StrategicResourceBundle.oilTwo,
          ),
          'player_2': StrategicResourceStockpile(
            onHand: StrategicResourceBundle.aluminiumOne,
          ),
        },
      ),
    );

    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 4,
      mapData: _mapData(),
      ruleset: GameRuleset.defaults,
    );

    expect(view.ownStrategicResources.onHand, StrategicResourceBundle.oilTwo);
    expect(view.ownStrategicResources.amountFor(ResourceType.aluminium), 0);
  });
}

WorldMap _mapData() => WorldMap(
  cols: 1,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
