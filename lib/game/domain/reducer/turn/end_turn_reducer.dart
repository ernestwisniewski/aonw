import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/turn.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/wonder.dart';

abstract final class EndTurnReducer {
  /// Runs one city turn for every city owned by [playerId]:
  /// food -> growth -> pending territory claim -> production queue,
  /// then advances research, active worker jobs, and fog of war.
  /// Returns [GameStateTransition] with the updated state, events, and effects.
  static GameStateTransition advanceCitiesForPlayer(
    GameState state,
    String playerId,
    MapData mapData, {
    FogOfWarService fogOfWarService = const FogOfWarService(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
    VictoryRules victoryRules = VictoryRules.standard,
    int? turn,
  }) {
    final ruleset = GameRuleset.standard().copyWith(
      city: cityRuleset,
      technology: technologyRuleset,
      stability: stabilityRuleset,
      wonders: wonderRuleset,
      paceBalance: paceBalance,
    );
    final result = PersistentTurnPipeline.advancePlayer(
      state: state.toPersistentState(),
      playerId: playerId,
      mapData: mapData,
      ruleset: ruleset,
      fogOfWarService: fogOfWarService,
      victoryRules: victoryRules,
      turn: turn,
    );
    final refreshed = const SelectionRefreshPhase().apply(
      TurnContext(
        state: state.copyWithPersistentState(result.state),
        mapData: mapData,
        ruleset: ruleset,
        playerId: playerId,
      ),
    );
    return GameStateTransition(state: refreshed.state, events: result.events);
  }
}
