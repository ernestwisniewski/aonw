import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/presentation/controllers/lobby_connection_controller.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lobby_connection_controller_test.dart';
import 'support/lobby_connection_controller_test_store.dart';

typedef _FakeNetworkSessionClient = LobbyControllerTestClient;
typedef _MemoryNetworkSessionStore = LobbyControllerMemorySessionStore;
const _match = lobbyControllerTestMatch;
const _validValidation = lobbyControllerValidValidation;
const _emptyLiveEvents = emptyLobbyControllerLiveEvents;

void registerLobbyConnectionControllerLifecycleCases() {
  test('terminal lobby state returns every multiplayer mode safely', () async {
    final scenarios = <_TerminalLobbyScenario>[
      _TerminalLobbyScenario(
        name: 'quickplay',
        enter: (harness) => harness.controller.startQuickplayQueue(),
        signal: _TerminalLobbySignal.membershipError,
        expectedMode: LobbyMultiplayerMode.home,
      ),
      _TerminalLobbyScenario(
        name: 'public match',
        enter: (harness) async {
          await harness.controller.openPublicLobby();
          await harness.controller.joinPublicMatch(matchId: 'public_joined');
        },
        signal: _TerminalLobbySignal.abandonedMatch,
        expectedMode: LobbyMultiplayerMode.publicBrowse,
      ),
      _TerminalLobbyScenario(
        name: 'private host',
        enter: (harness) => harness.controller.createPrivateMatch(),
        signal: _TerminalLobbySignal.abandonedMatch,
        expectedMode: LobbyMultiplayerMode.home,
      ),
      _TerminalLobbyScenario(
        name: 'private participant',
        enter: (harness) async {
          harness.controller.openJoinPrivateMatch();
          await harness.controller.joinPrivateMatch(inviteCode: 'ABC123');
        },
        signal: _TerminalLobbySignal.missingUser,
        expectedMode: LobbyMultiplayerMode.privateJoin,
      ),
    ];

    for (final scenario in scenarios) {
      await _runTerminalLobbyScenario(scenario);
    }
  });

  test('failed public refresh removes the last clickable result', () async {
    final listed = _match(
      id: 'public_listed',
      state: 'open',
      quickplay: false,
      ownerUserId: 'host_user',
      players: const [
        WirePlayer(
          id: 'host_player',
          userId: 'host_user',
          name: 'Host',
          colorValue: 0xFFDC2626,
          kind: WirePlayerKind.human,
          connectionState: WirePlayerConnectionState.connected,
        ),
      ],
    );
    final client = _FakeNetworkSessionClient(
      quickplayMatch: _match(state: 'open'),
      listedMatches: [listed],
    );
    final harness = _ControllerHarness(client: client);
    addTearDown(harness.controller.dispose);

    await harness.controller.openPublicLobby();
    expect(harness.controller.publicMatches, [listed]);
    client.listMatchesError = StateError('discovery unavailable');
    await harness.controller.refreshPublicMatches();

    expect(harness.controller.publicMatches, isEmpty);
    expect(harness.controller.publicMatchesLoaded, isTrue);
    expect(harness.presentedErrors.single, contains('discovery unavailable'));
  });

  test('sign out leaves an open lobby before revoking the session', () async {
    final client = _FakeNetworkSessionClient(
      quickplayMatch: _match(state: 'open'),
      leaveError: StateError('leave could not be delivered'),
    );
    final live = _ControlledLiveEvents(
      onClose: () => client.sessionActions.add('close'),
    );
    final harness = _ControllerHarness(client: client, liveEvents: live);
    addTearDown(harness.controller.dispose);

    await harness.controller.startQuickplayQueue();
    await _flushMicrotasks();
    final signedOut = await harness.controller.signOut();

    expect(signedOut, isTrue);
    expect(client.sessionActions, ['leave', 'close', 'signOut']);
    expect(harness.session, isNull);
  });

  test(
    'cancelled authentication does not enter a phantom quickplay queue',
    () async {
      final client = _FakeNetworkSessionClient(
        quickplayMatch: _match(state: 'open'),
      );
      final store = _MemoryNetworkSessionStore(displayName: 'Alice');
      NetworkSession? currentSession;
      final presentedErrors = <String>[];
      final controller = LobbyConnectionController(
        mapName: 'verdantia',
        mapSource: MapSource.asset,
        sessionClient: client,
        sessionStore: store,
        sessionEffectRunner: lobbyControllerSessionEffectRunner(store),
        liveEvents: _emptyLiveEvents(),
        now: () => DateTime.utc(2026, 6, 2, 12),
        canContinue: () => true,
        currentSession: () => currentSession,
        setSession: (session) => currentSession = session,
        authenticate: ({required initialDisplayName}) async => null,
        displayName: () => 'Alice',
        setPrimaryDisplayName: (_) {},
        country: () => PlayerCountry.china,
        validateMap: () async => _validValidation(),
        mapNotReadyMessage: () => 'Map is not ready',
        inviteCodeRequiredMessage: () => 'Invite code required',
        errorTextFor: (error) => 'mapped $error',
        presentError: presentedErrors.add,
        publishMatch: (_) {},
        navigateTo: (_) {},
      );
      addTearDown(controller.dispose);

      await controller.startQuickplayQueue();

      expect(controller.mode, LobbyMultiplayerMode.home);
      expect(controller.activeMatch, isNull);
      expect(controller.busy, isFalse);
      expect(client.quickplayRequest, isNull);
      expect(presentedErrors, isEmpty);
    },
  );
}

