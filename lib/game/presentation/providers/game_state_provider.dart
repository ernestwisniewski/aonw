import 'dart:async';

import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/api/transport/live_wire_command_dispatcher.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/application/use_cases/bootstrap_game_state_use_case.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_save.dart' show GameMode;
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_event_renderer_effect_mapper.dart';
import 'package:aonw/game/presentation/providers/game_activity_history_provider.dart';
import 'package:aonw/game/presentation/providers/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/multiplayer_connection_status_provider.dart';
import 'package:aonw/game/presentation/providers/renderer_provider.dart';
import 'package:aonw/game/presentation/providers/repository_providers.dart';
import 'package:aonw/game/presentation/providers/ruleset_providers.dart';
import 'package:aonw/game/presentation/providers/session_providers.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_state_provider.g.dart';

Duration? _doNotRetry(int retryCount, Object error) => null;
const _liveSnapshotRetryDelays = [
  Duration(milliseconds: 150),
  Duration(milliseconds: 350),
  Duration(milliseconds: 750),
];

@Riverpod(
  retry: _doNotRetry,
  dependencies: [activeGameSession, networkSession, activeRendererViewModel],
)
class GameStateNotifier extends _$GameStateNotifier {
  DispatchCommandUseCase? _dispatchCommand;
  LiveEventSubscriptionHandle? _liveEvents;
  Future<LiveEventSubscriptionHandle?>? _liveEventsStarting;
  String _saveId = '';
  Future<void> _dispatchQueue = Future<void>.value();
  Future<void> _networkSnapshotQueue = Future<void>.value();
  int _eventLogOffset = 0;

  @override
  Future<GameState> build(String saveId) async {
    ref.onDispose(() {
      unawaited(_closeLiveEvents());
    });
    await _closeLiveEvents();
    _saveId = saveId;
    final session = ref.watch(activeGameSessionProvider);
    if (session == null || saveId.isEmpty) {
      _dispatchCommand = null;
      return const GameState();
    }

    final reducer = GameStateReducer(
      mapData: session.mapData,
      ruleset: GameRuleset(
        city: ref.watch(cityRulesetProvider),
        technology: ref.watch(technologyRulesetProvider),
      ),
    );
    _dispatchCommand = buildDispatchCommandUseCase(
      ref,
      reducer,
      session.gameMode,
      saveId: saveId,
      commandDispatcher: LiveWireCommandDispatcher(
        liveHandle: _liveCommandHandle,
        fallback: ref.watch(wireCommandDispatcherProvider),
      ),
    );
    final repository = gameRepositoryForSave(ref, saveId);

    final bootstrap = BootstrapGameStateUseCase(
      repository: repository,
      dispatchCommand: _dispatchCommand!,
      eventLog: session.gameMode == GameMode.multiplayer
          ? eventLogForSave(ref, saveId)
          : null,
      replayReducer: session.gameMode == GameMode.multiplayer ? reducer : null,
    );
    final bootstrapped = await bootstrap.executeWithResult(
      saveId: saveId,
      preferredPlayerId: ref.watch(networkSessionProvider)?.playerId,
    );
    _eventLogOffset = bootstrapped.offset;
    if (!ref.mounted) return bootstrapped.state;
    unawaited(_startLiveEvents(saveId, gameMode: session.gameMode));
    return bootstrapped.state;
  }

  Future<List<UiEffect>> dispatch(
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    final result = await dispatchTransition(command, context: context);
    return result.uiEffects;
  }

  /// Use when the caller must coordinate the new state with renderer effects.
  Future<DispatchCommandResult> dispatchTransition(
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    return _enqueueDispatch(
      () => _dispatchTransitionNow(command, context: context),
    );
  }

