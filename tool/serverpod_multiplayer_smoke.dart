import 'dart:async';
import 'dart:io';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;

Future<void> main(List<String> args) async {
  final config = _SmokeConfig.fromArgs(args);
  try {
    await _RuntimeSmoke(config).run();
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(_SmokeConfig.usage);
    exitCode = 64;
  } on TimeoutException catch (error) {
    stderr.writeln('Serverpod multiplayer smoke timed out: ${error.message}');
    exitCode = 1;
  } catch (error, stackTrace) {
    stderr
      ..writeln('Serverpod multiplayer smoke failed: $error')
      ..writeln(stackTrace);
    exitCode = 1;
  }
}

class _RuntimeSmoke {
  _RuntimeSmoke(this.config);

  final _SmokeConfig config;

  Future<void> run() async {
    final host = _normalizeHost(config.host);
    final mapData = await _loadMap(config.mapName);
    final seed = DateTime.now().toUtc().microsecondsSinceEpoch;
    final displayNameSuffix = (seed % 100000000).toString().padLeft(8, '0');
    final password = config.password ?? 'AonwSmoke-$seed-password';
    final ownerEmail = '${config.emailPrefix}-owner-$seed@example.test';
    final guestEmail = '${config.emailPrefix}-guest-$seed@example.test';
    final conflictEmail = '${config.emailPrefix}-conflict-$seed@example.test';
    final thirdEmail = '${config.emailPrefix}-third-$seed@example.test';
    final fourthEmail = '${config.emailPrefix}-fourth-$seed@example.test';
    final overflowEmail = '${config.emailPrefix}-overflow-$seed@example.test';

    stdout
      ..writeln('Serverpod multiplayer smoke')
      ..writeln('  host: $host')
      ..writeln('  map: ${config.mapName}');

    final publicClient = sp.Client(host);
    final ownerAuth = await _createAccount(
      publicClient,
      email: ownerEmail,
      password: password,
      displayName: 'Smoke Owner $displayNameSuffix',
    );
    final guestAuth = await _createAccount(
      publicClient,
      email: guestEmail,
      password: password,
      displayName: 'Smoke Guest $displayNameSuffix',
    );
    final conflictAuth = await _createAccount(
      publicClient,
      email: conflictEmail,
      password: password,
      displayName: 'Smoke Conflict $displayNameSuffix',
    );
    final thirdAuth = await _createAccount(
      publicClient,
      email: thirdEmail,
      password: password,
      displayName: 'Smoke Third $displayNameSuffix',
    );
    final fourthAuth = await _createAccount(
      publicClient,
      email: fourthEmail,
      password: password,
      displayName: 'Smoke Fourth $displayNameSuffix',
    );
    final overflowAuth = await _createAccount(
      publicClient,
      email: overflowEmail,
      password: password,
      displayName: 'Smoke Overflow $displayNameSuffix',
    );

    final ownerClient = createServerpodClient(host, token: _token(ownerAuth));
    final guestClient = createServerpodClient(host, token: _token(guestAuth));
    final conflictClient = createServerpodClient(
      host,
      token: _token(conflictAuth),
    );
    final thirdClient = createServerpodClient(host, token: _token(thirdAuth));
    final fourthClient = createServerpodClient(host, token: _token(fourthAuth));
    final overflowClient = createServerpodClient(
      host,
      token: _token(overflowAuth),
    );

    final quickplayWaiting = await _quickplay(
      ownerClient,
      PlayerCountry.russia,
    );
    final quickplayOwner = quickplayWaiting.players.firstWhere(
      (player) => player.userId == '${ownerAuth.authUserId}',
      orElse: () => throw StateError(
        'Quickplay match has no player for owner ${ownerAuth.authUserId}.',
      ),
    );
    _expect(
      quickplayWaiting.quickplay &&
          quickplayWaiting.maxPlayers == 4 &&
          quickplayWaiting.minPlayers == 2 &&
          quickplayWaiting.state == 'open' &&
          quickplayWaiting.autoStartAt == null,
      'Expected server-owned open quickplay lobby with 4/2 seats.',
    );
    _expect(
      quickplayOwner.country == PlayerCountry.russia,
      'Expected quickplay owner country Russia, got '
      '${quickplayOwner.country.name}.',
    );

    final quickplayRequeued = await _quickplay(
      ownerClient,
      PlayerCountry.china,
    );
    _expect(
      quickplayRequeued.id == quickplayWaiting.id &&
          quickplayRequeued.players.single.country == PlayerCountry.china,
      'Expected owner quickplay requeue to update country to China.',
    );

    final quickplayCountdown = await _quickplay(
      guestClient,
      PlayerCountry.france,
    );
    _expect(
      quickplayCountdown.id == quickplayWaiting.id &&
          quickplayCountdown.state == 'open' &&
          quickplayCountdown.autoStartAt != null &&
          quickplayCountdown.players.length == 2,
      'Expected second quickplay player to start countdown.',
    );

    await _expectQuickplayCountryUnavailable(
      conflictClient,
      PlayerCountry.france,
    );

    final quickplayThree = await _quickplay(thirdClient, PlayerCountry.germany);
    _expect(
      quickplayThree.id == quickplayWaiting.id &&
          quickplayThree.state == 'open' &&
          quickplayThree.players.length == 3 &&
          quickplayThree.autoStartAt == quickplayCountdown.autoStartAt,
      'Expected third quickplay player to keep existing countdown.',
    );

    final quickplayStarted = await _quickplay(
      fourthClient,
      PlayerCountry.japan,
    );
    _expect(
      quickplayStarted.id == quickplayWaiting.id &&
          quickplayStarted.state == 'running' &&
          quickplayStarted.players.length == 4 &&
          quickplayStarted.autoStartAt == null,
      'Expected fourth quickplay player to start the match immediately.',
    );

    final quickplayOverflow = await _quickplay(
      overflowClient,
      PlayerCountry.italy,
    );
    _expect(
      quickplayOverflow.id != quickplayStarted.id &&
          quickplayOverflow.state == 'open' &&
          quickplayOverflow.players.single.country == PlayerCountry.italy,
      'Expected overflow quickplay player to create a fresh lobby.',
    );
    await ownerClient.multiplayer
        .leaveMatch(quickplayStarted.id)
        .timeout(config.requestTimeout);
    await overflowClient.multiplayer
        .leaveMatch(quickplayOverflow.id)
        .timeout(config.requestTimeout);

    final created = await ownerClient.multiplayer
        .createMatch(
          sp.CreateMatchRequest(
            name: 'Runtime smoke $seed',
            mapName: config.mapName,
            maxPlayers: 2,
            minPlayers: 2,
            private: false,
          ),
        )
        .timeout(config.requestTimeout);
    await guestClient.multiplayer
        .joinMatch(created.id)
        .timeout(config.requestTimeout);
    final started = await ownerClient.multiplayer
        .startMatch(created.id)
        .timeout(config.requestTimeout);

    const eventCodec = EventCodec();
    const snapshotCodec = SnapshotCodec();
    final guestBeforeInput = StreamController<sp.MultiplayerClientMessage>();
    final guestBefore = await _connectUntilInitialSnapshot(
      guestClient.multiplayer.connect(started.id, 0, guestBeforeInput.stream),
      guestBeforeInput,
    );
    final guestBeforeSnapshot = guestBefore.single.snapshot;
    _expect(
      guestBeforeSnapshot != null && guestBeforeSnapshot.offset == 0,
      'Expected guest initial snapshot at offset 0, got '
      '${guestBeforeSnapshot?.offset}.',
    );

    final ownerPlayer = started.players.firstWhere(
      (player) => player.userId == started.ownerUserId,
      orElse: () => throw StateError(
        'Started match has no player for owner ${started.ownerUserId}.',
      ),
    );
    final ownerInput = StreamController<sp.MultiplayerClientMessage>();
    final ownerInitialMessage = Completer<sp.MultiplayerServerMessage>();
    final ackMessages = <sp.MultiplayerServerMessage>[];
    final firstAckSeen = Completer<sp.MultiplayerServerMessage>();
    final diplomacyAckSeen = Completer<sp.MultiplayerServerMessage>();
    final ackMessagesSeen = Completer<List<sp.MultiplayerServerMessage>>();
    final ownerSubscription = ownerClient.multiplayer
        .connect(started.id, 0, ownerInput.stream)
        .listen(
          (message) {
            if (message.snapshot != null && !ownerInitialMessage.isCompleted) {
              ownerInitialMessage.complete(message);
            }
            if (message.ack != null) {
              ackMessages.add(message);
              if (ackMessages.length == 1 && !firstAckSeen.isCompleted) {
                firstAckSeen.complete(message);
              }
              if (ackMessages.length == 2 && !diplomacyAckSeen.isCompleted) {
                diplomacyAckSeen.complete(message);
              }
              if (ackMessages.length == 4 && !ackMessagesSeen.isCompleted) {
                ackMessagesSeen.complete(List.unmodifiable(ackMessages));
              }
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!ownerInitialMessage.isCompleted) {
              ownerInitialMessage.completeError(error, stackTrace);
            }
            if (!firstAckSeen.isCompleted) {
              firstAckSeen.completeError(error, stackTrace);
            }
            if (!diplomacyAckSeen.isCompleted) {
              diplomacyAckSeen.completeError(error, stackTrace);
            }
            if (!ackMessagesSeen.isCompleted) {
              ackMessagesSeen.completeError(error, stackTrace);
            }
          },
        );
    final ownerInitial = await ownerInitialMessage.future.timeout(
      config.streamTimeout,
    );
    final ownerInitialSnapshot = ownerInitial.snapshot;
    _expect(
      ownerInitialSnapshot != null && ownerInitialSnapshot.offset == 0,
      'Expected owner initial snapshot at offset 0, got '
      '${ownerInitialSnapshot?.offset}.',
    );

    final initialSnapshot = snapshotCodec.fromWire(ownerInitialSnapshot!);
    final targetPlayer = started.players.firstWhere(
      (player) => player.id != ownerPlayer.id,
      orElse: () => throw StateError(
        'Started match has no opponent for owner player ${ownerPlayer.id}.',
      ),
    );
    final move = _movementCommandFor(
      mapData: mapData,
      snapshot: initialSnapshot,
      actorPlayerId: ownerPlayer.id,
    );
    ownerInput.add(
      sp.MultiplayerClientMessage(
        clientMessageId: 'move-unit-$seed',
        lastSeenOffset: ownerInitial.offset,
        requestSnapshot: false,
        command: WireCommand(
          matchId: started.id,
          tick: 1,
          turn: started.turn,
          actorPlayerId: ownerPlayer.id,
          command: GameCommandSerializer.toJson(move.command),
        ),
      ),
    );

    final moveAckMessage = await firstAckSeen.future.timeout(
      config.streamTimeout,
    );
    final moveAck = moveAckMessage.ack;
    _expect(moveAck != null, 'Expected movement command ACK.');
    _expect(moveAck!.accepted, 'Expected movement command to be accepted.');
    _expect(
      moveAck.offset == 1,
      'Expected movement ACK offset 1, got ${moveAck.offset}.',
    );
    _expect(
      moveAck.snapshot.offset == moveAck.offset,
      'Expected movement ACK snapshot offset ${moveAck.offset}, got '
      '${moveAck.snapshot.offset}.',
    );
    final moveEvents = eventCodec.eventsFromJsonList(moveAck.events);
    _expect(
      moveEvents.whereType<UnitMovedEvent>().any(
        (event) =>
            event.unitId == move.command.unitId &&
            event.fromCol == move.fromCol &&
            event.fromRow == move.fromRow &&
            event.toCol == move.command.targetCol &&
            event.toRow == move.command.targetRow,
      ),
      'Expected movement ACK to include the committed UnitMovedEvent.',
    );

    final postMoveSnapshot = snapshotCodec.fromWire(moveAck.snapshot);
    final diplomacyCommand = SendDiplomaticMessageCommand(
      playerId: ownerPlayer.id,
      targetPlayerId: targetPlayer.id,
      topic: DiplomaticMessageTopic.peacefulPraise,
      messageId: 'smoke-diplomacy-$seed',
    );
    final expectsDiplomacyAccepted = DiplomaticActionGuard.canTargetDiscovered(
      playerId: diplomacyCommand.playerId,
      targetPlayerId: diplomacyCommand.targetPlayerId,
      knownPlayerIds: started.players.map((player) => player.id),
      diplomacy: postMoveSnapshot.runtimeState.diplomacy,
      fogOfWar: postMoveSnapshot.fogOfWar,
      units: postMoveSnapshot.units,
      cities: postMoveSnapshot.cities,
    );
    ownerInput.add(
      sp.MultiplayerClientMessage(
        clientMessageId: 'send-diplomacy-$seed',
        lastSeenOffset: moveAck.offset,
        requestSnapshot: false,
        command: WireCommand(
          matchId: started.id,
          tick: 2,
          turn: started.turn,
          actorPlayerId: ownerPlayer.id,
          command: GameCommandSerializer.toJson(diplomacyCommand),
        ),
      ),
    );

    final diplomacyAckMessage = await diplomacyAckSeen.future.timeout(
      config.streamTimeout,
    );
    final diplomacyAck = diplomacyAckMessage.ack;
    _expect(diplomacyAck != null, 'Expected diplomacy command ACK.');
    _expect(
      diplomacyAck!.accepted == expectsDiplomacyAccepted,
      'Expected diplomacy ACK accepted=$expectsDiplomacyAccepted, got '
      '${diplomacyAck.accepted} (${diplomacyAck.reason ?? 'no reason'}).',
    );
    final expectedDiplomacyOffset = expectsDiplomacyAccepted
        ? moveAck.offset + 1
        : moveAck.offset;
    _expect(
      diplomacyAck.offset == expectedDiplomacyOffset,
      'Expected diplomacy ACK offset $expectedDiplomacyOffset, got '
      '${diplomacyAck.offset}.',
    );
    _expect(
      diplomacyAck.snapshot.offset == diplomacyAck.offset,
      'Expected diplomacy ACK snapshot offset ${diplomacyAck.offset}, got '
      '${diplomacyAck.snapshot.offset}.',
    );
    final diplomacyEvents = eventCodec.eventsFromJsonList(diplomacyAck.events);
    if (expectsDiplomacyAccepted) {
      _expect(
        diplomacyEvents.whereType<DiplomaticMessageSentEvent>().any(
          (event) =>
              event.messageId == diplomacyCommand.messageId &&
              event.fromPlayerId == diplomacyCommand.playerId &&
              event.toPlayerId == diplomacyCommand.targetPlayerId &&
              event.topic == diplomacyCommand.topic,
        ),
        'Expected diplomacy ACK to include the committed '
        'DiplomaticMessageSentEvent.',
      );
    } else {
      _expect(
        diplomacyAck.reason != null && diplomacyAck.reason!.isNotEmpty,
        'Expected rejected diplomacy ACK to include a reason.',
      );
      _expect(
        diplomacyEvents.isEmpty,
        'Expected rejected diplomacy ACK to include no committed events.',
      );
    }

    final submitTurnMessage = sp.MultiplayerClientMessage(
      clientMessageId: 'submit-turn-$seed',
      lastSeenOffset: diplomacyAck.offset,
      requestSnapshot: false,
      command: WireCommand(
        matchId: started.id,
        tick: 3,
        turn: started.turn,
        actorPlayerId: ownerPlayer.id,
        command: GameCommandSerializer.toJson(
          SubmitTurnCommand(ownerPlayer.id),
        ),
      ),
    );
    ownerInput
      ..add(submitTurnMessage)
      ..add(submitTurnMessage);

    final ownerAckMessages = await ackMessagesSeen.future.timeout(
      config.streamTimeout,
    );
    await ownerInput.close();
    await ownerSubscription.cancel();
    final ack = ownerAckMessages[2].ack;
    final retryAck = ownerAckMessages[3].ack;
    _expect(ack != null, 'Expected command ACK from Serverpod stream.');
    _expect(
      retryAck != null,
      'Expected retry command ACK from Serverpod stream.',
    );
    _expect(ack!.accepted, 'Expected accepted command ACK, got rejection.');
    _expect(
      retryAck!.accepted,
      'Expected accepted retry command ACK, got rejection.',
    );
    final expectedSubmitOffset = diplomacyAck.offset + 1;
    _expect(
      ack.offset == expectedSubmitOffset,
      'Expected command ACK offset $expectedSubmitOffset, got ${ack.offset}.',
    );
    _expect(
      retryAck.offset == ack.offset,
      'Expected retry ACK to reuse offset ${ack.offset}, got ${retryAck.offset}.',
    );
    _expect(
      ack.snapshot.offset == ack.offset,
      'Expected ACK snapshot offset ${ack.offset}, got ${ack.snapshot.offset}.',
    );
    _expect(
      retryAck.snapshot.offset == ack.snapshot.offset,
      'Expected retry ACK snapshot offset ${ack.snapshot.offset}, got '
      '${retryAck.snapshot.offset}.',
    );

    final guestReconnectInput = StreamController<sp.MultiplayerClientMessage>();
    final guestReconnectMessages = await _connectUntilInitialSnapshot(
      guestClient.multiplayer.connect(
        started.id,
        guestBeforeSnapshot!.offset,
        guestReconnectInput.stream,
      ),
      guestReconnectInput,
    );
    _expect(
      guestReconnectMessages.length == 1,
      'Expected reconnect to receive one latest snapshot message, got '
      '${guestReconnectMessages.length}.',
    );
    final reconnect = guestReconnectMessages.single;
    _expect(
      reconnect.snapshot?.offset == ack.offset,
      'Expected reconnect snapshot offset ${ack.offset}, got '
      '${reconnect.snapshot?.offset}.',
    );
    _expect(
      reconnect.event == null && reconnect.ack == null,
      'Expected no duplicate event or ACK replay after latest snapshot.',
    );
    final reconnectSnapshot = reconnect.snapshot;
    _expect(
      reconnectSnapshot != null,
      'Expected reconnect to include the latest authoritative snapshot.',
    );
    final resumedSnapshot = snapshotCodec.fromWire(reconnectSnapshot!);
    final resumedUnit = resumedSnapshot.units.firstWhere(
      (unit) => unit.id == move.command.unitId,
      orElse: () => throw StateError(
        'Reconnect snapshot is missing moved unit ${move.command.unitId}.',
      ),
    );
    _expect(
      resumedUnit.col == move.command.targetCol &&
          resumedUnit.row == move.command.targetRow,
      'Expected reconnect snapshot to contain moved unit at '
      '${move.command.targetCol}:${move.command.targetRow}, got '
      '${resumedUnit.col}:${resumedUnit.row}.',
    );

    final events = await guestClient.multiplayer
        .listEvents(started.id, 0)
        .timeout(config.requestTimeout);
    final expectedEventCount = ack.offset;
    _expect(
      events.length == expectedEventCount,
      'Expected $expectedEventCount persisted events, got ${events.length}.',
    );
    _expect(
      events.first.offset == moveAck.offset && events.last.offset == ack.offset,
      'Expected persisted event offsets ${moveAck.offset}, ${ack.offset}, got '
      '${events.map((event) => event.offset).join(', ')}.',
    );
    _expect(
      eventCodec
          .eventsFromWire(events.first)
          .whereType<UnitMovedEvent>()
          .any((event) => event.unitId == move.command.unitId),
      'Expected first persisted event to describe the movement command.',
    );
    if (expectsDiplomacyAccepted) {
      final diplomacyEvent = events.firstWhere(
        (event) => event.offset == diplomacyAck.offset,
        orElse: () => throw StateError(
          'Expected persisted diplomacy event at offset ${diplomacyAck.offset}.',
        ),
      );
      _expect(
        eventCodec
            .eventsFromWire(diplomacyEvent)
            .whereType<DiplomaticMessageSentEvent>()
            .any((event) => event.messageId == diplomacyCommand.messageId),
        'Expected persisted event to describe the diplomacy command.',
      );
    }

    final guestActiveInput = StreamController<sp.MultiplayerClientMessage>();
    final guestActive = await _openUntilInitialSnapshot(
      guestClient.multiplayer.connect(
        started.id,
        ack.offset,
        guestActiveInput.stream,
      ),
      guestActiveInput,
    );
    try {
      await ownerClient.multiplayer
          .leaveMatch(started.id)
          .timeout(config.requestTimeout);
      final resumedAfterLeave = await ownerClient.multiplayer
          .loadMatch(started.id)
          .timeout(config.requestTimeout);
      _expect(
        resumedAfterLeave.state == 'running' &&
            resumedAfterLeave.id == started.id,
        'Expected owner to resume running match while guest is active, got '
        '${resumedAfterLeave.state}/${resumedAfterLeave.id}.',
      );
    } finally {
      await guestActive.close();
    }

    stdout
      ..writeln('  match: ${started.id}')
      ..writeln('  owner auth user: ${ownerAuth.authUserId}')
      ..writeln('  guest auth user: ${guestAuth.authUserId}')
      ..writeln('  quickplay started: ${quickplayStarted.id}')
      ..writeln('  quickplay overflow lobby: ${quickplayOverflow.id}')
      ..writeln(
        '  moved unit: ${move.command.unitId} '
        '${move.fromCol}:${move.fromRow}->'
        '${move.command.targetCol}:${move.command.targetRow}',
      )
      ..writeln('  movement ack offset: ${moveAck.offset}')
      ..writeln(
        '  diplomacy ack offset: ${diplomacyAck.offset} '
        '(${diplomacyAck.accepted ? 'accepted' : 'rejected: ${diplomacyAck.reason}'})',
      )
      ..writeln('  ack offset: ${ack.offset}')
      ..writeln('  retry ack offset: ${retryAck.offset}')
      ..writeln('  reconnect snapshot offset: ${reconnect.snapshot?.offset}')
      ..writeln('Serverpod multiplayer smoke passed.');
  }

