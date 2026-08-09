import 'dart:async';

import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/live_wire_command_dispatcher.dart';
import 'package:aonw/game/application/use_cases/bootstrap_game_state_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider_multiplayer_sync.dart';
import 'package:aonw/game/presentation/providers/game/game_state_runtime.dart';
import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_compatibility_provider.dart';
import 'package:aonw/game/presentation/providers/ruleset/ruleset_providers.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/save.dart';

final class GameStateApplicationBootstrap {
  const GameStateApplicationBootstrap({
    required GameStateBinding binding,
    required GameStateRuntime runtime,
    required GameStateMultiplayerSync multiplayerSync,
  }) : _binding = binding,
       _runtime = runtime,
       _multiplayerSync = multiplayerSync;

  final GameStateBinding _binding;
  final GameStateRuntime _runtime;
  final GameStateMultiplayerSync _multiplayerSync;

  Future<GameClientState> buildState(String saveId) async {
    if (!_binding.isMounted()) return GameClientState();
    _binding.ref.onDispose(() => unawaited(_multiplayerSync.closeLiveEvents()));
    await _multiplayerSync.closeLiveEvents();
    if (!_binding.isMounted()) return GameClientState();
    _runtime.saveId = saveId;
    final compatibility = await _compatibleSession(saveId);
    if (compatibility == null) return _failClosedState();
    final session = compatibility.session;
    if (!_networkSessionRemainsCompatible(compatibility, saveId)) {
      return _failClosedState();
    }
    final reducer = _createReducer(session);
    _runtime.reducer = reducer;
    final liveCommandDispatcher = session.gameMode == GameMode.multiplayer
        ? LiveWireCommandDispatcher(
            liveHandle: _multiplayerSync.liveCommandHandle,
            fallback: _binding.ref.watch(wireCommandDispatcherProvider),
          )
        : null;
    _runtime.dispatchCommand = buildDispatchCommandUseCase(
      _binding.ref,
      reducer,
      session.gameMode,
      saveId: saveId,
      commandDispatcher: liveCommandDispatcher,
      requiresNetworkTransport: compatibility.networkBacked,
    );
    final bootstrap = BootstrapGameStateUseCase(
      repository: gameRepositoryForSave(_binding.ref, saveId),
      dispatchCommand: _runtime.dispatchCommand!,
    );
    final bootstrapped = await bootstrap.executeWithResult(
      saveId: saveId,
      preferredPlayerId: _binding.ref.read(networkSessionProvider)?.playerId,
    );
    _runtime.eventLogOffset = bootstrapped.offset;
    var synchronized = reducer
        .syncActivePlayer(
          bootstrapped.state,
          playerId: bootstrapped.state.activePlayerId,
          canAct: bootstrapped.state.activePlayerCanAct,
        )
        .state;
    if (bootstrapped.shouldFocusTurnStart) {
      final focus = GameIntentResolver(reducer: reducer).resolve(
        synchronized.interaction,
        FocusTurnStartActionCommand(synchronized.activePlayerId),
        synchronized,
      );
      if (focus.interaction != synchronized.interaction) {
        synchronized = synchronized.copyWith(interaction: focus.interaction);
      }
    }
    if (!_binding.isMounted()) return synchronized;
    unawaited(
      _multiplayerSync.startLiveEvents(saveId, gameMode: session.gameMode),
    );
    return synchronized;
  }

  Future<({GameSession session, bool networkBacked})?> _compatibleSession(
    String saveId,
  ) async {
    final session = _binding.ref.watch(activeGameSessionProvider);
    if (session == null || saveId.isEmpty) return null;
    final decision = await _binding.ref.read(
      multiplayerSaveAccessDecisionProvider(saveId).future,
    );
    if (!_binding.isMounted()) return null;
    if (decision.state == MultiplayerAccessState.allowed) {
      return (session: session, networkBacked: decision.networkBacked);
    }
    _resetRuntime();
    return null;
  }

  void _resetRuntime() {
    _runtime
      ..eventLogOffset = 0
      ..dispatchCommand = null
      ..reducer = null;
  }

  bool _networkSessionRemainsCompatible(
    ({GameSession session, bool networkBacked}) compatibility,
    String saveId,
  ) {
    return !compatibility.networkBacked ||
        canUseNetworkMatchTransport(
          session: _binding.ref.read(networkSessionProvider),
          saveId: saveId,
        );
  }

  GameClientState _failClosedState() {
    _resetRuntime();
    return GameClientState();
  }

  GameStateReducer _createReducer(GameSession session) {
    return GameStateReducer(
      mapData: session.mapData,
      ruleset: GameRuleset.standard().copyWith(
        city: _binding.ref.watch(cityRulesetProvider),
        technology: _binding.ref.watch(technologyRulesetProvider),
        stability: _binding.ref.watch(stabilityRulesetProvider),
      ),
    );
  }
}
