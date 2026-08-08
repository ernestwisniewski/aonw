part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubConnectionRegistryScenarios() {
  test(
    'does not apply a late disconnect after a newer connection registers',
    () async {
      final disconnectObserved = Completer<void>();
      final fixture = await _startRunningMatch(
        'registry-late-disconnect',
        operationalEvents: ServerpodOperationalEventSink.withWriter((
          message, {
          required level,
          stackTrace,
        }) {
          if (message.contains('event=multiplayer_stream_disconnected') &&
              !disconnectObserved.isCompleted) {
            disconnectObserved.complete();
          }
        }),
      );
      final state = (await fixture.store.findState(fixture.match.id))!;
      final secondAuthorizationStarted = Completer<void>();
      final allowSecondAuthorization = Completer<void>();
      final harness = _RegistryPresenceHarness(
        store: fixture.store,
        state: state,
        authorize: (attempt) async {
          if (attempt == 2) {
            secondAuthorizationStarted.complete();
            await allowSecondAuthorization.future;
          }
          return _registryAuthorization(state);
        },
      );
      final first = await _openRegistryConnection(harness);
      final secondInput = StreamController<MultiplayerClientMessage>();
      final secondInitial = Completer<void>();
      final secondSubscription = harness.connect(secondInput.stream).listen((
        message,
      ) {
        if (!secondInitial.isCompleted) secondInitial.complete();
      });
      await secondAuthorizationStarted.future.timeout(
        const Duration(seconds: 1),
      );

      final lateDisconnect = first.subscription.cancel();
      await disconnectObserved.future.timeout(const Duration(seconds: 1));
      allowSecondAuthorization.complete();
      await secondInitial.future.timeout(const Duration(seconds: 1));
      await lateDisconnect.timeout(const Duration(seconds: 1));

      expect(harness.connectedGenerations, ['generation-1', 'generation-2']);
      expect(harness.disconnectedGenerations, isEmpty);

      await secondSubscription.cancel();
      expect(harness.disconnectedGenerations, ['generation-2']);
      await first.input.close();
      await secondInput.close();
    },
  );

  test('uses the newest generation for an older surviving stream', () async {
    final fixture = await _startRunningMatch('registry-two-streams');
    final state = (await fixture.store.findState(fixture.match.id))!;
    final heartbeatHandled = Completer<void>();
    final harness = _RegistryPresenceHarness(
      store: fixture.store,
      state: state,
      onMessageHandled: (message) {
        if (message.clientMessageId == 'heartbeat-after-newer-closed' &&
            !heartbeatHandled.isCompleted) {
          heartbeatHandled.complete();
        }
      },
    );
    final older = await _openRegistryConnection(harness);
    final newer = await _openRegistryConnection(harness);

    await newer.subscription.cancel();
    expect(harness.disconnectedGenerations, isEmpty);

    older.input.add(
      MultiplayerClientMessage(
        clientMessageId: 'heartbeat-after-newer-closed',
        lastSeenOffset: 0,
        requestSnapshot: false,
      ),
    );
    await heartbeatHandled.future.timeout(const Duration(seconds: 1));

    expect(harness.renewedGenerations, ['generation-2']);
    expect(harness.callbackOrder, [
      'renew:generation-2',
      'handle:heartbeat-after-newer-closed',
    ]);

    await older.subscription.cancel();
    expect(harness.disconnectedGenerations, ['generation-2']);
    await older.input.close();
    await newer.input.close();
  });

  test('cancelling during authorization does not leak a connection', () async {
    final fixture = await _startRunningMatch('registry-cancel-authorize');
    final state = (await fixture.store.findState(fixture.match.id))!;
    final firstAuthorizationStarted = Completer<void>();
    final allowFirstAuthorization = Completer<void>();
    final harness = _RegistryPresenceHarness(
      store: fixture.store,
      state: state,
      authorize: (attempt) async {
        if (attempt == 1) {
          firstAuthorizationStarted.complete();
          await allowFirstAuthorization.future;
        }
        return _registryAuthorization(state);
      },
    );
    final cancelledInput =
        StreamController<MultiplayerClientMessage>.broadcast();
    final cancelledSubscription = harness
        .connect(cancelledInput.stream)
        .listen((_) {});
    await firstAuthorizationStarted.future.timeout(const Duration(seconds: 1));

    await cancelledSubscription.cancel();
    allowFirstAuthorization.complete();
    final valid = await _openRegistryConnection(harness);

    expect(harness.connectedGenerations, ['generation-2']);
    expect(harness.disconnectedGenerations, isEmpty);

    await valid.subscription.cancel();
    expect(harness.disconnectedGenerations, ['generation-2']);
    await cancelledInput.close();
    await valid.input.close();
  });

  test(
    'cancelling during participant connect disconnects the same generation',
    () async {
      final fixture = await _startRunningMatch('registry-cancel-connect');
      final state = (await fixture.store.findState(fixture.match.id))!;
      final participantConnectedStarted = Completer<void>();
      final allowParticipantConnected = Completer<void>();
      final harness = _RegistryPresenceHarness(
        store: fixture.store,
        state: state,
        participantConnectedHook: (connectionGeneration) async {
          if (connectionGeneration != 'generation-1') return;
          participantConnectedStarted.complete();
          await allowParticipantConnected.future;
        },
      );
      final cancelledInput =
          StreamController<MultiplayerClientMessage>.broadcast();
      final cancelledSubscription = harness
          .connect(cancelledInput.stream)
          .listen((_) {});
      await participantConnectedStarted.future.timeout(
        const Duration(seconds: 1),
      );

      final cancellation = cancelledSubscription.cancel();
      allowParticipantConnected.complete();
      await cancellation.timeout(const Duration(seconds: 1));

      expect(harness.connectedGenerations, ['generation-1']);
      expect(harness.disconnectedGenerations, ['generation-1']);

      final valid = await _openRegistryConnection(harness);
      await valid.subscription.cancel();
      expect(harness.connectedGenerations, ['generation-1', 'generation-2']);
      expect(harness.disconnectedGenerations, ['generation-1', 'generation-2']);

      await cancelledInput.close();
      await valid.input.close();
    },
  );

  test('closes the stream when presence renewal rejects the player', () async {
    final fixture = await _startRunningMatch('registry-renew-rejected');
    final state = (await fixture.store.findState(fixture.match.id))!;
    final harness = _RegistryPresenceHarness(
      store: fixture.store,
      state: state,
      renewPresenceHook: (_) async {
        throw multiplayerException(
          'not_match_player',
          'Player presence can no longer be renewed.',
        );
      },
    );
    final input = StreamController<MultiplayerClientMessage>();
    final initial = Completer<void>();
    final error = Completer<Object>();
    final done = Completer<void>();
    final subscription = harness
        .connect(input.stream)
        .listen(
          (_) {
            if (!initial.isCompleted) initial.complete();
          },
          onError: (Object value) {
            if (!error.isCompleted) error.complete(value);
          },
          onDone: done.complete,
        );
    await initial.future.timeout(const Duration(seconds: 1));

    input.add(
      MultiplayerClientMessage(
        clientMessageId: 'heartbeat-renew-rejected',
        lastSeenOffset: 0,
        requestSnapshot: false,
      ),
    );

    expect(
      await error.future.timeout(const Duration(seconds: 1)),
      _multiplayerError('not_match_player'),
    );
    await done.future.timeout(const Duration(seconds: 1));
    expect(harness.callbackOrder, ['renew:generation-1']);
    expect(harness.disconnectedGenerations, ['generation-1']);

    await subscription.cancel();
    await input.close();
  });
}