  Future<sp_auth.AuthSuccess> _createAccount(
    sp.Client client, {
    required String email,
    required String password,
    required String displayName,
  }) {
    return client.emailIdp
        .createAccount(
          email: email,
          password: password,
          displayName: displayName,
        )
        .timeout(config.requestTimeout);
  }

  Future<WireMatch> _quickplay(sp.Client client, PlayerCountry country) {
    return client.multiplayer
        .quickplay(
          sp.CreateMatchRequest(
            name: 'Runtime quickplay smoke',
            mapName: config.mapName,
            maxPlayers: 2,
            minPlayers: 1,
            private: true,
            countryId: country.name,
          ),
        )
        .timeout(config.requestTimeout);
  }

  Future<void> _expectQuickplayCountryUnavailable(
    sp.Client client,
    PlayerCountry country,
  ) async {
    try {
      await _quickplay(client, country);
    } on sp.MultiplayerException catch (error) {
      _expect(
        error.code == 'country_unavailable',
        'Expected country_unavailable, got ${error.code}.',
      );
      return;
    }
    throw StateError(
      'Expected quickplay country ${country.name} to be unavailable.',
    );
  }

  Future<List<sp.MultiplayerServerMessage>> _connectUntilInitialSnapshot(
    Stream<sp.MultiplayerServerMessage> stream,
    StreamController<sp.MultiplayerClientMessage> input,
  ) async {
    final messages = <sp.MultiplayerServerMessage>[];
    final snapshotSeen = Completer<void>();
    Object? postSnapshotError;
    StackTrace? postSnapshotStackTrace;
    late final StreamSubscription<sp.MultiplayerServerMessage> subscription;
    subscription = stream.listen(
      (message) {
        messages.add(message);
        if (message.snapshot != null && !snapshotSeen.isCompleted) {
          snapshotSeen.complete();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!snapshotSeen.isCompleted) {
          snapshotSeen.completeError(error, stackTrace);
        }
        postSnapshotError = error;
        postSnapshotStackTrace = stackTrace;
      },
    );

    try {
      await snapshotSeen.future.timeout(config.streamTimeout);
      await Future<void>.delayed(config.backlogFlushDelay);
      final error = postSnapshotError;
      if (error != null) {
        Error.throwWithStackTrace(
          error,
          postSnapshotStackTrace ?? StackTrace.current,
        );
      }
      if (!input.isClosed) await input.close();
      return messages;
    } finally {
      await subscription.cancel();
    }
  }

