import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_result.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_support.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/diplomacy/gold_amount.dart';
import 'package:aonw_core/game/domain/event.dart';

abstract final class DiplomacyProposalCommandHandler {
  static DiplomacyCommandResult resolve({
    required DiplomacyCommandState state,
    required SendDiplomaticProposalCommand command,
    required String actorPlayerId,
    required int turn,
    required bool canAct,
  }) {
    final rejectionReason = _rejectionReason(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      canAct: canAct,
    );
    if (rejectionReason != null) {
      return DiplomacyCommandSupport.reject(state, rejectionReason);
    }

    final proposal = _proposal(state, command, turn);
    final nextDiplomacy = state.diplomacy.addProposal(proposal);
    if (identical(nextDiplomacy, state.diplomacy)) {
      return DiplomacyCommandSupport.reject(
        state,
        'diplomacy_duplicate_proposal',
      );
    }
    return DiplomacyCommandSupport.accept(
      state,
      diplomacy: nextDiplomacy,
      events: [
        DiplomaticProposalSentEvent(
          proposalId: proposal.id,
          fromPlayerId: proposal.fromPlayerId,
          toPlayerId: proposal.toPlayerId,
          kind: proposal.kind,
          expiresOnTurn: proposal.expiresOnTurn,
        ),
      ],
    );
  }

  static String? _rejectionReason({
    required DiplomacyCommandState state,
    required SendDiplomaticProposalCommand command,
    required String actorPlayerId,
    required bool canAct,
  }) {
    final issueReason = DiplomacyCommandSupport.issueRejectionReason(
      playerId: command.playerId,
      actorPlayerId: actorPlayerId,
      canAct: canAct,
    );
    if (issueReason != null) return issueReason;
    if (!DiplomacyCommandSupport.canTarget(
      state,
      command.playerId,
      command.targetPlayerId,
    )) {
      return 'diplomacy_target_not_discovered';
    }
    final status = state.diplomacy.statusBetween(
      command.playerId,
      command.targetPlayerId,
    );
    return _proposalAllowed(command.kind, status)
        ? null
        : 'diplomacy_proposal_not_allowed';
  }

  static DiplomaticProposal _proposal(
    DiplomacyCommandState state,
    SendDiplomaticProposalCommand command,
    int turn,
  ) {
    return DiplomaticProposal(
      id:
          command.proposalId ??
          'proposal.$turn.${command.playerId}.${command.targetPlayerId}.'
              '${command.kind.name}.${state.diplomacy.pendingProposals.length}',
      fromPlayerId: command.playerId,
      toPlayerId: command.targetPlayerId,
      kind: command.kind,
      createdTurn: turn,
      expiresOnTurn: turn + DiplomacyState.defaultProposalDurationTurns,
      goldPayment: _goldPayment(state, command),
    );
  }

  static int _goldPayment(
    DiplomacyCommandState state,
    SendDiplomaticProposalCommand command,
  ) {
    if (command.kind != DiplomaticProposalKind.truce) return 0;
    if (command.goldPayment <= 0) return GoldAmount.zero.value;
    final requested = GoldAmount(command.goldPayment);
    final availableGold = state.playerGold[command.playerId] ?? 0;
    return requested.value.clamp(0, availableGold).toInt();
  }

  static bool _proposalAllowed(
    DiplomaticProposalKind kind,
    DiplomaticRelationStatus status,
  ) {
    return switch (kind) {
      DiplomaticProposalKind.friendship =>
        status == DiplomaticRelationStatus.neutral ||
            status == DiplomaticRelationStatus.hostile ||
            status == DiplomaticRelationStatus.truce,
      DiplomaticProposalKind.truce =>
        status == DiplomaticRelationStatus.hostile ||
            status == DiplomaticRelationStatus.war,
    };
  }
}
