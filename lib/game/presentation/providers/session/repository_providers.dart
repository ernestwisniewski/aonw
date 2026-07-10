import 'package:aonw/api/client/api_config.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_refresh_coordinator.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/api/transport/network_command_transport.dart';
import 'package:aonw/api/transport/network_event_log.dart';
import 'package:aonw/api/transport/network_game_repository.dart';
import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/infrastructure/logging/developer_game_logger.dart';
import 'package:aonw/game/infrastructure/persistence/platform_persistence_adapters_io.dart'
    if (dart.library.js_interop) 'package:aonw/game/infrastructure/persistence/web/platform_persistence_adapters_web.dart';
import 'package:aonw/game/infrastructure/system/system_clock.dart';
import 'package:aonw/game/infrastructure/system/timestamp_id_generator.dart';
import 'package:aonw/game/infrastructure/transport/local_command_transport.dart';
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
  return NetworkGameRepository(
    serverpodHost: ref.watch(apiConfigProvider).baseUrl.toString(),
    userId: session.userId,
    token: session.token,
    snapshotCache: ref.watch(snapshotStoreProvider),
    authKeyProviderFactory: _authKeyProviderFactory(ref),
  );
});

final networkEventLogProvider = fr.Provider<EventLog>((ref) {
  ref.watch(networkSessionProvider.select(_transportSessionScope));
  final session = ref.read(networkSessionProvider);
  if (session == null || !session.isConnected || session.matchId == null) {
    throw StateError('No active multiplayer session for network event log.');
  }
  return NetworkEventLog(
    serverpodHost: ref.watch(apiConfigProvider).baseUrl.toString(),
    token: session.token,
    authKeyProviderFactory: _authKeyProviderFactory(ref),
  );
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
WireCommandDispatcher wireCommandDispatcher(Ref ref) {
  final host = ref.watch(apiConfigProvider).baseUrl.toString();
  return ServerpodWireCommandDispatcher(
    serverpodHost: host,
    authKeyProviderFactory: _authKeyProviderFactory(ref),
  );
}

@Riverpod(keepAlive: true)
NetworkSessionClient networkSessionClient(Ref ref) {
  return NetworkSessionClient(
    serverpodHost: ref.watch(apiConfigProvider).baseUrl.toString(),
    authKeyProviderFactory: _authKeyProviderFactory(ref),
  );
}

@Riverpod(keepAlive: true)
NetworkSessionStore networkSessionStore(Ref ref) {
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

@Riverpod(keepAlive: true)
class NetworkSessionState extends _$NetworkSessionState {
  @override
  NetworkSession? build() => null;

  void set(NetworkSession? session) => state = session;
}

@riverpod
NetworkSession? networkSession(Ref ref) {
  return ref.watch(networkSessionStateProvider);
}

DispatchCommandUseCase buildDispatchCommandUseCase(
  Ref ref,
  GameStateReducer reducer,
  GameMode gameMode, {
  required String saveId,
  WireCommandDispatcher? commandDispatcher,
}) {
  ref.watch(networkSessionProvider.select(_transportSessionScope));
  final session = ref.read(networkSessionProvider);
  final repository = gameRepositoryForSave(ref, saveId);
  if (gameMode == GameMode.multiplayer &&
      session != null &&
      session.isConnected &&
      session.matchId == saveId) {
    return DispatchCommandUseCase(
      commandTransport: NetworkCommandTransport(
        serverpodHost: ref.watch(apiConfigProvider).baseUrl.toString(),
        token: session.token,
        tokenReader: ref
            .read(networkSessionRefreshCoordinatorProvider)
            .currentToken,
        actorPlayerId: session.playerId ?? session.userId,
        commandDispatcher:
            commandDispatcher ?? ref.watch(wireCommandDispatcherProvider),
        tickGenerator: ClientTickGenerator(),
        localReducer: reducer,
        gameRepository: repository,
      ),
    );
  }

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
