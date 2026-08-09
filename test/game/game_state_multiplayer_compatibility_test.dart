import 'dart:async';

import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_flow.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'multiplayer bootstrap follows the central compatibility decision',
    () async {
      const scenarios = [
        (access: MultiplayerAccessState.pending, shouldBootstrap: false),
        (access: MultiplayerAccessState.updateRequired, shouldBootstrap: false),
        (access: MultiplayerAccessState.unavailable, shouldBootstrap: false),
        (access: MultiplayerAccessState.allowed, shouldBootstrap: true),
      ];

      for (final scenario in scenarios) {
        final repository = _RecordingGameRepository(
          _save(GameMode.multiplayer),
        );
        final container = _container(
          repository: repository,
          gameMode: GameMode.multiplayer,
          access: scenario.access,
          networkSession: _networkSession(),
        );
        addTearDown(container.dispose);

        final state = await container.read(gameStateProvider(_saveId).future);

        expect(
          repository.loadCount,
          scenario.shouldBootstrap ? 1 : 0,
          reason: '${scenario.access} repository boundary',
        );
        expect(
          state.playerColors,
          scenario.shouldBootstrap ? isNotEmpty : isEmpty,
          reason: '${scenario.access} state boundary',
        );
      }
    },
  );

  test(
    'network save never falls back to local bootstrap or dispatch',
    () async {
      final invalidSessions =
          <({String label, NetworkSession? session, int originReads})>[
            (label: 'missing session', session: null, originReads: 1),
            (
              label: 'mismatched match',
              session: _networkSession(matchId: 'other_match'),
              originReads: 1,
            ),
            (
              label: 'offline match',
              session: _networkSession(connected: false),
              originReads: 0,
            ),
            (
              label: 'null player identity',
              session: _networkSession(playerId: null),
              originReads: 0,
            ),
            (
              label: 'empty player identity',
              session: _networkSession(playerId: ''),
              originReads: 0,
            ),
            (
              label: 'blank player identity',
              session: _networkSession(playerId: '  '),
              originReads: 0,
            ),
          ];

      for (final scenario in invalidSessions) {
        final localRepository = _RecordingGameRepository(
          _save(GameMode.multiplayer, origin: GameSaveOrigin.network),
        );
        final networkRepository = _RecordingGameRepository(
          _save(GameMode.multiplayer, origin: GameSaveOrigin.network),
        );
        final container = _container(
          repository: localRepository,
          networkRepository: networkRepository,
          gameMode: GameMode.multiplayer,
          access: MultiplayerAccessState.allowed,
          networkSession: scenario.session,
        );
        addTearDown(container.dispose);

        final state = await container.read(gameStateProvider(_saveId).future);
        await container
            .read(gameStateProvider(_saveId).notifier)
            .dispatchTransition(SubmitTurnCommand(_player.id));

        expect(state.playerColors, isEmpty, reason: scenario.label);
        expect(
          localRepository.loadCount,
          scenario.originReads,
          reason: '${scenario.label} may only read origin metadata',
        );
        expect(localRepository.saveCount, 0, reason: scenario.label);
        expect(networkRepository.loadCount, 0, reason: scenario.label);
        expect(networkRepository.saveCount, 0, reason: scenario.label);
      }
    },
  );

  test(
    'connected network save bootstraps only from network repository',
    () async {
      final localRepository = _RecordingGameRepository(
        _save(GameMode.multiplayer, origin: GameSaveOrigin.network),
      );
      final networkRepository = _RecordingGameRepository(
        _save(GameMode.multiplayer, origin: GameSaveOrigin.network),
      );
      final container = _container(
        repository: localRepository,
        networkRepository: networkRepository,
        gameMode: GameMode.multiplayer,
        access: MultiplayerAccessState.allowed,
        networkSession: _networkSession(),
      );
      addTearDown(container.dispose);

      final state = await container.read(gameStateProvider(_saveId).future);

      expect(state.playerColors, isNotEmpty);
      expect(localRepository.loadCount, 0);
      expect(localRepository.saveCount, 0);
      expect(networkRepository.loadCount, 1);
      expect(networkRepository.saveCount, 0);
    },
  );

  test('session changed after access decision stays fail-closed', () async {
    final accessDecision = Completer<MultiplayerSaveAccessDecision>();
    var currentSession = _networkSession();
    final localRepository = _RecordingGameRepository(
      _save(GameMode.multiplayer, origin: GameSaveOrigin.network),
    );
    final networkRepository = _RecordingGameRepository(
      _save(GameMode.multiplayer, origin: GameSaveOrigin.network),
    );
    final container = _container(
      repository: localRepository,
      networkRepository: networkRepository,
      gameMode: GameMode.multiplayer,
      access: MultiplayerAccessState.allowed,
      networkSessionReader: () => currentSession,
      saveAccessDecision: accessDecision.future,
    );
    addTearDown(container.dispose);

    final pendingState = container.read(gameStateProvider(_saveId).future);
    await Future<void>.delayed(Duration.zero);
    accessDecision.complete((
      state: MultiplayerAccessState.allowed,
      networkBacked: true,
    ));
    currentSession = _networkSession(connected: false);
    container.invalidate(networkSessionProvider);

    final state = await pendingState;

    expect(state.playerColors, isEmpty);
    expect(localRepository.loadCount, 0);
    expect(localRepository.saveCount, 0);
    expect(networkRepository.loadCount, 0);
    expect(networkRepository.saveCount, 0);
  });

  test('compatibility denial does not block single-player bootstrap', () async {
    final repository = _RecordingGameRepository(
      _save(
        NewGameFlow.singlePlayer.gameMode,
        players: _localSinglePlayerParticipants,
      ),
    );
    final container = _container(
      repository: repository,
      gameMode: NewGameFlow.singlePlayer.gameMode,
      access: MultiplayerAccessState.updateRequired,
    );
    addTearDown(container.dispose);

    final state = await container.read(gameStateProvider(_saveId).future);

    expect(repository.loadCount, 2);
    expect(state.playerColors, isNotEmpty);
    expect(NewGameFlow.singlePlayer.gameMode, GameMode.multiplayer);
  });

  test(
    'save refresh does not restart an active local game-state runtime',
    () async {
      final repository = _RecordingGameRepository(_save(GameMode.hotSeat));
      final container = _container(
        repository: repository,
        gameMode: GameMode.hotSeat,
        access: MultiplayerAccessState.updateRequired,
      );
      addTearDown(container.dispose);
      final gameState = gameStateProvider(_saveId);
      final stateSubscription = container.listen(
        gameState,
        (_, _) {},
        fireImmediately: true,
      );
      final accessSubscription = container.listen(
        multiplayerSaveAccessStateProvider(_saveId),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(stateSubscription.close);
      addTearDown(accessSubscription.close);

      await container.read(gameState.future);
      await container
          .read(gameState.notifier)
          .syncActivePlayer(playerId: _player.id, canAct: false);
      expect(container.read(gameState).value?.activePlayerCanAct, isFalse);

      container.invalidate(gameSaveSnapshotProvider(_saveId));
      await container.read(gameSaveProvider(_saveId).future);
      await container.read(multiplayerSaveAccessStateProvider(_saveId).future);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(gameState).value?.activePlayerCanAct, isFalse);
    },
  );
}

