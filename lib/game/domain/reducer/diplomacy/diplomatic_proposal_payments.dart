import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';

abstract final class DiplomaticProposalPayments {
  static int goldPaymentForCommand(
    GameState state,
    SendDiplomaticProposalCommand command,
  ) {
    if (command.kind != DiplomaticProposalKind.truce) return 0;
    final availableGold = state.playerGold[command.playerId] ?? 0;
    return command.goldPayment.clamp(0, availableGold).toInt();
  }

  static bool canFundAccepted(GameState state, DiplomaticProposal proposal) {
    if (proposal.goldPayment <= 0) return true;
    final payerGold = state.playerGold[proposal.fromPlayerId] ?? 0;
    return payerGold >= proposal.goldPayment;
  }

  static GameState applyAccepted(GameState state, DiplomaticProposal proposal) {
    if (proposal.goldPayment <= 0) return state;
    final payerGold = state.playerGold[proposal.fromPlayerId] ?? 0;
    final transfer = proposal.goldPayment.clamp(0, payerGold).toInt();
    if (transfer <= 0) return state;
    final recipientGold = state.playerGold[proposal.toPlayerId] ?? 0;
    return state.copyWith(
      playerGold: {
        ...state.playerGold,
        proposal.fromPlayerId: payerGold - transfer,
        proposal.toPlayerId: recipientGold + transfer,
      },
    );
  }
}