  Future<_OpenStream> _openUntilInitialSnapshot(
    Stream<sp.MultiplayerServerMessage> stream,
    StreamController<sp.MultiplayerClientMessage> input,
  ) async {
    final snapshotSeen = Completer<void>();
    late final StreamSubscription<sp.MultiplayerServerMessage> subscription;
    subscription = stream.listen(
      (message) {
        if (message.snapshot != null && !snapshotSeen.isCompleted) {
          snapshotSeen.complete();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!snapshotSeen.isCompleted) {
          snapshotSeen.completeError(error, stackTrace);
        }
      },
    );
    await snapshotSeen.future.timeout(config.streamTimeout);
    return _OpenStream(input: input, subscription: subscription);
  }

  static AuthToken _token(sp_auth.AuthSuccess auth) {
    return AuthToken(auth.token, expiresAt: auth.tokenExpiresAt);
  }

  static String _normalizeHost(String host) {
    return host.endsWith('/') ? host : '$host/';
  }

  static Future<MapData> _loadMap(String mapName) async {
    final safeName = _safeMapName(mapName);
    final file = File('assets/maps/$safeName/map.json');
    if (!await file.exists()) {
      throw StateError('Bundled map not found: ${file.path}');
    }
    return MapDataCodec.fromJson(await file.readAsString())
      ..mapName ??= safeName;
  }

