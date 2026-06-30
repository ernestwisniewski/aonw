import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('marks only diplomacy service commands as DiplomaticCommand', () {
    const diplomacyCommands = <GameCommand>[
      SendDiplomaticProposalCommand(
        playerId: 'player_1',
        targetPlayerId: 'player_2',
        kind: DiplomaticProposalKind.friendship,
      ),
      RespondDiplomaticProposalCommand(
        playerId: 'player_2',
        proposalId: 'proposal_1',
        accepted: true,
      ),
      DeclareWarCommand(playerId: 'player_1', targetPlayerId: 'player_2'),
      SendGoldGiftCommand(
        playerId: 'player_1',
        targetPlayerId: 'player_2',
        amount: 5,
      ),
      SendDiplomaticMessageCommand(
        playerId: 'player_1',
        targetPlayerId: 'player_2',
        topic: DiplomaticMessageTopic.peacefulPraise,
      ),
      RespondDiplomaticMessageCommand(
        playerId: 'player_2',
        messageId: 'message_1',
        response: DiplomaticMessageResponse.conciliatory,
      ),
    ];
    const resourceTradeCommands = <GameCommand>[
      OpenResourceTradeCommand(
        playerId: 'player_1',
        targetPlayerId: 'player_2',
        resource: ResourceType.horses,
        goldPerTurn: 2,
        durationTurns: 5,
      ),
      OpenResourceExchangeCommand(
        playerId: 'player_1',
        targetPlayerId: 'player_2',
        offeredResource: ResourceType.iron,
        requestedResource: ResourceType.horses,
        durationTurns: 5,
      ),
    ];

    expect(diplomacyCommands, everyElement(isA<DiplomaticCommand>()));
    expect(
      resourceTradeCommands,
      everyElement(isNot(isA<DiplomaticCommand>())),
    );
  });
}
