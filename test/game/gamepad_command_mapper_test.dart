import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

T _runtimeInstance<T>(T Function() create) => create();

void main() {
  group('GamepadCommandMapper', () {
    final mapper = _runtimeInstance(GamepadCommandMapper.new);

    test('maps cancel to the active pending action cancel command', () {
      final commands = mapper.commandsForFrame(
        frame: const GamepadControlFrame(cancelPressed: true),
        state: GameClientState(
          interaction: const InteractionState(
            moveCommandActive: true,
            pendingAction: PendingWorkerActionSelection(
              ownerPlayerId: 'player_1',
              unitId: 'worker_1',
            ),
          ),
        ),
      );

      expect(commands, [const CancelWorkerActionSelectionCommand('worker_1')]);
    });

    test('prioritizes city founding cancel over other interaction state', () {
      final commands = mapper.commandsForFrame(
        frame: const GamepadControlFrame(cancelPressed: true),
        state: GameClientState(
          interaction: InteractionState(
            cityFoundingDraft: CityFoundingDraft(
              unitId: 'settler_1',
              ownerPlayerId: 'player_1',
              center: const CityHex(col: 1, row: 1),
            ),
            moveCommandActive: true,
            pendingAction: const PendingResearchSelection(
              ownerPlayerId: 'player_1',
            ),
          ),
        ),
      );

      expect(commands, [const CancelCityFoundingCommand()]);
    });

    test('blocks move toggle outside standard and move targeting modes', () {
      final commands = mapper.commandsForFrame(
        frame: const GamepadControlFrame(moveModePressed: true),
        state: GameClientState(
          interaction: const InteractionState(
            pendingAction: PendingWorkerActionSelection(
              ownerPlayerId: 'player_1',
              unitId: 'worker_1',
            ),
          ),
        ),
      );

      expect(commands, isEmpty);
    });

    test('maps focus and confirm buttons to shared game commands', () {
      final commands = mapper.commandsForFrame(
        frame: const GamepadControlFrame(
          focusPreviousPressed: true,
          focusNextPressed: true,
          confirmPressed: true,
        ),
        state: GameClientState(activePlayerId: 'player_1'),
        currentTile: WorldTile(
          col: 2,
          row: 3,
          terrains: [],
          resources: [],
          height: 0,
        ),
      );

      expect(commands, [
        const FocusNextPendingActionCommand('player_1', actionStep: -1),
        const FocusNextPendingActionCommand('player_1'),
        const TileTappedCommand(2, 3),
      ]);
    });

    test('keeps directional HUD focus out of map commands', () {
      final commands = mapper.commandsForFrame(
        frame: const GamepadControlFrame(
          hudFocusPreviousPressed: true,
          hudFocusNextPressed: true,
        ),
        state: GameClientState(activePlayerId: 'player_1'),
      );

      expect(commands, isEmpty);
    });
  });
}
