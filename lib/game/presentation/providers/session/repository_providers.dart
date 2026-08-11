import 'dart:async';

import 'package:aonw/api/client/api_config.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_refresh_coordinator.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/api/session/serverpod_native_social_auth_session.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/api/transport/network_command_transport.dart';
import 'package:aonw/api/transport/network_event_log.dart';
import 'package:aonw/api/transport/network_game_repository.dart';
import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw/game/application/ports/native_social_auth.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/network_session_store.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/ports/wire_command_dispatcher.dart';
import 'package:aonw/game/application/services/network_session_state_machine.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/infrastructure/logging/developer_game_logger.dart';
import 'package:aonw/game/infrastructure/persistence/platform_persistence_adapters_io.dart'
    if (dart.library.js_interop) 'package:aonw/game/infrastructure/persistence/web/platform_persistence_adapters_web.dart';
import 'package:aonw/game/infrastructure/system/system_clock.dart';
import 'package:aonw/game/infrastructure/system/timestamp_id_generator.dart';
import 'package:aonw/game/infrastructure/transport/local_command_transport.dart';
import 'package:aonw/game/presentation/controllers/lobby_connection_controller.dart';
import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_connection_status_provider.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repository_providers.g.dart';

@riverpod
Clock gameClock(Ref ref) {
  return const SystemClock();
}

@riverpod
IdGenerator saveIdGenerator(Ref ref) {
  return TimestampIdGenerator(clock: ref.watch(gameClockProvider));
}

@riverpod
GameLogger gameLogger(Ref ref) {
  return const DeveloperGameLogger();
}

@riverpod
GameRepository gameRepository(Ref ref) {
  return buildLocalGameRepository(ref);
}

GameRepository gameRepositoryForSave(Ref ref, String saveId) {
  final activeNetworkSave = ref.watch(
    networkSessionProvider.select(
      (session) => _isActiveNetworkSave(session: session, saveId: saveId),
    ),
  );
  if (activeNetworkSave) {
    return ref.watch(networkGameRepositoryProvider);
  }

  return ref.watch(gameRepositoryProvider);
}

GameRepository buildLocalGameRepository(Ref ref) {
  return createPlatformGameRepository(
    clock: ref.watch(gameClockProvider),
    idGenerator: ref.watch(saveIdGeneratorProvider),
  );
}

@riverpod
EventLog eventLog(Ref ref) {
  return buildLocalEventLog();
}

EventLog eventLogForSave(Ref ref, String saveId) {
  final activeNetworkSave = ref.watch(
    networkSessionProvider.select(
      (session) => _isActiveNetworkSave(session: session, saveId: saveId),
    ),
  );
  if (activeNetworkSave) {
    return ref.watch(networkEventLogProvider);
  }

  return ref.watch(eventLogProvider);
}

final networkGameRepositoryProvider = fr.Provider<GameRepository>((ref) {
  ref.watch(networkSessionProvider.select(_transportSessionScope));
  final session = ref.read(networkSessionProvider);
  if (session == null || !session.isConnected || session.matchId == null) {
    throw StateError('No active multiplayer session for network repository.');
  }
  final repository = NetworkGameRepository(
    serverpodHost: ref.watch(apiConfigProvider).baseUrl.toString(),
    userId: session.userId,
    token: session.token,
    snapshotCache: ref.watch(snapshotStoreProvider),
    authKeyProviderFactory: _authKeyProviderFactory(ref),
  );
  ref.onDispose(repository.close);
  return repository;
});

final networkEventLogProvider = fr.Provider<EventLog>((ref) {
  ref.watch(networkSessionProvider.select(_transportSessionScope));
  final session = ref.read(networkSessionProvider);
  if (session == null || !session.isConnected || session.matchId == null) {
    throw StateError('No active multiplayer session for network event log.');
  }
  final eventLog = NetworkEventLog(
    serverpodHost: ref.watch(apiConfigProvider).baseUrl.toString(),
    token: session.token,
    recipientPlayerId: session.playerId,
    authKeyProviderFactory: _authKeyProviderFactory(ref),
  );
  ref.onDispose(eventLog.close);
  return eventLog;
});

EventLog buildLocalEventLog() {
  return createPlatformEventLog();
}

bool _isActiveNetworkSave({
  required NetworkSession? session,
  required String saveId,
}) {
  return saveId.isNotEmpty &&
      session != null &&
      session.isConnected &&
      session.matchId == saveId;
}

@riverpod
SnapshotStore snapshotStore(Ref ref) {
  return createPlatformSnapshotStore(clock: ref.watch(gameClockProvider));
}

@riverpod
ReplayStore replayStore(Ref ref) {
  return createPlatformReplayStore();
}