  static String _safeMapName(String mapName) {
    final trimmed = mapName.trim();
    if (trimmed.isEmpty || !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
      throw FormatException('Invalid map name: $mapName');
    }
    return trimmed;
  }

  static _SmokeMove _movementCommandFor({
    required MapData mapData,
    required SaveSnapshot snapshot,
    required String actorPlayerId,
  }) {
    final pathfinder = UnitMovementPathfinder(
      mapData: mapData,
      units: snapshot.units,
    );
    final candidates = <_MoveCandidate>[];
    final actorUnits =
        snapshot.units
            .where(
              (unit) =>
                  unit.ownerPlayerId == actorPlayerId &&
                  !unit.isWorking &&
                  unit.type != GameUnitType.merchant &&
                  unit.movementPoints > 0,
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    for (final unit in actorUnits) {
      final reachable = pathfinder.movementCostsFrom(
        unit: unit,
        maxCost: unit.movementPoints,
      );
      for (final entry in reachable.entries) {
        final coords = entry.key;
        final foreignCityCenter = snapshot.cities.any(
          (city) =>
              city.ownerPlayerId != actorPlayerId &&
              city.occupiesCenter(coords.col, coords.row),
        );
        if (foreignCityCenter) continue;
        candidates.add(
          _MoveCandidate(
            unit: unit,
            col: coords.col,
            row: coords.row,
            cost: entry.value,
          ),
        );
      }
    }

    candidates.sort((a, b) {
      final unit = a.unit.id.compareTo(b.unit.id);
      if (unit != 0) return unit;
      final cost = a.cost.compareTo(b.cost);
      if (cost != 0) return cost;
      final col = a.col.compareTo(b.col);
      if (col != 0) return col;
      return a.row.compareTo(b.row);
    });

    if (candidates.isEmpty) {
      throw StateError(
        'No legal runtime-smoke movement candidate for $actorPlayerId.',
      );
    }
    final selected = candidates.first;
    return _SmokeMove(
      command: MoveUnitCommand(selected.unit.id, selected.col, selected.row),
      fromCol: selected.unit.col,
      fromRow: selected.unit.row,
    );
  }

  static void _expect(bool condition, String message) {
    if (!condition) throw StateError(message);
  }
}

class _OpenStream {
  const _OpenStream({required this.input, required this.subscription});