Future<void> _runTerminalLobbyScenario(_TerminalLobbyScenario scenario) async {
  final live = _ControlledLiveEvents();
  final client = _FakeNetworkSessionClient(
    quickplayMatch: _match(state: 'open'),
    joinedPublicMatch: _match(
      id: 'public_joined',
      state: 'open',
      quickplay: false,
    ),
    createdPrivateMatch: _match(
      id: 'private_hosted',
      state: 'open',
      quickplay: false,
    ),
    joinedPrivateMatch: _match(
      id: 'private_joined',
      state: 'open',
      quickplay: false,
    ),
  );
  final harness = _ControllerHarness(client: client, liveEvents: live);
  addTearDown(harness.controller.dispose);
  await scenario.enter(harness);
  await _flushMicrotasks();
  final active = harness.controller.activeMatch;
  expect(active, isNotNull, reason: scenario.name);
  _emitTerminalLobbySignal(live, scenario.signal, active!);
  await _flushMicrotasks();

  expect(harness.controller.mode, scenario.expectedMode, reason: scenario.name);
  expect(harness.controller.activeMatch, isNull, reason: scenario.name);
  expect(harness.session?.matchId, isNull, reason: scenario.name);
  expect(harness.invalidatedMatchIds, [active.id], reason: scenario.name);
  expect(harness.unavailablePresentations, 1, reason: scenario.name);
  expect(harness.presentedErrors, isEmpty, reason: scenario.name);
  live.emitError(const MultiplayerFailure.multiplayer(code: 'match_abandoned'));
  await _flushMicrotasks();
  expect(harness.unavailablePresentations, 1, reason: scenario.name);
}

void _emitTerminalLobbySignal(
  _ControlledLiveEvents live,
  _TerminalLobbySignal signal,
  WireMatch active,
) {
  switch (signal) {
    case _TerminalLobbySignal.membershipError:
      live.emitError(
        const MultiplayerFailure.multiplayer(code: 'match_not_found'),
      );
    case _TerminalLobbySignal.abandonedMatch:
      live.emitMatch(
        _match(
          id: active.id,
          state: 'abandoned',
          quickplay: active.quickplay,
          ownerUserId: active.ownerUserId,
          players: active.players,
        ),
      );
    case _TerminalLobbySignal.missingUser:
      live.emitMatch(
        _match(
          id: active.id,
          state: 'open',
          quickplay: active.quickplay,
          ownerUserId: 'user_2',
          players: const [
            WirePlayer(
              id: 'player_2',
              userId: 'user_2',
              name: 'Bob',
              colorValue: 0xFFDC2626,
              kind: WirePlayerKind.human,
              connectionState: WirePlayerConnectionState.connected,
            ),
          ],
        ),
      );
  }
}