const _saveId = 'save_1';
const _player = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);

ProviderContainer _container({
  required _RecordingGameRepository repository,
  _RecordingGameRepository? networkRepository,
  required GameMode gameMode,
  required MultiplayerAccessState access,
  NetworkSession? networkSession,
  NetworkSession? Function()? networkSessionReader,
  Future<MultiplayerSaveAccessDecision>? saveAccessDecision,
}) {
  final eventLog = _EmptyEventLog();
  return ProviderContainer(
    overrides: [
      activeGameSessionProvider.overrideWithValue(
        GameSession(
          mapData: _map(),
          viewMode: MapViewMode.tile,
          saveId: _saveId,
          gameMode: gameMode,
        ),
      ),
      multiplayerAccessStateProvider.overrideWithValue(access),
      networkSessionProvider.overrideWith(
        (_) => networkSessionReader?.call() ?? networkSession,
      ),
      if (saveAccessDecision != null)
        multiplayerSaveAccessDecisionProvider(
          _saveId,
        ).overrideWith((_) => saveAccessDecision),
      gameRepositoryProvider.overrideWithValue(repository),
      networkGameRepositoryProvider.overrideWithValue(
        networkRepository ?? repository,
      ),
      eventLogProvider.overrideWithValue(eventLog),
      networkEventLogProvider.overrideWithValue(eventLog),
      liveMultiplayerEventsProvider.overrideWithValue(
        const _NoopLiveMultiplayerEvents(),
      ),
      snapshotStoreProvider.overrideWithValue(_EmptySnapshotStore()),
    ],
  );
}

