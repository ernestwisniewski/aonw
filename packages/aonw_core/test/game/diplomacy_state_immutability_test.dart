import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('owns diplomacy collections including nested score history', () {
    final contactKeys = <String>{'player_1|player_2'};
    final relation = DiplomaticRelation.between(
      playerAId: 'player_1',
      playerBId: 'player_2',
    );
    final relations = <String, DiplomaticRelation>{relation.key: relation};
    const proposal = DiplomaticProposal(
      id: 'proposal_1',
      fromPlayerId: 'player_1',
      toPlayerId: 'player_2',
      kind: DiplomaticProposalKind.friendship,
      createdTurn: 1,
      expiresOnTurn: 5,
    );
    final pendingProposals = <String, DiplomaticProposal>{
      proposal.id: proposal,
    };
    final message = DiplomaticMessage.create(
      id: 'message_1',
      fromPlayerId: 'player_1',
      toPlayerId: 'player_2',
      topic: DiplomaticMessageTopic.peacefulPraise,
      createdTurn: 1,
      expiresOnTurn: 5,
    );
    final messages = <String, DiplomaticMessage>{message.id: message};
    const scoreEntry = DiplomaticScoreEntry(
      playerAId: 'player_1',
      playerBId: 'player_2',
      turn: 1,
      delta: 5,
      scoreAfter: 5,
      reason: DiplomaticScoreChangeReason.manual,
    );
    final scoreEntries = <DiplomaticScoreEntry>[scoreEntry];
    final scoreHistory = <String, List<DiplomaticScoreEntry>>{
      relation.key: scoreEntries,
    };
    final state = DiplomacyState(
      contactKeys: contactKeys,
      relations: relations,
      pendingProposals: pendingProposals,
      messages: messages,
      scoreHistory: scoreHistory,
    );
    final json = state.toJson();
    final hashCode = state.hashCode;

    contactKeys.clear();
    relations.clear();
    pendingProposals.clear();
    messages.clear();
    scoreEntries.clear();
    scoreHistory.clear();

    expect(state.contactKeys, {'player_1|player_2'});
    expect(state.relations, {relation.key: relation});
    expect(state.pendingProposals, {proposal.id: proposal});
    expect(state.messages, {message.id: message});
    expect(state.scoreHistory[relation.key], [scoreEntry]);
    expect(state.toJson(), json);
    expect(state.hashCode, hashCode);
  });

  test('does not expose mutable diplomacy collections', () {
    final relation = DiplomaticRelation.between(
      playerAId: 'player_1',
      playerBId: 'player_2',
    );
    final state = DiplomacyState(
      contactKeys: {relation.key},
      relations: {relation.key: relation},
      scoreHistory: {
        relation.key: [
          const DiplomaticScoreEntry(
            playerAId: 'player_1',
            playerBId: 'player_2',
            turn: 1,
            delta: 5,
            scoreAfter: 5,
            reason: DiplomaticScoreChangeReason.manual,
          ),
        ],
      },
    );

    expect(
      () => state.contactKeys.add('player_1|player_3'),
      throwsUnsupportedError,
    );
    expect(() => state.relations.clear(), throwsUnsupportedError);
    expect(() => state.pendingProposals.clear(), throwsUnsupportedError);
    expect(() => state.messages.clear(), throwsUnsupportedError);
    expect(() => state.scoreHistory.clear(), throwsUnsupportedError);
    expect(
      () => state.scoreHistory[relation.key]!.clear(),
      throwsUnsupportedError,
    );
  });

  test('copyWith shares unchanged immutable collections', () {
    final state = DiplomacyState(contactKeys: {'player_1|player_2'});

    final next = state.copyWith(relations: const {});

    expect(identical(next.contactKeys, state.contactKeys), isTrue);
    expect(identical(next.scoreHistory, state.scoreHistory), isTrue);
  });
}
