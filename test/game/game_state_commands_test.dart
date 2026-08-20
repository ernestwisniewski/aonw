import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game/game_state_effects.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider_commands.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider_multiplayer_sync.dart';
import 'package:aonw/game/presentation/providers/game/game_state_runtime.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lost dispatch owner prevents a late provider publication', () async {
    final initialState = GameClientState(activePlayerId: 'ai_1');
    final dispatchedState = GameClientState(activePlayerId: 'human_1');
    var publishedState = initialState;
    var canPublish = true;
    final runtime = GameStateRuntime()
      ..saveId = 'save_1'
      ..dispatchCommand = DispatchCommandUseCase(
        commandTransport: _LateCommandTransport(
          state: dispatchedState,
          beforeResult: () => canPublish = false,
        ),
      );
    final binding = GameStateBinding(
      readRef: () => throw StateError('provider ref should not be read'),
      isMounted: () => true,
      readState: () => publishedState,
      readStateFuture: () async => publishedState,
      writeState: (state) => publishedState = state,
    );
    final commands = GameStateCommands(
      binding: binding,
      runtime: runtime,
      multiplayerSync: GameStateMultiplayerSync(
        binding: binding,
        runtime: runtime,
        effects: GameStateEffects(binding),
      ),
    );

    final result = await commands.dispatchTransition(
      const SkipUnitTurnCommand('unit_1'),
      canPublish: () => canPublish,
    );

    expect(result.state, same(dispatchedState));
    expect(publishedState, same(initialState));
  });
}

final class _LateCommandTransport implements CommandTransport {
  const _LateCommandTransport({
    required this.state,
    required this.beforeResult,
  });

  final GameClientState state;
  final void Function() beforeResult;

  @override
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameClientState currentState,
    required DomainCommand command,
    GameCommandContext context = const GameCommandContext(),
    bool fromMovePreviewConfirmation = false,
  }) async {
    beforeResult();
    return CommandTransportResult(state: state, snapshot: null, offset: -1);
  }
}
