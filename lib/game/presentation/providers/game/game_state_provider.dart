import 'dart:async';

import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/api/transport/live_wire_command_dispatcher.dart';
import 'package:aonw/api/transport/multiplayer_snapshot_cache_key.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/live_snapshot_presentation_policy.dart';
import 'package:aonw/game/application/services/multiplayer_interaction_reconciler.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/application/use_cases/bootstrap_game_state_use_case.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_save.dart' show GameMode;
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue_mapper.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/game/presentation/engine/renderer_view_model.dart';
import 'package:aonw/game/presentation/providers/audio/game_audio_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_activity_history_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/game/live_snapshot_presentation_resolver.dart'
    as live;
import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_connection_status_provider.dart';
import 'package:aonw/game/presentation/providers/renderer/renderer_provider.dart';
import 'package:aonw/game/presentation/providers/ruleset/ruleset_providers.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_state_provider.g.dart';
part 'game_state_provider_renderer_effects.dart';
part 'game_state_provider_turn_lifecycle.dart';

@Riverpod(
  retry: _doNotRetry,
  dependencies: [activeGameSession, networkSession, activeRendererViewModel],
)
class GameStateNotifier extends _$GameStateNotifier {
  DispatchCommandUseCase? _dispatchCommand;
  GameStateReducer? _reducer;
  LiveEventSubscriptionHandle? _liveEvents;
  Future<LiveEventSubscriptionHandle?>? _liveEventsStarting;
  String _saveId = '';
  Future<void> _dispatchQueue = Future<void>.value();
  Future<void> _networkSnapshotQueue = Future<void>.value();
  int _eventLogOffset = 0;
  Ref get _providerRef => ref;
  bool get _isMounted => ref.mounted;
  GameClientState? get _stateValue => state.value;
  Future<GameClientState> get _stateFuture => future;
  set _stateValue(GameClientState value) => state = AsyncData(value);

  @override
  Future<GameClientState> build(String saveId) => _buildState(saveId);

  Future<void> syncActivePlayer({
    required String playerId,
    required bool canAct,
  }) => _enqueueDispatch(() async {
    final current = state.value;
    final reducer = _reducer;
    if (!ref.mounted || current == null || reducer == null) return;
    state = AsyncData(
      reducer
          .syncActivePlayer(current, playerId: playerId, canAct: canAct)
          .state,
    );
  });

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
        tokenReader: () =>
            ref.read(networkSessionRefreshCoordinatorProvider).currentToken(),
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

  Future<void> _applyNetworkSnapshot({
    required String saveId,
    required CanonicalGameSnapshot snapshot,
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
    if (incomingOffset > 0 && incomingOffset <= _eventLogOffset) return;
    final presentation = live.resolve(_eventLogOffset, liveEvent, snapshot);
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
    final authoritativeState = snapshot.toClientState(
      activePlayerId: control.activePlayerId,
      activePlayerCanAct: control.canAct,
    );
    final nextState = previousState == null
        ? authoritativeState
        : MultiplayerInteractionReconciler.reconcile(
            authoritativeState: authoritativeState,
            interactionSource: previousState,
          );
    _eventLogOffset = incomingOffset;
    state = AsyncData(nextState);
    await _cacheAppliedSnapshot(
      saveId: saveId,
      snapshot: snapshot,
      offset: incomingOffset,
    );
    await _presentExternalSnapshot(
      previousState: previousState,
      nextState: nextState,
      events: _presentedLiveEvents(presentation, liveEvent),
      movementExecutions: presentation.movementExecutions,
      identity: _liveBatchIdentity(saveId, incomingOffset),
      viewerPlayerId: viewerPlayerId,
      turn: snapshot.save.turn,
      renderer: ref.read(activeRendererViewModelProvider),
      audioController: ref.read(gameAudioControllerProvider),
      notifications: ref.read(gameEventNotificationsProvider.notifier),
      isMounted: () => ref.mounted,
    );
  }

  Future<void> _cacheAppliedSnapshot({
    required String saveId,
    required CanonicalGameSnapshot snapshot,
    required int offset,
  }) async {
    if (!ref.mounted || _saveId != saveId) return;
    final session = ref.read(networkSessionProvider);
    if (session == null || session.matchId != saveId) return;
    try {
      await ref
          .read(snapshotStoreProvider)
          .save(
            _multiplayerCacheKey(session.userId, saveId),
            Snapshot(
              state: snapshot.withEventLogOffset(offset),
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
    _warnGameState(ref, message, error, stackTrace);
  }
}
