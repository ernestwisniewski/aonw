import 'package:aonw_core/ai/mcts/mcts_simulated_economy_command_applier.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsSimulatedEconomyCommandApplier city founding', () {
    test('updates only the own founding fragment on acceptance', () {
      final (:applier, :view) = _applier();

      final result = applier.applyFoundCity(
        FoundCityCommand(
          'settler_1',
          controlledHexes: const [
            CityHex(col: 1, row: 0),
            CityHex(col: 2, row: 0),
          ],
        ),
      );

      expect(result.nextOwnUnits, hasLength(2));
      expect(result.nextOwnUnits.first, same(view.ownUnits.first));
      final founder = result.nextOwnUnits.last;
      expect(founder.id, 'settler_1');
      expect(founder.movementPoints, 0);
      expect(founder.queuedPath, isNull);
      expect(founder.cityFoundingJob, isNotNull);
      expect(result.nextVisibleEnemyUnits, same(view.visibleEnemyUnits));
      expect(result.nextOwnCities, same(view.ownCities));
      expect(
        result.nextRememberedEnemyCities,
        same(view.rememberedEnemyCities),
      );
      expect(result.nextOwnResearch, same(view.ownResearch));
    });

    test('preserves every fragment identity on rejection', () {
      final (:applier, :view) = _applier();

      final result = applier.applyFoundCity(
        FoundCityCommand(
          'settler_1',
          controlledHexes: const [
            CityHex(col: 1, row: 0),
            CityHex(col: 1, row: 0),
          ],
        ),
      );

      expect(result.nextOwnUnits, same(view.ownUnits));
      expect(result.nextVisibleEnemyUnits, same(view.visibleEnemyUnits));
      expect(result.nextOwnCities, same(view.ownCities));
      expect(
        result.nextRememberedEnemyCities,
        same(view.rememberedEnemyCities),
      );
      expect(result.nextOwnResearch, same(view.ownResearch));
    });
  });
}

({MctsSimulatedEconomyCommandApplier applier, GameView view}) _applier() {
  final sentinel = GameUnit.produced(
    id: 'warrior_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    col: 3,
    row: 0,
  );
  final founder =
      GameUnit.produced(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        col: 0,
        row: 0,
      ).copyWithQueuedPath(
        QueuedMovePath(
          targetCol: 1,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
      );
  final enemy = GameUnit.produced(
    id: 'enemy_1',
    ownerPlayerId: 'player_2',
    type: GameUnitType.warrior,
    col: 4,
    row: 0,
  );
  final state = PersistentGameState(
    units: [sentinel, founder, enemy],
    research: ResearchState(
      players: {'player_1': PlayerResearchState(scienceOverflow: 7)},
    ),
    fogOfWar: FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(
          playerId: 'player_1',
          visibleHexes: {
            for (var col = 0; col < 5; col++) HexCoordinate(col: col, row: 0),
          },
        ),
      },
    ),
  );
  final view = GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 1,
    mapData: _mapData,
    ruleset: GameRuleset.defaults,
  );
  return (
    applier: MctsSimulatedEconomyCommandApplier(
      view: view,
      ownUnits: view.ownUnits,
      visibleEnemyUnits: view.visibleEnemyUnits,
      ownCities: view.ownCities,
      rememberedEnemyCities: view.rememberedEnemyCities,
      ownResearch: view.ownResearch,
    ),
    view: view,
  );
}

final _mapData = MapData(
  cols: 5,
  rows: 1,
  tiles: [
    for (var col = 0; col < 5; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.plains],
        resources: const [],
        height: 0,
      ),
  ],
);
