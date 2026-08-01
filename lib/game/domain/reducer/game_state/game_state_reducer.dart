import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

part 'game_state_reducer_active_player.dart';
part 'game_state_reducer_interaction_state.dart';

class GameStateReducer {
  final MapReadView mapData;
  final GameRuleset ruleset;

  const GameStateReducer({
    required this.mapData,
    this.ruleset = GameRuleset.defaults,
  });

  GameStateTransition syncActivePlayer(
    GameClientState state, {
    required String playerId,
    required bool canAct,
  }) => _ActivePlayerReducer.handleSetActivePlayer(state, playerId, canAct);
}