  final StreamController<sp.MultiplayerClientMessage> input;
  final StreamSubscription<sp.MultiplayerServerMessage> subscription;

  Future<void> close() async {
    if (!input.isClosed) await input.close();
    await subscription.cancel();
  }
}

class _SmokeMove {
  const _SmokeMove({
    required this.command,
    required this.fromCol,
    required this.fromRow,
  });

  final MoveUnitCommand command;
  final int fromCol;
  final int fromRow;
}

class _MoveCandidate {
  const _MoveCandidate({
    required this.unit,
    required this.col,
    required this.row,
    required this.cost,
  });

  final GameUnit unit;
  final int col;
  final int row;
  final int cost;
}

class _SmokeConfig {
  const _SmokeConfig({
    required this.host,
    required this.mapName,
    required this.emailPrefix,
    required this.requestTimeout,
    required this.streamTimeout,
    required this.backlogFlushDelay,
    this.password,
  });

  final String host;
  final String mapName;
  final String emailPrefix;
  final String? password;
  final Duration requestTimeout;
  final Duration streamTimeout;
  final Duration backlogFlushDelay;

  static const usage = '''
Usage:
  dart run tool/serverpod_multiplayer_smoke.dart [options]

Options:
  --host URL            Serverpod API host. Default: env AONW_SERVERPOD_SMOKE_HOST or http://127.0.0.1:8080/
  --map NAME           Map name. Default: env AONW_SERVERPOD_SMOKE_MAP or myranth
  --email-prefix TEXT  Email prefix for generated test accounts. Default: env AONW_SERVERPOD_SMOKE_EMAIL_PREFIX or aonw-smoke
  --password TEXT      Password for generated accounts. Default: generated per run
''';

