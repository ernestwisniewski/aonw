import 'package:aonw_core/ai/mcts/mcts_opponent_view_index.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsOpponentViewIndex', () {
    test('returns sorted opponents and keeps active player in known ids', () {
      final state = PersistentGameState(
        units: [
          _unit('unit_3', 'player_3', col: 3),
          _unit('unit_1', 'player_1'),
        ],
        cities: [_city('city_2', 'player_2', col: 2)],
      );

      final index = MctsOpponentViewIndex.fromState(state);

      expect(index.opponentPlayerIds('player_1'), ['player_2', 'player_3']);
      expect(index.knownPlayerIds('player_1'), [
        'player_1',
        'player_2',
        'player_3',
      ]);
    });

    test('builds opponent view from indexed state slices', () {
      final playerCity = _city('city_1', 'player_1');
      final opponentCity = _city(
        'city_2',
        'player_2',
        col: 2,
        controlledHexes: const [CityHex(col: 3, row: 0)],
      );
      final otherCity = _city('city_3', 'player_3', col: 4);
      final ownedByCity = FieldImprovement(
        hex: opponentCity.center,
        type: FieldImprovementType.farm,
        builtByCityId: opponentCity.id,
      );
      const controlledByCity = FieldImprovement(
        hex: CityHex(col: 3, row: 0),
        type: FieldImprovementType.mine,
      );
      final playerImprovement = FieldImprovement(
        hex: playerCity.center,
        type: FieldImprovementType.camp,
        builtByCityId: playerCity.id,
      );
      final state = PersistentGameState(
        playerGold: const {'player_2': 7},
        playerWarWeariness: const {'player_2': 2},
        playerStabilityNet: const {'player_2': -1},
        units: [
          _unit('unit_1', 'player_1'),
          _unit('unit_2', 'player_2', col: 2),
          _unit('unit_3', 'player_3', col: 4),
        ],
        cities: [playerCity, opponentCity, otherCity],
        fieldImprovements: [ownedByCity, controlledByCity, playerImprovement],
      );

      final view = MctsOpponentViewIndex.fromState(state).viewFor(
        state: state,
        opponentId: 'player_2',
        turn: 5,
        mapData: MapData(cols: 5, rows: 1, tiles: const []),
        ruleset: GameRuleset.standard(),
      );

      expect(view.forPlayerId, 'player_2');
      expect(view.turn, 5);
      expect(view.ownGold, 7);
      expect(view.ownWarWeariness, 2);
      expect(view.ownStabilityNet, -1);
      expect(view.ownUnits.map((unit) => unit.id), ['unit_2']);
      expect(view.ownCities.map((city) => city.id), ['city_2']);
      expect(view.ownImprovements, [ownedByCity, controlledByCity]);
      expect(view.visibleEnemyUnits.map((unit) => unit.id), [
        'unit_1',
        'unit_3',
      ]);
      expect(view.rememberedEnemyCities.map((city) => city.id), [
        'city_1',
        'city_3',
      ]);
      expect(view.visibility.isEnabled, isFalse);
    });
  });
}

GameUnit _unit(String id, String ownerPlayerId, {int col = 0}) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.warrior,
    col: col,
    row: 0,
  );
}

GameCity _city(
  String id,
  String ownerPlayerId, {
  int col = 0,
  List<CityHex> controlledHexes = const [],
}) {
  return GameCity(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: CityHex(col: col, row: 0),
    controlledHexes: controlledHexes,
  );
}
