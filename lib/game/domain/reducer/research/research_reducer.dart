import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class ResearchReducer {
  static GameStateTransition selectTechnology(
    GameState state,
    SelectTechnologyCommand command, {
    GameCommandContext context = const GameCommandContext(),
    required MapTileLookup mapTiles,
    TechnologyRuleset ruleset = TechnologyRulesets.standard,
  }) {
    if (!_canControlPlayer(state, command.playerId, context)) {
      return GameStateTransition(state: state);
    }

    final result = SelectTechnologyResolver.selectTechnology(
      research: state.research,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      command: command,
      actorPlayerId: command.playerId,
      mapTiles: mapTiles,
      ruleset: ruleset,
      paceBalance: context.paceBalance,
    );
    if (!result.accepted) {
      return GameStateTransition(state: state);
    }

    final pendingAction =
        ResearchSelectionPendingActionPolicy.afterAcceptedSelection(
          pendingAction: state.pendingAction,
          playerId: command.playerId,
        );
    var updatedState = state.copyWith(research: result.research);
    if (!identical(pendingAction, state.pendingAction)) {
      updatedState = updatedState.copyWithInteraction(
        pendingAction: pendingAction,
      );
    }

    return GameStateTransition(state: updatedState);
  }

  static GameState cancelResearchSelection(
    GameState state,
    CancelResearchSelectionCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    if (!_canControlPlayer(state, command.playerId, context)) return state;
    final pendingAction = state.pendingAction;
    if (pendingAction is! PendingResearchSelection ||
        pendingAction.ownerPlayerId != command.playerId) {
      return state;
    }
    return state.copyWithInteraction(pendingAction: null);
  }

  static bool _canControlPlayer(
    GameState state,
    String playerId,
    GameCommandContext context,
  ) {
    if (!context.canAct) return false;
    if (context.hasActor) return context.actorPlayerId == playerId;
    if (state.activePlayerId.isEmpty) return true;
    return state.activePlayerId == playerId && state.activePlayerCanAct;
  }
}