typedef _RegistryAuthorizer =
    Future<MatchConnectionAuthorization> Function(int attempt);

final class _RegistryPresenceHarness {
  _RegistryPresenceHarness({
    required this.store,
    required this.state,
    this.authorize,
    this.participantConnectedHook,
    this.renewPresenceHook,
    this.onMessageHandled,
  }) {
    registry = MatchConnectionRegistry(
      connectionGenerationGenerator: () {
        _generation += 1;
        return 'generation-$_generation';
      },
    );
    broadcaster = MatchBroadcaster(registry);
  }

  final MultiplayerMatchStore store;
  final StoredMatchState state;
  final _RegistryAuthorizer? authorize;
  final Future<void> Function(String connectionGeneration)?
  participantConnectedHook;
  final Future<void> Function(String connectionGeneration)? renewPresenceHook;
  final void Function(MultiplayerClientMessage message)? onMessageHandled;

  late final MatchConnectionRegistry registry;
  late final MatchBroadcaster broadcaster;
  final List<String> connectedGenerations = [];
  final List<String> disconnectedGenerations = [];
  final List<String> renewedGenerations = [];
  final List<String> callbackOrder = [];
  var _generation = 0;
  var _authorizationAttempt = 0;

  Stream<MultiplayerServerMessage> connect(
    Stream<MultiplayerClientMessage> input,
  ) {
    final participant = state.match.players.first;
    return registry.connect(
      store: store,
      userIdentifier: participant.userId,
      matchId: state.match.id,
      afterOffset: 0,
      input: input,
      authorize:
          ({
            required MultiplayerMatchStore store,
            required String matchId,
            required String userIdentifier,
          }) {
            _authorizationAttempt += 1;
            return authorize?.call(_authorizationAttempt) ??
                Future.value(_registryAuthorization(state));
          },
      participantConnected:
          ({
            required MultiplayerMatchStore store,
            required String matchId,
            required String userIdentifier,
            required String connectionGeneration,
          }) async {
            connectedGenerations.add(connectionGeneration);
            final hook = participantConnectedHook;
            if (hook != null) await hook(connectionGeneration);
            return state;
          },
      participantDisconnected:
          ({
            required MultiplayerMatchStore store,
            required String matchId,
            required String userIdentifier,
            required String connectionGeneration,
          }) async {
            disconnectedGenerations.add(connectionGeneration);
          },
      renewPresence:
          ({
            required MultiplayerMatchStore store,
            required String matchId,
            required String userIdentifier,
            required String connectionGeneration,
          }) async {
            renewedGenerations.add(connectionGeneration);
            callbackOrder.add('renew:$connectionGeneration');
            final hook = renewPresenceHook;
            if (hook != null) await hook(connectionGeneration);
          },
      handleClientMessage:
          ({
            required MultiplayerMatchStore store,
            required String matchId,
            required String userIdentifier,
            required MultiplayerClientMessage message,
            required MatchMessageTarget caller,
          }) async {
            callbackOrder.add('handle:${message.clientMessageId}');
            onMessageHandled?.call(message);
          },
      createMessage: broadcaster.message,
    );
  }
}

final class _OpenRegistryConnection {
  const _OpenRegistryConnection({
    required this.input,
    required this.subscription,
  });

  final StreamController<MultiplayerClientMessage> input;
  final StreamSubscription<MultiplayerServerMessage> subscription;
}

Future<_OpenRegistryConnection> _openRegistryConnection(
  _RegistryPresenceHarness harness,
) async {
  final input = StreamController<MultiplayerClientMessage>();
  final initial = Completer<void>();
  final subscription = harness.connect(input.stream).listen((_) {
    if (!initial.isCompleted) initial.complete();
  });
  await initial.future.timeout(const Duration(seconds: 1));
  return _OpenRegistryConnection(input: input, subscription: subscription);
}

MatchConnectionAuthorization _registryAuthorization(StoredMatchState state) {
  return MatchConnectionAuthorization(
    state: state,
    participant: state.match.players.first,
  );
}