const _localSinglePlayerParticipants = [
  _player,
  Player(
    id: 'ai',
    name: 'AI',
    colorValue: 0xFFC45050,
    kind: PlayerKind.ai,
    ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 1),
  ),
];

GameSave _save(
  GameMode gameMode, {
  List<Player> players = const [_player],
  GameSaveOrigin origin = GameSaveOrigin.local,
}) {
  return GameSave(
    id: _saveId,
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 8, 9),
    camera: CameraState.zero,
    players: players,
    gameMode: gameMode,
    origin: origin,
  );
}

NetworkSession _networkSession({
  String matchId = _saveId,
  String? playerId = 'player_1',
  bool connected = true,
}) {
  return NetworkSession(
    userId: 'user_1',
    playerId: playerId,
    token: AuthToken('token'),
    matchId: matchId,
    connectionState: connected
        ? const NetworkConnectionState(
            status: NetworkConnectionStatus.connected,
          )
        : NetworkConnectionState.offline,
  );
}

WorldMap _map() {
  return WorldMap(
    cols: 1,
    rows: 1,
    tiles: [
      WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}

final class _RecordingGameRepository implements GameRepository {
  _RecordingGameRepository(this.gameSave);

  final GameSave gameSave;
  int loadCount = 0;
  int saveCount = 0;

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) => throw UnimplementedError();

  @override
  Future<void> delete(String saveId) => throw UnimplementedError();

  @override
  Future<List<GameSaveIndex>> list() => throw UnimplementedError();

  @override
  Future<CanonicalGameSnapshot> load(String saveId) async {
    loadCount++;
    return GameSnapshotFactory.create(save: gameSave);
  }

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async {
    saveCount++;
  }

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) => throw UnimplementedError();
}

final class _EmptyEventLog implements EventLog {
  @override
  Future<void> append(String saveId, RecordedDomainCommand command) async {}

  @override
  Future<int> latestOffset(String saveId) async => 0;

  @override
  Stream<RecordedDomainCommand> readAll(String saveId) => const Stream.empty();

  @override
  Stream<RecordedDomainCommand> readSince(String saveId, {int offset = 0}) =>
      const Stream.empty();
}

final class _EmptySnapshotStore implements SnapshotStore {
  @override
  Future<Snapshot?> latest(String saveId) async => null;

  @override
  Future<void> save(String saveId, Snapshot snapshot) async {}
}

final class _NoopLiveMultiplayerEvents implements LiveMultiplayerEvents {
  const _NoopLiveMultiplayerEvents();

  @override
  Future<LiveMultiplayerEventHandle> subscribe({
    required String matchId,
    required AuthToken token,
    Future<AuthToken> Function()? tokenReader,
    required int fromOffset,
    int Function()? nextOffset,
    required void Function(LiveServerEvent event) onEvent,
    required void Function(CanonicalGameSnapshot snapshot) onSnapshotResync,
    void Function(WireMatch match)? onMatch,
    void Function()? onConnected,
    void Function()? onReconnecting,
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onDone,
  }) async {
    onConnected?.call();
    return const _NoopLiveMultiplayerEventHandle();
  }
}

final class _NoopLiveMultiplayerEventHandle
    implements LiveMultiplayerEventHandle {
  const _NoopLiveMultiplayerEventHandle();

  @override
  Future<void> close() async {}

  @override
  Future<WireCommandAck> sendCommand({
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
    Duration timeout = const Duration(seconds: 10),
  }) {
    throw UnimplementedError();
  }
}
