import 'dart:async';

import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/multiplayer_interaction_reconciler.dart';
import 'package:aonw/game/application/services/multiplayer_snapshot_cache_key.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/audio/game_audio_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_state_effects.dart';
import 'package:aonw/game/presentation/providers/game/game_state_runtime.dart';
import 'package:aonw/game/presentation/providers/game/live_snapshot_presentation_resolver.dart'
    as live;
import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_connection_status_provider.dart';
import 'package:aonw/game/presentation/providers/renderer/renderer_provider.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';

const _liveSnapshotRetryDelays = [
  Duration(milliseconds: 150),
  Duration(milliseconds: 350),
  Duration(milliseconds: 750),
];

String _multiplayerCacheKey(String userId, String saveId) {
  return multiplayerSnapshotCacheKey(userId: userId, matchId: saveId);
}

final class GameStateMultiplayerSync {
  GameStateMultiplayerSync({
    required GameStateBinding binding,
    required GameStateRuntime runtime,
    required GameStateEffects effects,
  }) : _binding = binding,
       _runtime = runtime,
       _effects = effects;

  final GameStateBinding _binding;
  final GameStateRuntime _runtime;
  final GameStateEffects _effects;
  Future<void> _networkSnapshotQueue = Future<void>.value();

  Future<void> startLiveEvents(
    String saveId, {
    required GameMode gameMode,
  }) async {
    if (gameMode != GameMode.multiplayer) return;

    final session = _binding.ref.read(networkSessionProvider);
    if (session == null ||
        !session.isConnected ||
        session.matchId != saveId ||
        session.token.value.isEmpty) {
      return;
    }

    final starting = Completer<LiveMultiplayerEventHandle?>();
    _runtime.liveEventsStarting = starting.future;
    try {
      final subscription = _binding.ref.read(liveMultiplayerEventsProvider);
      final handle = await subscription.subscribe(
        matchId: saveId,
        token: session.token,
        tokenReader: () => _binding.ref
            .read(networkSessionRefreshCoordinatorProvider)
            .currentToken(),
        fromOffset: _runtime.eventLogOffset + 1,
        nextOffset: () => _runtime.eventLogOffset + 1,
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
          if (!_binding.isMounted() || _runtime.saveId != saveId) return;
          _binding.ref.read(multiplayerMatchProvider.notifier).upsert(match);
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
          _effects.warn('Live event stream failed', error, stackTrace);
        },
        onDone: () {
          _setNetworkConnectionStatus(
            saveId,
            NetworkConnectionStatus.reconnecting,
            message: 'Live event stream closed',
          );
          _effects.warn('Live event stream closed');
        },
      );
      if (!_binding.isMounted() || _runtime.saveId != saveId) {
        await handle.close();
        starting.complete(null);
        return;
      }
      _runtime.liveEvents = handle;
      starting.complete(handle);
    } catch (error, stackTrace) {
      starting.complete(null);
      _effects.warn('Could not start live event stream', error, stackTrace);
    } finally {
      if (identical(_runtime.liveEventsStarting, starting.future)) {
        _runtime.liveEventsStarting = null;
      }
    }
  }

  Future<void> _reloadNetworkSnapshot(
    String saveId, {
    LiveServerEvent? liveEvent,
    int attempt = 0,
  }) async {
    if (!_binding.isMounted() || _runtime.saveId != saveId) return;
    try {
      final snapshot = await gameRepositoryForSave(
        _binding.ref,
        saveId,
      ).load(saveId);
      final liveOffset = liveEvent?.wire.offset;
      if (liveOffset != null && snapshot.eventLogOffset < liveOffset) {
        if (attempt < _liveSnapshotRetryDelays.length) {
          final delay = _liveSnapshotRetryDelays[attempt];
          _effects.warn(
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
        _effects.warn(
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
      _effects.warn('Could not reload network snapshot', error, stackTrace);
    }
  }

  void _setNetworkConnectionStatus(
    String saveId,
    NetworkConnectionStatus status, {
    String? message,
  }) {
    if (!_binding.isMounted()) return;
    final session = _binding.ref.read(networkSessionProvider);
    if (session == null || session.matchId != saveId) return;
    _binding.ref
        .read(networkSessionStateProvider.notifier)
        .reportTransportStatus(
          saveId: saveId,
          status: status,
          message: message,
          changedAt: _binding.ref.read(gameClockProvider).nowUtc(),
        );
  }

  Future<void> _applyNetworkSnapshot({
    required String saveId,
    required CanonicalGameSnapshot snapshot,
    LiveServerEvent? liveEvent,
  }) async {
    if (!_binding.isMounted() || _runtime.saveId != saveId) return;
    final incomingOffset = _acceptedNetworkSnapshotOffset(
      snapshot: snapshot,
      liveEvent: liveEvent,
    );
    if (incomingOffset == null) return;
    final presentation = live.resolve(
      _runtime.eventLogOffset,
      liveEvent,
      snapshot,
    );
    final previousState = _binding.readState();
    final viewerPlayerId = _binding.ref.read(networkSessionProvider)?.playerId;
    final nextState = _reconcileNetworkSnapshotState(
      snapshot: snapshot,
      previousState: previousState,
      viewerPlayerId: viewerPlayerId,
    );
    _runtime.eventLogOffset = incomingOffset;
    _binding.writeState(nextState);
    await cacheAppliedSnapshot(
      saveId: saveId,
      snapshot: snapshot,
      offset: incomingOffset,
    );
    await _effects.presentExternalSnapshot(
      previousState: previousState,
      nextState: nextState,
      events: presentedLiveEvents(presentation, liveEvent),
      movementExecutions: presentation.movementExecutions,
      identity: liveBatchIdentity(saveId, incomingOffset, liveEvent),
      viewerPlayerId: viewerPlayerId,
      turn: snapshot.save.turn,
      renderer: _binding.ref.read(activeRendererViewModelProvider),
      audioController: _binding.ref.read(gameAudioControllerProvider),
      notifications: _binding.ref.read(gameEventNotificationsProvider.notifier),
    );
  }

  int? _acceptedNetworkSnapshotOffset({
    required CanonicalGameSnapshot snapshot,
    required LiveServerEvent? liveEvent,
  }) {
    final liveOffset = liveEvent?.wire.offset;
    if (liveOffset != null &&
        snapshot.eventLogOffset > 0 &&
        snapshot.eventLogOffset < liveOffset) {
      _effects.warn(
        'Ignoring stale snapshot offset ${snapshot.eventLogOffset} for '
        'live event offset $liveOffset',
      );
      return null;
    }
    final incomingOffset = snapshot.eventLogOffset > 0
        ? snapshot.eventLogOffset
        : liveOffset ?? 0;
    if (incomingOffset > 0 && incomingOffset <= _runtime.eventLogOffset) {
      return null;
    }
    if (liveOffset != null && liveOffset > _runtime.eventLogOffset + 1) {
      _effects.warn(
        'Detected live event offset gap: current ${_runtime.eventLogOffset}, '
        'incoming $liveOffset; applying authoritative snapshot',
      );
    }
    return incomingOffset;
  }

  GameClientState _reconcileNetworkSnapshotState({
    required CanonicalGameSnapshot snapshot,
    required GameClientState? previousState,
    required String? viewerPlayerId,
  }) {
    final control = PlayerControlCoordinator.initialForPlayer(
      save: snapshot.save,
      preferredPlayerId: viewerPlayerId,
    );
    final authoritativeState = snapshot.toClientState(
      activePlayerId: control.activePlayerId,
      activePlayerCanAct: control.canAct,
    );
    if (previousState == null) return authoritativeState;
    return MultiplayerInteractionReconciler.reconcile(
      authoritativeState: authoritativeState,
      interactionSource: previousState,
    );
  }

  Future<void> cacheAppliedSnapshot({
    required String saveId,
    required CanonicalGameSnapshot snapshot,
    required int offset,
  }) async {
    if (!_binding.isMounted() || _runtime.saveId != saveId) return;
    final session = _binding.ref.read(networkSessionProvider);
    if (session == null || session.matchId != saveId) return;
    try {
      await _binding.ref
          .read(snapshotStoreProvider)
          .save(
            _multiplayerCacheKey(session.userId, saveId),
            Snapshot(
              state: snapshot.withEventLogOffset(offset),
              createdAt: _binding.ref.read(gameClockProvider).nowUtc(),
            ),
          );
      _binding.ref.invalidate(gameSaveSnapshotProvider(saveId));
    } catch (error, stackTrace) {
      _effects.warn('Could not cache network snapshot', error, stackTrace);
    }
  }

  FutureOr<LiveMultiplayerEventHandle?> liveCommandHandle() {
    return _runtime.liveEvents ?? _runtime.liveEventsStarting;
  }

  void _queueNetworkSnapshotApply({
    required String saveId,
    required CanonicalGameSnapshot snapshot,
    LiveServerEvent? liveEvent,
  }) {
    _networkSnapshotQueue = _networkSnapshotQueue.then(
      (_) => _applyNetworkSnapshot(
        saveId: saveId,
        snapshot: snapshot,
        liveEvent: liveEvent,
      ),
      onError: (Object error, StackTrace stackTrace) {
        _effects.warn(
          'Previous network snapshot apply failed',
          error,
          stackTrace,
        );
        return _applyNetworkSnapshot(
          saveId: saveId,
          snapshot: snapshot,
          liveEvent: liveEvent,
        );
      },
    );
  }

  Future<void> closeLiveEvents() async {
    final liveEvents = _runtime.liveEvents;
    _runtime.liveEvents = null;
    _runtime.liveEventsStarting = null;
    await liveEvents?.close();
  }
}
