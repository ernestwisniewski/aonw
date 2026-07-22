import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_result.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_support.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/diplomacy/gold_amount.dart';
import 'package:aonw_core/game/domain/event.dart';

abstract final class DiplomacyProposalResponseCommandHandler {
  static DiplomacyCommandResult resolve({
    required DiplomacyCommandState state,
    required RespondDiplomaticProposalCommand command,
    required String actorPlayerId,
    required int turn,
    required bool canAct,
  }) {
    final issueReason = DiplomacyCommandSupport.issueRejectionReason(
      playerId: command.playerId,
      actorPlayerId: actorPlayerId,
      canAct: canAct,
    );
    if (issueReason != null) {
      return DiplomacyCommandSupport.reject(state, issueReason);
    }
    final proposal = state.diplomacy.pendingProposals[command.proposalId];
    if (proposal == null || proposal.toPlayerId != command.playerId) {
      return DiplomacyCommandSupport.reject(
        state,
        'diplomacy_proposal_not_found',
      );
    }
    if (command.accepted && !_canFund(state.playerGold, proposal)) {
      return DiplomacyCommandSupport.reject(
        state,
        'diplomacy_proposal_payment_unavailable',
      );
    }
    return command.accepted
        ? _acceptProposal(state, proposal, turn)
        : _rejectProposal(state, proposal, turn);
  }

  static DiplomacyCommandResult _acceptProposal(
    DiplomacyCommandState state,
    DiplomaticProposal proposal,
    int turn,
  ) {
    var diplomacy = state.diplomacy.removeProposal(proposal.id);
    final oldRelation = diplomacy.relationBetween(
      proposal.fromPlayerId,
      proposal.toPlayerId,
    );
    final newStatus = proposal.kind == DiplomaticProposalKind.friendship
        ? DiplomaticRelationStatus.friendly
        : DiplomaticRelationStatus.truce;
    final expiresOnTurn = proposal.kind == DiplomaticProposalKind.truce
        ? turn + DiplomacyState.defaultTruceDurationTurns
        : null;
    final adjustment = diplomacy
        .setStatus(
          proposal.fromPlayerId,
          proposal.toPlayerId,
          newStatus,
          turn: turn,
          reason: DiplomaticRelationChangeReason.proposalAccepted,
          statusExpiresOnTurn: expiresOnTurn,
        )
        .adjustRelationScoreWithEntry(
          proposal.fromPlayerId,
          proposal.toPlayerId,
          proposal.kind == DiplomaticProposalKind.friendship ? 18 : 10,
          turn: turn,
          reason: DiplomaticScoreChangeReason.proposalAccepted,
          sourceId: proposal.id,
        );
    diplomacy = adjustment.state;
    final relation = diplomacy.relationBetween(
      proposal.fromPlayerId,
      proposal.toPlayerId,
    );
    return DiplomacyCommandSupport.accept(
      state,
      playerGold: _applyPayment(state.playerGold, proposal),
      diplomacy: diplomacy,
      intendedAttacks: _clearPairAttacks(state, proposal),
      events: [
        _respondedEvent(proposal, accepted: true),
        DiplomaticRelationChangedEvent(
          playerAId: relation.playerAId,
          playerBId: relation.playerBId,
          oldStatus: oldRelation.status,
          newStatus: relation.status,
          reason: DiplomaticRelationChangeReason.proposalAccepted,
          expiresOnTurn: relation.statusExpiresOnTurn,
        ),
        if (adjustment.entry != null)
          DiplomacyCommandSupport.scoreEvent(adjustment.entry!),
      ],
    );
  }

  static DiplomacyCommandResult _rejectProposal(
    DiplomacyCommandState state,
    DiplomaticProposal proposal,
    int turn,
  ) {
    final adjustment = state.diplomacy
        .removeProposal(proposal.id)
        .adjustRelationScoreWithEntry(
          proposal.fromPlayerId,
          proposal.toPlayerId,
          -6,
          turn: turn,
          reason: DiplomaticScoreChangeReason.proposalRejected,
          sourceId: proposal.id,
        );
    return DiplomacyCommandSupport.accept(
      state,
      diplomacy: adjustment.state,
      events: [
        _respondedEvent(proposal, accepted: false),
        if (adjustment.entry != null)
          DiplomacyCommandSupport.scoreEvent(adjustment.entry!),
      ],
    );
  }

  static DiplomaticProposalRespondedEvent _respondedEvent(
    DiplomaticProposal proposal, {
    required bool accepted,
  }) {
    return DiplomaticProposalRespondedEvent(
      proposalId: proposal.id,
      fromPlayerId: proposal.fromPlayerId,
      toPlayerId: proposal.toPlayerId,
      kind: proposal.kind,
      accepted: accepted,
    );
  }

  static bool _canFund(
    Map<String, int> playerGold,
    DiplomaticProposal proposal,
  ) {
    if (proposal.goldPayment <= 0) return true;
    return GoldAmount(
      proposal.goldPayment,
    ).canFundFrom(playerGold[proposal.fromPlayerId] ?? 0);
  }

  static Map<String, int> _applyPayment(
    Map<String, int> playerGold,
    DiplomaticProposal proposal,
  ) {
    if (proposal.goldPayment <= 0) return playerGold;
    final payerGold = playerGold[proposal.fromPlayerId] ?? 0;
    final transfer = proposal.goldPayment.clamp(0, payerGold).toInt();
    if (transfer <= 0) return playerGold;
    return Map.unmodifiable({
      ...playerGold,
      proposal.fromPlayerId: payerGold - transfer,
      proposal.toPlayerId: (playerGold[proposal.toPlayerId] ?? 0) + transfer,
    });
  }

  static List<IntendedAttack> _clearPairAttacks(
    DiplomacyCommandState state,
    DiplomaticProposal proposal,
  ) {
    final retained = [
      for (final attack in state.intendedAttacks)
        if (!_attackBetween(
          state,
          attack,
          proposal.fromPlayerId,
          proposal.toPlayerId,
        ))
          attack,
    ];
    return retained.length == state.intendedAttacks.length
        ? state.intendedAttacks
        : List.unmodifiable(retained);
  }

  static bool _attackBetween(
    DiplomacyCommandState state,
    IntendedAttack attack,
    String playerAId,
    String playerBId,
  ) {
    final attackerOwner = _unitOwnerById(state, attack.attackerUnitId);
    if (attackerOwner == null) return false;
    final defenderOwner = _ownerAt(
      state,
      attack.defenderCol,
      attack.defenderRow,
    );
    if (defenderOwner == null) return false;
    final pairKey = DiplomacyState.relationKey(playerAId, playerBId);
    return DiplomacyState.relationKey(attackerOwner, defenderOwner) == pairKey;
  }

  static String? _unitOwnerById(DiplomacyCommandState state, String unitId) {
    for (final unit in state.units) {
      if (unit.id == unitId) return unit.ownerPlayerId;
    }
    return null;
  }

  static String? _ownerAt(DiplomacyCommandState state, int col, int row) {
    for (final unit in state.units) {
      if (unit.occupies(col, row)) return unit.ownerPlayerId;
    }
    for (final city in state.cities) {
      if (city.occupiesCenter(col, row)) return city.ownerPlayerId;
    }
    return null;
  }
}
