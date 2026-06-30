import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy/persistent_diplomacy_resolver.dart';
import 'package:aonw_core/game/domain/diplomacy/persistent_diplomacy_result.dart';
import 'package:aonw_core/game/domain/state.dart';

class DiplomacyCommandRouter {
  const DiplomacyCommandRouter({
    this.resolver = const PersistentDiplomacyResolver(),
  });

  final PersistentDiplomacyResolver resolver;

  PersistentDiplomacyResult route({
    required PersistentGameState state,
    required DiplomaticCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) {
    return switch (command) {
      SendDiplomaticProposalCommand() => resolver.sendProposal(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        turn: turn,
        canAct: canAct,
      ),
      RespondDiplomaticProposalCommand() => resolver.respondProposal(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        turn: turn,
        canAct: canAct,
      ),
      DeclareWarCommand() => resolver.declareWar(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        turn: turn,
        canAct: canAct,
      ),
      SendGoldGiftCommand() => resolver.sendGoldGift(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        turn: turn,
        canAct: canAct,
      ),
      SendDiplomaticMessageCommand() => resolver.sendMessage(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        turn: turn,
        canAct: canAct,
      ),
      RespondDiplomaticMessageCommand() => resolver.respondMessage(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        turn: turn,
        canAct: canAct,
      ),
    };
  }
}
