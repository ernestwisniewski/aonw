import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';

abstract final class DiplomacyReducer {
  static GameStateTransition sendProposal(
    GameState state,
    SendDiplomaticProposalCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _reduce(state, command, context);
  }

  static GameStateTransition respondProposal(
    GameState state,
    RespondDiplomaticProposalCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _reduce(state, command, context);
  }

  static GameStateTransition declareWar(
    GameState state,
    DeclareWarCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _reduce(state, command, context);
  }

  static GameStateTransition sendGoldGift(
    GameState state,
    SendGoldGiftCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _reduce(state, command, context);
  }

  static GameStateTransition sendMessage(
    GameState state,
    SendDiplomaticMessageCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _reduce(state, command, context);
  }

  static GameStateTransition respondMessage(
    GameState state,
    RespondDiplomaticMessageCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _reduce(state, command, context);
  }

  static GameStateTransition _reduce(
    GameState state,
    DiplomaticCommand command,
    GameCommandContext context,
  ) {
    final result = DiplomacyCommandResolver.resolve(
      state: DiplomacyCommandState(
        playerColors: state.playerColors,
        playerCountries: state.playerCountries,
        playerGold: state.playerGold,
        units: state.units,
        cities: state.cities,
        fogOfWar: state.fogOfWar,
        diplomacy: state.diplomacy,
        intendedAttacks: state.intendedAttacks,
        resourceTradeAgreements: state.resourceTradeAgreements,
      ),
      command: command,
      actorPlayerId: _actorPlayerId(state, command, context),
      turn: context.combatSeedTurn,
      canAct: context.canAct,
    );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(
      state: state.copyWith(
        playerGold: result.playerGold,
        diplomacy: result.diplomacy,
        intendedAttacks: result.intendedAttacks,
        resourceTradeAgreements: result.resourceTradeAgreements,
      ),
      events: result.events,
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