enum _TerminalLobbySignal { membershipError, abandonedMatch, missingUser }

final class _TerminalLobbyScenario {
  const _TerminalLobbyScenario({
    required this.name,
    required this.enter,
    required this.signal,
    required this.expectedMode,
  });

  final String name;
  final Future<void> Function(_ControllerHarness harness) enter;
  final _TerminalLobbySignal signal;
  final LobbyMultiplayerMode expectedMode;
}

final class _ControllerHarness {
  _ControllerHarness({required this.client, LiveMultiplayerEvents? liveEvents})
    : store = _MemoryNetworkSessionStore(displayName: 'Alice'),
      liveEvents = liveEvents ?? _emptyLiveEvents(),
      session = NetworkSession(
        userId: 'user_1',
        token: AuthToken('token'),
        refreshToken: 'refresh-token',
        connectionState: const NetworkConnectionState(
          status: NetworkConnectionStatus.connected,
        ),
      ) {
    controller = LobbyConnectionController(
      mapName: 'verdantia',
      mapSource: MapSource.asset,
      sessionClient: client,
      sessionStore: store,
      sessionEffectRunner: lobbyControllerSessionEffectRunner(store),
      liveEvents: this.liveEvents,
      now: () => DateTime.utc(2026, 6, 2, 12),
      canContinue: () => true,
      currentSession: () => session,
      setSession: (value) => session = value,
      authenticate: ({required initialDisplayName}) async => null,
      displayName: () => 'Alice',
      setPrimaryDisplayName: (_) {},
      country: () => PlayerCountry.china,
      validateMap: () async => _validValidation(),
      mapNotReadyMessage: () => 'Map is not ready',
      inviteCodeRequiredMessage: () => 'Invite code required',
      errorTextFor: (error) => 'mapped $error',
      presentError: presentedErrors.add,
      publishMatch: (_) {},
      invalidatePublishedMatch: invalidatedMatchIds.add,
      presentLobbyUnavailable: () => unavailablePresentations += 1,
      navigateTo: (_) {},
    );
  }

  final _FakeNetworkSessionClient client;
  final _MemoryNetworkSessionStore store;
  final LiveMultiplayerEvents liveEvents;
  final invalidatedMatchIds = <String>[];
  final presentedErrors = <String>[];
  late final LobbyConnectionController controller;
  NetworkSession? session;
  var unavailablePresentations = 0;
}

final class _ControlledLiveEvents implements LiveMultiplayerEvents {
  _ControlledLiveEvents({this.onClose});

  final void Function()? onClose;
  void Function(WireMatch match)? _onMatch;
  void Function(Object error, StackTrace stackTrace)? _onError;

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
    _onMatch = onMatch;
    _onError = onError;
    onConnected?.call();
    return _ControlledLiveEventHandle(onClose);
  }

  void emitMatch(WireMatch match) {
    final callback = _onMatch;
    if (callback == null) fail('No active lobby subscription.');
    callback(match);
  }

  void emitError(Object error) {
    final callback = _onError;
    if (callback == null) fail('No active lobby subscription.');
    callback(error, StackTrace.empty);
  }
}

final class _ControlledLiveEventHandle implements LiveMultiplayerEventHandle {
  _ControlledLiveEventHandle(this.onClose);

  final void Function()? onClose;
  var closed = false;

  @override
  Future<void> close() async {
    if (closed) return;
    closed = true;
    onClose?.call();
  }

  @override
  Future<WireCommandAck> sendCommand({
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    fail('Lobby subscriptions do not send commands.');
  }
}

Future<void> _flushMicrotasks() async {
  for (var i = 0; i < 5; i += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}
