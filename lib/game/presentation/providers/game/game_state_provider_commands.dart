import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/presentation/providers/game/game_activity_history_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider_multiplayer_sync.dart';
import 'package:aonw/game/presentation/providers/game/game_state_runtime.dart';
import 'package:aonw_core/game/domain/command.dart';

final class GameStateCommands {
  GameStateCommands({
    required GameStateBinding binding,
    required GameStateRuntime runtime,
    required GameStateMultiplayerSync multiplayerSync,
  }) : _binding = binding,
       _runtime = runtime,
       _multiplayerSync = multiplayerSync;

  final GameStateBinding _binding;
  final GameStateRuntime _runtime;
  final GameStateMultiplayerSync _multiplayerSync;
  Future<void> _dispatchQueue = Future<void>.value();

  Future<void> syncActivePlayer({
    required String playerId,
    required bool canAct,
  }) => _enqueueDispatch(() async {
    final current = _binding.readState();
    final reducer = _runtime.reducer;
    if (!_binding.isMounted() || current == null || reducer == null) return;
    _binding.writeState(
      reducer
          .syncActivePlayer(current, playerId: playerId, canAct: canAct)
          .state,
    );
  });

  Future<DispatchCommandResult> _dispatchTransitionNow(
    DomainCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    if (!_binding.isMounted()) {
      return DispatchCommandResult(state: GameClientState());
    }
    var current = _binding.readState();
    if (current == null) {
      try {
        current = await _binding.readStateFuture();
      } catch (_) {
        return DispatchCommandResult(state: GameClientState());
      }
      if (!_binding.isMounted()) return DispatchCommandResult(state: current);
    }
    final useCase = _runtime.dispatchCommand;
    if (useCase == null || _runtime.saveId.isEmpty) {
      return DispatchCommandResult(state: current);
    }
    final result = await useCase.execute(
      saveId: _runtime.saveId,
      currentState: current,
      command: command,
      context: context,
    );
    await _publishDispatchResult(result);
    return result;
  }

  Future<DispatchCommandResult> _resolveIntentTransitionNow(
    GameIntent intent, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    if (!_binding.isMounted()) {
      return DispatchCommandResult(state: GameClientState(), offset: -1);
    }
    var current = _binding.readState();
    if (current == null) {
      try {
        current = await _binding.readStateFuture();
      } catch (_) {
        return DispatchCommandResult(state: GameClientState(), offset: -1);
      }
    }
    final reducer = _runtime.reducer;
    if (!_binding.isMounted() || reducer == null) {
      return DispatchCommandResult(state: current, offset: -1);
    }
    final resolution = GameIntentResolver(
      reducer: reducer,
      context: context,
    ).resolve(current.interaction, intent, current);
    final domainCommand = resolution.domainCommand;
    if (domainCommand != null) {
      return _dispatchResolvedDomainCommand(
        current: current,
        intent: intent,
        command: domainCommand,
        context: context,
      );
    }
    final next = resolution.interaction == current.interaction
        ? current
        : current.copyWith(interaction: resolution.interaction);
    if (_binding.isMounted()) _binding.writeState(next);
    return DispatchCommandResult(
      state: next,
      uiEffects: resolution.presentationFocus,
      offset: -1,
    );
  }

  Future<DispatchCommandResult> _dispatchResolvedDomainCommand({
    required GameClientState current,
    required GameIntent intent,
    required DomainCommand command,
    required GameCommandContext context,
  }) async {
    final useCase = _runtime.dispatchCommand;
    if (useCase == null || _runtime.saveId.isEmpty) {
      return DispatchCommandResult(state: current, offset: -1);
    }
    final result = await useCase.execute(
      saveId: _runtime.saveId,
      currentState: current,
      command: command,
      context: context,
      fromMovePreviewConfirmation:
          intent is TileTappedCommand && command is MoveUnitCommand,
    );
    await _publishDispatchResult(result);
    return result;
  }

  Future<void> _publishDispatchResult(DispatchCommandResult result) async {
    if (_binding.isMounted()) {
      if (result.offset >= 0) {
        _runtime.eventLogOffset = result.offset;
        _binding.ref.invalidate(gameActivityHistoryProvider(_runtime.saveId));
      }
      _binding.writeState(result.state);
    }
    if (result.storedSnapshot && result.snapshot != null) {
      await _multiplayerSync.cacheAppliedSnapshot(
        saveId: _runtime.saveId,
        snapshot: result.snapshot!,
        offset: result.offset,
      );
    }
  }

  Future<T> _enqueueDispatch<T>(Future<T> Function() operation) {
    final next = _dispatchQueue.then((_) => operation());
    _dispatchQueue = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  Future<List<UiEffect>> dispatch(
    DomainCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    final result = await dispatchTransition(command, context: context);
    return result.uiEffects;
  }

  /// Use when the caller must coordinate the new state with renderer effects.
  Future<DispatchCommandResult> dispatchTransition(
    DomainCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _enqueueDispatch(
      () => _dispatchTransitionNow(command, context: context),
    );
  }

  Future<List<UiEffect>> dispatchIntent(
    GameIntent intent, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    final result = await dispatchIntentTransition(intent, context: context);
    return result.uiEffects;
  }

  Future<DispatchCommandResult> dispatchIntentTransition(
    GameIntent intent, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _enqueueDispatch(
      () => _resolveIntentTransitionNow(intent, context: context),
    );
  }
}
