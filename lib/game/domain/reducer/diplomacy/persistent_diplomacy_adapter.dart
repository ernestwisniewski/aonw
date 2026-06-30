import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';

abstract final class PersistentDiplomacyAdapter {
  static GameStateTransition reduce(
    GameState state,
    DiplomaticCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final result = const DiplomacyCommandRouter().route(
      state: _persistentState(state),
      command: command,
      actorPlayerId: _actorPlayerId(state, command, context),
      turn: context.combatSeedTurn,
      canAct: context.canAct,
    );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(
      state: _fromPersistent(state, result.state),
      events: result.events,
    );
  }

  static PersistentGameState _persistentState(GameState state) {
    return PersistentGameState(
      playerColors: state.playerColors,
      playerCountries: state.playerCountries,
      playerGold: state.playerGold,
      units: state.units,
      cities: state.cities,
      artifacts: state.artifacts,
      fieldImprovements: state.fieldImprovements,
      fogOfWar: state.fogOfWar,
      research: state.research,
      runtimeState: GameRuntimeState(
        cityFoundingDraft: state.cityFoundingDraft,
        pendingAction: state.pendingAction,
        submittedPlayerIds: state.submittedPlayerIds,
        intendedAttacks: state.intendedAttacks,
        diplomacy: state.diplomacy,
        dominationHoldTurnsByPlayerId: state.dominationHoldTurnsByPlayerId,
        culturalVictoryHoldTurnsByPlayerId:
            state.culturalVictoryHoldTurnsByPlayerId,
        mapObjectiveHoldStatesByObjectiveId:
            state.mapObjectiveHoldStatesByObjectiveId,
        resourceTradeAgreements: state.resourceTradeAgreements,
      ),
    );
  }

  static GameState _fromPersistent(
    GameState state,
    PersistentGameState persistent,
  ) {
    return state.copyWith(
      playerGold: persistent.playerGold,
      diplomacy: persistent.runtimeState.diplomacy,
      intendedAttacks: persistent.runtimeState.intendedAttacks,
      resourceTradeAgreements: persistent.runtimeState.resourceTradeAgreements,
    );
  }

  static String _actorPlayerId(
    GameState state,
    DiplomaticCommand command,
    GameCommandContext context,
  ) {
    if (context.hasActor) return context.actorPlayerId!;
    if (state.activePlayerId.isNotEmpty) return state.activePlayerId;
    return _commandPlayerId(command);
  }

  static String _commandPlayerId(DiplomaticCommand command) {
    return switch (command) {
      SendDiplomaticProposalCommand(:final playerId) => playerId,
      RespondDiplomaticProposalCommand(:final playerId) => playerId,
      DeclareWarCommand(:final playerId) => playerId,
      SendGoldGiftCommand(:final playerId) => playerId,
      SendDiplomaticMessageCommand(:final playerId) => playerId,
      RespondDiplomaticMessageCommand(:final playerId) => playerId,
    };
  }
}
