import 'package:aonw/game/application/services/authoritative_command_policy.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthoritativeCommandPolicy', () {
    test('sends combat but blocks server-managed movement reset', () {
      expect(
        AuthoritativeCommandPolicy.shouldSendToServer(
          const AttackHexCommand('warrior_1', 1, 0),
        ),
        isTrue,
      );
      expect(
        AuthoritativeCommandPolicy.shouldSendToServer(
          const ResetUnitMovementCommand(playerId: 'player_1'),
        ),
        isFalse,
      );
      expect(
        AuthoritativeCommandPolicy.isServerManaged(
          const ResetUnitMovementCommand(),
        ),
        isTrue,
      );
      expect(
        AuthoritativeCommandPolicy.shouldLogForReplay(
          const GameState(),
          const ResetUnitMovementCommand(playerId: 'player_1'),
        ),
        isTrue,
      );
    });

    test('sends and replays every authoritative diplomacy command', () {
      const commands = <GameCommand>[
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

      for (final command in commands) {
        expect(AuthoritativeCommandPolicy.shouldSendToServer(command), isTrue);
        expect(
          AuthoritativeCommandPolicy.shouldLogForReplay(
            const GameState(),
            command,
          ),
          isTrue,
        );
      }
    });

    test('keeps worker selection local and enriches confirmation', () {
      const state = GameState(
        activePlayerId: 'player_1',
        interaction: GameInteractionState(
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
            improvementType: FieldImprovementType.farm,
          ),
        ),
      );
      const selection = SelectWorkerImprovementCommand(
        'worker_1',
        FieldImprovementType.farm,
      );

      expect(
        AuthoritativeCommandPolicy.isClientOnlyForState(state, selection),
        isTrue,
      );
      expect(
        AuthoritativeCommandPolicy.shouldLogForReplay(state, selection),
        isFalse,
      );
      expect(
        AuthoritativeCommandPolicy.shouldLogForReplay(
          state,
          const SelectWorkerImprovementCommand(
            'worker_2',
            FieldImprovementType.mine,
          ),
        ),
        isFalse,
      );
      expect(
        AuthoritativeCommandPolicy.shouldLogForReplay(
          const GameState(),
          selection,
        ),
        isTrue,
      );
      expect(
        AuthoritativeCommandPolicy.authoritativeCommandForClientIntent(
          state,
          const ConfirmWorkerImprovementCommand('worker_1'),
          const GameCommandContext(actorPlayerId: 'player_1'),
        ),
        const ConfirmWorkerImprovementCommand(
          'worker_1',
          improvementType: FieldImprovementType.farm,
        ),
      );
    });
  });
}
