import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

GameStateTransition resolveEndTurnForTest(
  GameState state,
  String playerId,
  MapReadView mapView, {
  CityRuleset cityRuleset = CityRulesets.standard,
  TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
  WonderRuleset wonderRuleset = WonderRuleset.standard,
  VictoryRules victoryRules = VictoryRules.standard,
  int turn = 1,
}) {
  final playerIds = _playerIds(state, playerId);
  final players = [
    for (final id in playerIds)
      Player(
        id: id,
        name: id,
        colorValue: state.playerColors[id] ?? 0,
        country: state.playerCountries[id] ?? PlayerCountry.poland,
      ),
  ];
  final savedAt = DateTime.utc(2026, 1, 1);
  final save = GameSave(
    id: 'turn_engine_test',
    name: 'Turn engine test',
    mapName: mapView.mapName ?? 'turn_engine_test',
    turn: turn,
    playerStates: {for (final id in playerIds) id: PlayerTurnState.active},
    savedAt: savedAt,
    camera: CameraState.zero,
    matchRules: MatchRules.standard.copyWith(victory: victoryRules),
    players: players,
  );
  final ruleset = GameRuleset.standard().copyWith(
    city: cityRuleset,
    technology: technologyRuleset,
    stability: stabilityRuleset,
    wonders: wonderRuleset,
  );
  final resolution =
      LocalCommandResolver(
        reducer: GameStateReducer(mapData: mapView, ruleset: ruleset),
      ).resolve(
        baseSnapshot: SaveSnapshot.fromGameState(save: save, state: state),
        currentState: state,
        command: EndTurnCommand(playerId),
        savedAt: savedAt,
      );
  return GameStateTransition(
    state: resolution.state,
    events: resolution.events,
    uiEffects: resolution.uiEffects,
  );
}

List<String> _playerIds(GameState state, String actorPlayerId) {
  final ids = <String>{
    actorPlayerId,
    ...state.playerColors.keys,
    ...state.playerCountries.keys,
    ...state.playerGold.keys,
    ...state.playerWarWeariness.keys,
    ...state.playerStabilityNet.keys,
    ...state.fogOfWar.playerIds,
    for (final unit in state.units) unit.ownerPlayerId,
    for (final city in state.cities) city.ownerPlayerId,
  }..removeWhere((id) => id.isEmpty);
  return ids.toList()..sort();
}