@Riverpod(keepAlive: true)
ApiConfig apiConfig(Ref ref) {
  const configuredBaseUrl = String.fromEnvironment('AONW_API_BASE_URL');
  final baseUrl = configuredBaseUrl.isEmpty
      ? _defaultLocalApiBaseUrl()
      : configuredBaseUrl;
  return ApiConfig(baseUrl: Uri.parse(baseUrl));
}

String _defaultLocalApiBaseUrl() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

@Riverpod(keepAlive: true)
MultiplayerStreamConnector multiplayerStreamConnector(Ref ref) {
  final host = ref.watch(apiConfigProvider).baseUrl.toString();
  return ServerpodMultiplayerStreamConnector(
    host,
    authKeyProviderFactory: _authKeyProviderFactory(ref),
  ).connect;
}

@Riverpod(keepAlive: true)
LiveMultiplayerEvents liveMultiplayerEvents(Ref ref) {
  return LiveEventSubscription(
    serverpodHost: ref.watch(apiConfigProvider).baseUrl.toString(),
    connector: ref.watch(multiplayerStreamConnectorProvider),
  );
}

@Riverpod(keepAlive: true)
WireCommandDispatcher wireCommandDispatcher(Ref ref) {
  final host = ref.watch(apiConfigProvider).baseUrl.toString();
  final dispatcher = ServerpodWireCommandDispatcher(
    serverpodHost: host,
    authKeyProviderFactory: _authKeyProviderFactory(ref),
  );
  ref.onDispose(dispatcher.close);
  return dispatcher;
}

@Riverpod(keepAlive: true)
MultiplayerSessionGateway networkSessionClient(Ref ref) {
  final client = NetworkSessionClient(
    serverpodHost: ref.watch(apiConfigProvider).baseUrl.toString(),
    authKeyProviderFactory: _authKeyProviderFactory(ref),
  );
  ref.onDispose(client.close);
  return client;
}

@Riverpod(keepAlive: true)
NativeSocialAuthSessionFactory nativeSocialAuthSessionFactory(Ref ref) {
  final host = ref.watch(apiConfigProvider).baseUrl.toString();
  return () => ServerpodNativeSocialAuthSession(host);
}

@Riverpod(keepAlive: true)
NetworkSessionStorePort networkSessionStore(Ref ref) {
  return NetworkSessionStore();
}

final networkSessionRefreshCoordinatorProvider =
    fr.Provider<NetworkSessionRefreshCoordinator>((ref) {
      final sessionClient = ref.read(networkSessionClientProvider);
      return NetworkSessionRefreshCoordinator(
        currentSession: () => ref.read(networkSessionProvider),
        setSession: ref.read(networkSessionStateProvider.notifier).set,
        sessionStore: ref.read(networkSessionStoreProvider),
        refreshToken: sessionClient.refresh,
        now: () => ref.read(gameClockProvider).nowUtc(),
      );
    });

final lobbyAuthenticatedSessionActivatorProvider =
    fr.Provider<LobbyAuthenticatedSessionActivator>((ref) {
      return _LobbyRefreshCoordinatorSessionActivator(
        ref.read(networkSessionRefreshCoordinatorProvider),
      );
    });

final class _LobbyRefreshCoordinatorSessionActivator
    implements LobbyAuthenticatedSessionActivator {
  const _LobbyRefreshCoordinatorSessionActivator(this._coordinator);

  final NetworkSessionRefreshCoordinator _coordinator;

  @override
  Future<void> activate({
    required NetworkSession session,
    required String displayName,
  }) {
    return _coordinator.activateAuthenticatedSession(
      session: session,
      displayName: displayName,
    );
  }
}

final networkSessionReducerProvider = fr.Provider<NetworkSessionReducer>(
  (ref) => const NetworkSessionReducer(),
);

final networkSessionEffectRunnerProvider =
    fr.Provider<NetworkSessionEffectRunner>((ref) {
      final store = ref.watch(networkSessionStoreProvider);
      final statusNotifier = ref.watch(
        multiplayerConnectionStatusProvider.notifier,
      );
      final logger = ref.watch(gameLoggerProvider);
      return NetworkSessionEffectRunner(
        persistMatchId: (matchId) => store.saveMatchId(matchId),
        publishTransportStatus: (effect) {
          statusNotifier.setStatus(
            MultiplayerConnectionStatusSnapshot(
              saveId: effect.saveId,
              status: effect.status,
              changedAt: effect.changedAt,
              message: effect.message,
            ),
          );
        },
        clearTransportStatus: statusNotifier.clear,
        onError: (error, stackTrace) {
          logger.warn(
            'NetworkSessionEffectRunner',
            'Could not run a network session effect',
            error,
            stackTrace,
          );
        },
      );
    });