  factory _SmokeConfig.fromArgs(List<String> args) {
    final options = <String, String>{};
    for (var i = 0; i < args.length; i += 1) {
      final arg = args[i];
      if (arg == '--help' || arg == '-h') {
        stdout.write(usage);
        exit(0);
      }
      if (!arg.startsWith('--')) {
        throw FormatException('Unexpected argument: $arg');
      }
      final equals = arg.indexOf('=');
      if (equals != -1) {
        options[arg.substring(2, equals)] = arg.substring(equals + 1);
        continue;
      }
      if (i + 1 >= args.length || args[i + 1].startsWith('--')) {
        throw FormatException('Missing value for $arg');
      }
      options[arg.substring(2)] = args[i + 1];
      i += 1;
    }

    String option(String key, String envKey, String fallback) {
      return options[key] ?? Platform.environment[envKey] ?? fallback;
    }

    return _SmokeConfig(
      host: option(
        'host',
        'AONW_SERVERPOD_SMOKE_HOST',
        'http://127.0.0.1:8080/',
      ),
      mapName: option('map', 'AONW_SERVERPOD_SMOKE_MAP', 'myranth'),
      emailPrefix: option(
        'email-prefix',
        'AONW_SERVERPOD_SMOKE_EMAIL_PREFIX',
        'aonw-smoke',
      ),
      password:
          options['password'] ??
          Platform.environment['AONW_SERVERPOD_SMOKE_PASSWORD'],
      requestTimeout: const Duration(seconds: 10),
      streamTimeout: const Duration(seconds: 5),
      backlogFlushDelay: const Duration(milliseconds: 250),
    );
  }
}
