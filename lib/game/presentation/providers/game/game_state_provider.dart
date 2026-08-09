import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/presentation/providers/game/game_state_effects.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider_application_bootstrap.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider_commands.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider_multiplayer_sync.dart';
import 'package:aonw/game/presentation/providers/game/game_state_runtime.dart';
import 'package:aonw/game/presentation/providers/renderer/renderer_provider.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_state_provider.g.dart';

Duration? _doNotRetry(int retryCount, Object error) => null;

@Riverpod(
  retry: _doNotRetry,
  dependencies: [activeGameSession, networkSession, activeRendererViewModel],
)
class GameStateNotifier extends _$GameStateNotifier {
  late final GameStateRuntime _runtime = GameStateRuntime();
  late final GameStateBinding _binding = GameStateBinding(
    readRef: () => ref,
    isMounted: () => ref.mounted,
    readState: () => state.value,
    readStateFuture: () => future,
    writeState: (value) => state = AsyncData(value),
  );
  late final GameStateEffects _effects = GameStateEffects(_binding);
  late final GameStateMultiplayerSync _multiplayerSync =
      GameStateMultiplayerSync(
        binding: _binding,
        runtime: _runtime,
        effects: _effects,
      );
  late final GameStateCommands _commands = GameStateCommands(
    binding: _binding,
    runtime: _runtime,
    multiplayerSync: _multiplayerSync,
  );
  late final GameStateApplicationBootstrap _bootstrap =
      GameStateApplicationBootstrap(
        binding: _binding,
        runtime: _runtime,
        multiplayerSync: _multiplayerSync,
      );

  @override
  Future<GameClientState> build(String saveId) => _bootstrap.buildState(saveId);

  Future<void> syncActivePlayer({
    required String playerId,
    required bool canAct,
  }) => _commands.syncActivePlayer(playerId: playerId, canAct: canAct);

  Future<List<UiEffect>> dispatch(
    DomainCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) => _commands.dispatch(command, context: context);

  Future<DispatchCommandResult> dispatchTransition(
    DomainCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) => _commands.dispatchTransition(command, context: context);

  Future<List<UiEffect>> dispatchIntent(
    GameIntent intent, {
    GameCommandContext context = const GameCommandContext(),
  }) => _commands.dispatchIntent(intent, context: context);

  Future<DispatchCommandResult> dispatchIntentTransition(
    GameIntent intent, {
    GameCommandContext context = const GameCommandContext(),
  }) => _commands.dispatchIntentTransition(intent, context: context);

  Future<void> closeLiveEvents() => _multiplayerSync.closeLiveEvents();
}
