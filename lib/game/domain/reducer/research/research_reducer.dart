import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';

abstract final class ResearchReducer {
  static GameStateTransition selectTechnology(
    GameState state,
    SelectTechnologyCommand command, {
    GameCommandContext context = const GameCommandContext(),
    required MapData mapData,
    TechnologyRuleset ruleset = TechnologyRulesets.standard,
  }) {
    if (!_canControlPlayer(state, command.playerId, context)) {
      return GameStateTransition(state: state);
    }

    final playerResearch = state.research.forPlayer(command.playerId);
    final availability = TechnologyAvailabilityService.availabilityFor(
      technologyId: command.technologyId,
      playerResearch: playerResearch,
      ruleset: ruleset,
    );
    if (availability != TechnologyAvailability.available) {
      return GameStateTransition(state: state);
    }

    final updatedPlayer = ResearchOverflowRules.applyToSelectedTechnology(
      playerId: command.playerId,
      playerResearch: playerResearch,
      technologyId: command.technologyId,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      mapData: mapData,
      ruleset: ruleset,
      paceBalance: context.paceBalance,
    );
    final updatedResearch = state.research.updatePlayer(
      command.playerId,
      updatedPlayer,
    );

    final pendingAction = state.pendingAction;
    var updatedState = state.copyWith(research: updatedResearch);
    if (pendingAction is PendingResearchSelection &&
        pendingAction.ownerPlayerId == command.playerId) {
      updatedState = updatedState.copyWith(pendingAction: null);
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
    return state.copyWith(pendingAction: null);
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