@Riverpod(keepAlive: true)
class NetworkSessionState extends _$NetworkSessionState {
  @override
  NetworkSessionTransportState build() => NetworkSessionTransportState.initial;

  void set(NetworkSession? session) {
    unawaited(dispatch(ReplaceNetworkSessionAction(session)));
  }

  Future<void> activateMatch({
    required String expectedUserId,
    String? playerId,
    required String matchId,
    required DateTime changedAt,
    bool persistMatchId = true,
  }) {
    return dispatch(
      ActivateNetworkMatchAction(
        expectedUserId: expectedUserId,
        playerId: playerId,
        matchId: matchId,
        changedAt: changedAt,
        persistMatchId: persistMatchId,
      ),
    );
  }

  Future<void> clearMatch({
    required String expectedUserId,
    required DateTime changedAt,
  }) {
    return dispatch(
      ClearNetworkMatchAction(
        expectedUserId: expectedUserId,
        changedAt: changedAt,
      ),
    );
  }

  Future<void> rememberMatch(String matchId) {
    return dispatch(RememberNetworkMatchAction(matchId));
  }

  void reportTransportStatus({
    required String saveId,
    required NetworkConnectionStatus status,
    required DateTime changedAt,
    String? message,
  }) {
    unawaited(
      dispatch(
        ReportNetworkTransportStatusAction(
          saveId: saveId,
          status: status,
          changedAt: changedAt,
          message: message,
        ),
      ),
    );
  }

  Future<void> dispatch(NetworkSessionAction action) async {
    final transition = ref
        .read(networkSessionReducerProvider)
        .reduce(state, action);
    if (!identical(transition.state, state)) state = transition.state;
    if (transition.effects.isEmpty) return;
    await ref
        .read(networkSessionEffectRunnerProvider)
        .runAll(transition.effects);
  }
}

@riverpod
NetworkSession? networkSession(Ref ref) {
  return ref.watch(
    networkSessionStateProvider.select((state) => state.session),
  );
}

DispatchCommandUseCase buildDispatchCommandUseCase(
  Ref ref,
  GameStateReducer reducer,
  GameMode gameMode, {
  required String saveId,
  WireCommandDispatcher? commandDispatcher,
  bool requiresNetworkTransport = false,
}) {
  ref.watch(networkSessionProvider.select(_transportSessionScope));
  final session = ref.read(networkSessionProvider);
  final activeNetworkTransport =
      gameMode == GameMode.multiplayer &&
      canUseNetworkMatchTransport(session: session, saveId: saveId);
  final targetsNetworkMatch =
      requiresNetworkTransport ||
      (gameMode == GameMode.multiplayer && session?.matchId == saveId);
  if (targetsNetworkMatch && !activeNetworkTransport) {
    throw StateError(
      'Network-backed save requires a connected matching session '
      'with an assigned playerId.',
    );
  }
  if (activeNetworkTransport) {
    final activeSession = session!;
    final playerId = activeSession.playerId!;
    final repository = gameRepositoryForSave(ref, saveId);
    return DispatchCommandUseCase(
      commandTransport: NetworkCommandTransport(
        serverpodHost: ref.watch(apiConfigProvider).baseUrl.toString(),
        token: activeSession.token,
        tokenReader: ref
            .read(networkSessionRefreshCoordinatorProvider)
            .currentToken,
        actorPlayerId: playerId,
        commandDispatcher:
            commandDispatcher ?? ref.watch(wireCommandDispatcherProvider),
        tickGenerator: ClientTickGenerator(),
        localReducer: reducer,
        gameRepository: repository,
      ),
    );
  }

  final repository = gameRepositoryForSave(ref, saveId);
  return DispatchCommandUseCase(
    commandTransport: LocalCommandTransport(
      reducer: reducer,
      gameRepository: repository,
      eventLog: eventLogForSave(ref, saveId),
      snapshotStore: ref.watch(snapshotStoreProvider),
      clock: ref.watch(gameClockProvider),
    ),
  );
}

ServerpodAuthKeyProviderFactory _authKeyProviderFactory(fr.Ref ref) {
  return () => NetworkSessionAuthKeyProvider(
    ref.read(networkSessionRefreshCoordinatorProvider),
  );
}

({String? userId, String? playerId, String? matchId, bool connected})
_transportSessionScope(NetworkSession? session) {
  return (
    userId: session?.userId,
    playerId: session?.playerId,
    matchId: session?.matchId,
    connected: session?.isConnected ?? false,
  );
}
