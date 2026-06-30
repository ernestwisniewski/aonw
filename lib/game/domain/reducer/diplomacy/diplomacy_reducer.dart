import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/diplomacy/persistent_diplomacy_adapter.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';

abstract final class DiplomacyReducer {
  static GameStateTransition sendProposal(
    GameState state,
    SendDiplomaticProposalCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return PersistentDiplomacyAdapter.reduce(state, command, context: context);
  }

  static GameStateTransition respondProposal(
    GameState state,
    RespondDiplomaticProposalCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return PersistentDiplomacyAdapter.reduce(state, command, context: context);
  }

  static GameStateTransition declareWar(
    GameState state,
    DeclareWarCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return PersistentDiplomacyAdapter.reduce(state, command, context: context);
  }

  static GameStateTransition sendMessage(
    GameState state,
    SendDiplomaticMessageCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return PersistentDiplomacyAdapter.reduce(state, command, context: context);
  }

  static GameStateTransition respondMessage(
    GameState state,
    RespondDiplomaticMessageCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return PersistentDiplomacyAdapter.reduce(state, command, context: context);
  }
}
