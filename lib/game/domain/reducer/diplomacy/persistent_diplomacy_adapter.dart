import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/state.dart';

abstract final class PersistentDiplomacyAdapter {
  static GameStateTransition reduce(
    GameState state,
    DiplomaticCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final result = const DiplomacyCommandRouter().route(
      state: state.toPersistentState(),
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

  static GameState _fromPersistent(
    GameState state,
    PersistentGameState persistent,
  ) {
    return state.copyWith(
      playerGold: persistent.playerGold,
      playerWarWeariness: persistent.playerWarWeariness,
      playerStabilityNet: persistent.playerStabilityNet,
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
