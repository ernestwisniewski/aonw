import 'package:aonw_core/ai/mcts/mcts_opponent_view_index.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsOpponentViewIndex', () {
    test('returns sorted opponents and keeps active player in known ids', () {
      final state = DomainState.snapshot(
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
      final state = DomainState.snapshot(
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
        mapData: WorldMap(cols: 5, rows: 1, tiles: []),
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

    test('shows only the opponent owned stored and carried artifacts', () {
      final state = _artifactVisibilityState();
      final index = MctsOpponentViewIndex.fromState(state);
      final view = _viewFor(index, state, 'player_2');

      expect(view.artifacts.map((artifact) => artifact.id), [
        'opponent_stored',
        'opponent_carried',
      ]);
      expect(
        _viewFor(
          index,
          state,
          'player_1',
        ).artifacts.map((artifact) => artifact.id),
        ['active_stored', 'active_carried'],
      );
      expect(
        _viewFor(
          index,
          state,
          'player_3',
        ).artifacts.map((artifact) => artifact.id),
        ['other_stored', 'other_carried'],
      );
      expect(_viewFor(index, state, 'missing').artifacts, isEmpty);
      expect(state.artifacts, hasLength(10));
      expect(() => view.artifacts.clear(), throwsUnsupportedError);
    });
  });
}

DomainState _artifactVisibilityState() {
  return DomainState.snapshot(
    units: [
      _unit('unit_1', 'player_1'),
      _unit('unit_2', 'player_2', col: 2),
      _unit('unit_3', 'player_3', col: 4),
    ],
    cities: [
      _city('city_1', 'player_1'),
      _city('city_2', 'player_2', col: 2),
      _city('city_3', 'player_3', col: 4),
    ],
    artifacts: _visibilityArtifacts,
  );
}

GameView _viewFor(
  MctsOpponentViewIndex index,
  DomainState state,
  String playerId,
) {
  return index.viewFor(
    state: state,
    opponentId: playerId,
    turn: 1,
    mapData: WorldMap(cols: 5, rows: 1, tiles: []),
    ruleset: GameRuleset.standard(),
  );
}

const _visibilityArtifacts = [
  WorldArtifact(
    id: 'active_stored',
    type: WorldArtifactType.merchantsSeal,
    location: WorldArtifactLocation.stored(cityId: 'city_1'),
  ),
  WorldArtifact(
    id: 'active_carried',
    type: WorldArtifactType.queensMirror,
    location: WorldArtifactLocation.carried(unitId: 'unit_1'),
  ),
  WorldArtifact(
    id: 'opponent_stored',
    type: WorldArtifactType.astronomersTablets,
    location: WorldArtifactLocation.stored(cityId: 'city_2'),
  ),
  WorldArtifact(
    id: 'opponent_carried',
    type: WorldArtifactType.heroSword,
    location: WorldArtifactLocation.carried(unitId: 'unit_2'),
  ),
  WorldArtifact(
    id: 'other_stored',
    type: WorldArtifactType.prophetMask,
    location: WorldArtifactLocation.stored(cityId: 'city_3'),
  ),
  WorldArtifact(
    id: 'other_carried',
    type: WorldArtifactType.ancientImperialCrown,
    location: WorldArtifactLocation.carried(unitId: 'unit_3'),
  ),
  WorldArtifact(
    id: 'map_artifact',
    type: WorldArtifactType.firstPeoplesChronicle,
    location: WorldArtifactLocation.map(col: 2, row: 0),
  ),
  WorldArtifact(
    id: 'excavation_artifact',
    type: WorldArtifactType.templeReliquary,
    location: WorldArtifactLocation.excavation(
      unitId: 'unit_2',
      col: 2,
      row: 0,
      remainingTurns: 1,
    ),
  ),
  WorldArtifact(
    id: 'dangling_stored',
    type: WorldArtifactType.queensMirror,
    location: WorldArtifactLocation.stored(cityId: 'missing_city'),
  ),
  WorldArtifact(
    id: 'dangling_carried',
    type: WorldArtifactType.ancientImperialCrown,
    location: WorldArtifactLocation.carried(unitId: 'missing_unit'),
  ),
];

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