  Future<T> _enqueueDispatch<T>(Future<T> Function() operation) {
    final next = _dispatchQueue.then((_) => operation());
    _dispatchQueue = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  Future<DispatchCommandResult> _dispatchTransitionNow(
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    if (!ref.mounted) {
      return const DispatchCommandResult(state: GameState());
    }
    var current = state.value;
    if (current == null) {
      try {
        current = await future;
      } catch (_) {
        return const DispatchCommandResult(state: GameState());
      }
      if (!ref.mounted) {
        return DispatchCommandResult(state: current);
      }
    }

    final useCase = _dispatchCommand;
    if (useCase == null || _saveId.isEmpty) {
      return DispatchCommandResult(state: current);
    }

    final result = await useCase.execute(
      saveId: _saveId,
      currentState: current,
      command: command,
      context: context,
    );

    if (ref.mounted) {
      if (result.offset >= 0) {
        _eventLogOffset = result.offset;
        ref.invalidate(gameActivityHistoryProvider(_saveId));
      }
      state = AsyncData(result.state);
    }
    if (result.storedSnapshot && result.snapshot != null) {
      await _cacheAppliedSnapshot(
        saveId: _saveId,
        snapshot: result.snapshot!,
        offset: result.offset,
      );
    }
    return result;
  }

  Future<void> _startLiveEvents(
    String saveId, {
    required GameMode gameMode,
  }) async {
    if (gameMode != GameMode.multiplayer) return;

    final session = ref.read(networkSessionProvider);
    if (session == null ||
        !session.isConnected ||
        session.matchId != saveId ||
        session.token.value.isEmpty) {
      return;
    }

    final starting = Completer<LiveEventSubscriptionHandle?>();
    _liveEventsStarting = starting.future;
    try {
      final subscription = LiveEventSubscription(
        serverpodHost: ref.read(apiConfigProvider).baseUrl.toString(),
        connector: ref.read(multiplayerStreamConnectorProvider),
      );
      final handle = await subscription.subscribe(
        matchId: saveId,
        token: session.token,
        fromOffset: _eventLogOffset + 1,
        nextOffset: () => _eventLogOffset + 1,
        onEvent: (event) {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.connected,
          );
          final snapshot = event.snapshot;
          if (snapshot == null) {
            unawaited(_reloadNetworkSnapshot(saveId, liveEvent: event));
          } else {
            _queueNetworkSnapshotApply(
              saveId: saveId,
              snapshot: snapshot,
              liveEvent: event,
            );
          }
        },
        onSnapshotResync: (snapshot) {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.connected,
          );
          _queueNetworkSnapshotApply(saveId: saveId, snapshot: snapshot);
        },
        onMatch: (match) {
          if (!ref.mounted || _saveId != saveId) return;
          ref.read(multiplayerMatchProvider.notifier).upsert(match);
        },
        onConnected: () {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.connected,
          );
        },
        onReconnecting: () {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.reconnecting,
            message: 'Live event stream reconnecting',
          );
        },
        onError: (error, stackTrace) {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.reconnecting,
            message: error.toString(),
          );
          _warn('Live event stream failed', error, stackTrace);
        },
        onDone: () {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.reconnecting,
            message: 'Live event stream closed',
          );
          _warn('Live event stream closed');
        },
      );
      if (!ref.mounted || _saveId != saveId) {
        await handle.close();
        starting.complete(null);
        return;
      }
      _liveEvents = handle;
      starting.complete(handle);
    } catch (error, stackTrace) {
      starting.complete(null);
      _warn('Could not start live event stream', error, stackTrace);
    } finally {
      if (identical(_liveEventsStarting, starting.future)) {
        _liveEventsStarting = null;
      }
    }
  }

  FutureOr<LiveEventSubscriptionHandle?> _liveCommandHandle() {
    return _liveEvents ?? _liveEventsStarting;
  }

  Future<void> _reloadNetworkSnapshot(
    String saveId, {
    LiveServerEvent? liveEvent,
    int attempt = 0,
  }) async {
    if (!ref.mounted || _saveId != saveId) return;
    try {
      final snapshot = await gameRepositoryForSave(ref, saveId).load(saveId);
      final liveOffset = liveEvent?.wire.offset;
      if (liveOffset != null && snapshot.eventLogOffset < liveOffset) {
        if (attempt < _liveSnapshotRetryDelays.length) {
          final delay = _liveSnapshotRetryDelays[attempt];
          _warn(
            'Snapshot offset ${snapshot.eventLogOffset} is behind live '
            'event offset $liveOffset; retrying in ${delay.inMilliseconds}ms',
          );
          await Future<void>.delayed(delay);
          return _reloadNetworkSnapshot(
            saveId,
            liveEvent: liveEvent,
            attempt: attempt + 1,
          );
        }
        _warn(
          'Snapshot offset ${snapshot.eventLogOffset} stayed behind live '
          'event offset $liveOffset; keeping the current state',
        );
        return;
      }
      _queueNetworkSnapshotApply(
        saveId: saveId,
        snapshot: snapshot,
        liveEvent: liveEvent,
      );
    } catch (error, stackTrace) {
      _warn('Could not reload network snapshot', error, stackTrace);
    }
  }

  void _setNetworkConnectionStatus(
    String saveId,
    NetworkConnectionStatus status, {
    String? message,
  }) {
    if (!ref.mounted) return;
    final session = ref.read(networkSessionProvider);
    if (session == null || session.matchId != saveId) return;
    final current = ref.read(multiplayerConnectionStatusProvider);
    if (current?.saveId == saveId &&
        current?.status == status &&
        current?.message == message) {
      return;
    }
    ref
        .read(multiplayerConnectionStatusProvider.notifier)
        .setStatus(
          MultiplayerConnectionStatusSnapshot(
            saveId: saveId,
            status: status,
            message: message,
            changedAt: ref.read(gameClockProvider).nowUtc(),
          ),
        );
  }

  void _queueNetworkSnapshotApply({
    required String saveId,
    required SaveSnapshot snapshot,
    LiveServerEvent? liveEvent,
  }) {
    _networkSnapshotQueue = _networkSnapshotQueue.then(
      (_) => _applyNetworkSnapshot(
        saveId: saveId,
        snapshot: snapshot,
        liveEvent: liveEvent,
      ),
      onError: (Object error, StackTrace stackTrace) {
        _warn('Previous network snapshot apply failed', error, stackTrace);
        return _applyNetworkSnapshot(
          saveId: saveId,
          snapshot: snapshot,
          liveEvent: liveEvent,
        );
      },
    );
  }

  Future<void> _applyNetworkSnapshot({
    required String saveId,
    required SaveSnapshot snapshot,
    LiveServerEvent? liveEvent,
  }) async {
    if (!ref.mounted || _saveId != saveId) return;
    final liveOffset = liveEvent?.wire.offset;
    if (liveOffset != null &&
        snapshot.eventLogOffset > 0 &&
        snapshot.eventLogOffset < liveOffset) {
      _warn(
        'Ignoring stale snapshot offset ${snapshot.eventLogOffset} for '
        'live event offset $liveOffset',
      );
      return;
    }
    final incomingOffset = snapshot.eventLogOffset > 0
        ? snapshot.eventLogOffset
        : liveOffset ?? 0;
    if (incomingOffset > 0 && incomingOffset <= _eventLogOffset) {
      return;
    }
    final hasOffsetGap = liveOffset != null && liveOffset > _eventLogOffset + 1;
    if (hasOffsetGap) {
      _warn(
        'Detected live event offset gap: current $_eventLogOffset, '
        'incoming $liveOffset; applying authoritative snapshot',
      );
    }

    final previousState = state.value;
    final viewerPlayerId = ref.read(networkSessionProvider)?.playerId;
    final control = PlayerControlCoordinator.initialForPlayer(
      save: snapshot.save,
      preferredPlayerId: viewerPlayerId,
    );
    final nextState = snapshot.toGameState(
      activePlayerId: control.activePlayerId,
      activePlayerCanAct: control.canAct,
    );
    _eventLogOffset = incomingOffset;
    state = AsyncData(nextState);
    await _cacheAppliedSnapshot(
      saveId: saveId,
      snapshot: snapshot,
      offset: incomingOffset,
    );

    final liveEvents = hasOffsetGap
        ? const <GameEvent>[]
        : liveEvent?.events ?? const <GameEvent>[];
    final renderer = ref.read(activeRendererViewModelProvider);
    if (renderer != null && previousState != null) {
      final transitionEffects = _rendererEffectsForExternalSnapshot(
        previousState: previousState,
        nextState: nextState,
        events: liveEvents,
        viewerPlayerId: viewerPlayerId,
      );
      await renderer.applyTransition(nextState, transitionEffects);
    }
    if (previousState != null && ref.mounted) {
      ref
          .read(gameEventNotificationsProvider.notifier)
          .addAll(
            liveEvents,
            nextState,
            previousState: previousState,
            turn: snapshot.save.turn,
          );
    }
  }

  Future<void> _cacheAppliedSnapshot({
    required String saveId,
    required SaveSnapshot snapshot,
    required int offset,
  }) async {
    if (!ref.mounted || _saveId != saveId) return;
    final session = ref.read(networkSessionProvider);
    if (session == null || session.matchId != saveId) return;
    try {
      await ref
          .read(snapshotStoreProvider)
          .save(
            saveId,
            Snapshot(
              offset: offset,
              state: snapshot,
              createdAt: ref.read(gameClockProvider).nowUtc(),
            ),
          );
      ref.invalidate(gameSaveSnapshotProvider(saveId));
    } catch (error, stackTrace) {
      _warn('Could not cache network snapshot', error, stackTrace);
    }
  }

  void _warn(String message, [Object? error, StackTrace? stackTrace]) {
    if (!ref.mounted) return;
    ref
        .read(gameLoggerProvider)
        .warn('GameStateNotifier', message, error, stackTrace);
  }

  List<RendererEffect> _rendererEffectsForExternalSnapshot({
    required GameState previousState,
    required GameState nextState,
    required Iterable<GameEvent> events,
    String? viewerPlayerId,
  }) {
    final movementEffects = QueuedMovementEffectBuilder.fromUnitDelta(
      beforeUnits: previousState.units,
      afterUnits: nextState.units,
    );
    final animatedUnitIds = {
      for (final effect in movementEffects) effect.unitId,
    };
    return [
      ...movementEffects,
      ...GameEventRendererEffectMapper.effectsFor(
        events: events,
        state: nextState,
        previousState: previousState,
        skipUnitMoveIds: animatedUnitIds,
        viewerPlayerId: viewerPlayerId,
      ),
    ];
  }

  Future<void> _closeLiveEvents() async {
    final liveEvents = _liveEvents;
    _liveEvents = null;
    _liveEventsStarting = null;
    await liveEvents?.close();
  }
}
