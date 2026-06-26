import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/command/hud_pending_action_commands.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudPendingActionCommands', () {
    test('creates cancel research command for matching active player', () {
      final command = HudPendingActionCommands.cancelResearchSelection(
        state: const GameState(
          pendingAction: PendingResearchSelection(ownerPlayerId: 'player_1'),
        ),
        activePlayerId: 'player_1',
      );

      expect(command, const CancelResearchSelectionCommand('player_1'));
    });

    test('does not cancel research owned by another player', () {
      final command = HudPendingActionCommands.cancelResearchSelection(
        state: const GameState(
          pendingAction: PendingResearchSelection(ownerPlayerId: 'player_2'),
        ),
        activePlayerId: 'player_1',
      );

      expect(command, isNull);
    });

    test('creates cancel worker command from pending worker action', () {
      final command = HudPendingActionCommands.cancelWorkerActionSelection(
        const GameState(
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
          ),
        ),
      );

      expect(command, const CancelWorkerActionSelectionCommand('worker_1'));
    });

    test('ignores unrelated pending actions', () {
      final command = HudPendingActionCommands.cancelWorkerActionSelection(
        const GameState(
          pendingAction: PendingResearchSelection(ownerPlayerId: 'player_1'),
        ),
      );

      expect(command, isNull);
    });
  });
}
