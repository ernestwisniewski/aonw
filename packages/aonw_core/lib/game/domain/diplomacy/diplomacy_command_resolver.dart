import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_result.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_message_command_handler.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_proposal_command_handler.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_proposal_response_command_handler.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_war_and_gift_command_handler.dart';

/// Applies diplomacy commands without depending on a state container.
abstract final class DiplomacyCommandResolver {
  static DiplomacyCommandResult resolve({
    required DiplomacyCommandState state,
    required DiplomaticCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) {
    return switch (command) {
      SendDiplomaticProposalCommand() =>
        DiplomacyProposalCommandHandler.resolve(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          turn: turn,
          canAct: canAct,
        ),
      RespondDiplomaticProposalCommand() =>
        DiplomacyProposalResponseCommandHandler.resolve(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          turn: turn,
          canAct: canAct,
        ),
      DeclareWarCommand() => DiplomacyWarAndGiftCommandHandler.declareWar(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        turn: turn,
        canAct: canAct,
      ),
      SendGoldGiftCommand() => DiplomacyWarAndGiftCommandHandler.sendGoldGift(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        turn: turn,
        canAct: canAct,
      ),
      SendDiplomaticMessageCommand() =>
        DiplomacyMessageCommandHandler.sendMessage(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          turn: turn,
          canAct: canAct,
        ),
      RespondDiplomaticMessageCommand() =>
        DiplomacyMessageCommandHandler.respondMessage(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          turn: turn,
          canAct: canAct,
        ),
    };
  }
}
