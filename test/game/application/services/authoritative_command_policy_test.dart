import 'package:aonw/game/application/services/authoritative_command_policy.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthoritativeCommandPolicy', () {
    test('only translates client intents into domain commands', () {
      final state = GameClientState(
        activePlayerId: 'player_1',
        interaction: const InteractionState(
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
            improvementType: FieldImprovementType.farm,
          ),
        ),
      );

      expect(
        AuthoritativeCommandPolicy.authoritativeCommandForClientIntent(
          state,
          const ChooseWorkerImprovementIntent(
            'worker_1',
            FieldImprovementType.farm,
          ),
          const GameCommandContext(actorPlayerId: 'player_1'),
        ),
        isNull,
      );
      expect(
        AuthoritativeCommandPolicy.authoritativeCommandForClientIntent(
          state,
          const ConfirmWorkerImprovementIntent('worker_1'),
          const GameCommandContext(actorPlayerId: 'player_1'),
        ),
        const ConfirmWorkerImprovementCommand(
          'worker_1',
          improvementType: FieldImprovementType.farm,
        ),
      );
    });

    test('does not fabricate confirmation without a matching selection', () {
      expect(
        AuthoritativeCommandPolicy.authoritativeCommandForClientIntent(
          GameClientState(),
          const ConfirmWorkerImprovementIntent('worker_1'),
          const GameCommandContext(actorPlayerId: 'player_1'),
        ),
        isNull,
      );
    });
  });
}
