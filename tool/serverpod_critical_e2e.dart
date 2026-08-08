import 'dart:async';
import 'dart:io';

import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;

import 'src/serverpod_critical_e2e_support.dart';

part 'src/serverpod_critical_e2e_lobby.dart';

Future<void> main(List<String> args) async {
  late final CriticalE2eConfig config;
  try {
    config = CriticalE2eConfig.fromArgs(args);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(CriticalE2eConfig.usage);
    exitCode = 64;
    return;
  }

  try {
    await _CriticalE2e(config).run();
  } on TimeoutException catch (error) {
    stderr.writeln('Critical Serverpod E2E timed out: ${error.message}');
    exitCode = 1;
  } catch (error, stackTrace) {
    stderr
      ..writeln('Critical Serverpod E2E failed: $error')
      ..writeln(stackTrace);
    exitCode = 1;
  }
}

final class _CriticalE2e {
  _CriticalE2e(this.config);

  final CriticalE2eConfig config;
  final List<sp.Client> _clients = [];
  final List<CriticalMatchStream> _streams = [];

  Future<void> run() async {
    final host = _normalizeHost(config.host);
    final loopbackProof = await _verifyLoopbackOnly(Uri.parse(host));
    final runId = DateTime.now().toUtc().microsecondsSinceEpoch;
    final displayNameSuffix = (runId % 1000000).toString().padLeft(6, '0');
    final password = 'AonwCritical-$runId-password';
    final ownerEmail = 'critical-owner-$runId@example.test';
    final guestEmail = 'critical-guest-$runId@example.test';
    final publicClient = _client(host);

    try {
      final registeredOwnerId = (await _request(
        publicClient.emailIdp.createAccount(
          email: ownerEmail,
          password: password,
          displayName: 'Critical Owner $displayNameSuffix',
        ),
      )).authUserId;
      final registeredGuestId = (await _request(
        publicClient.emailIdp.createAccount(
          email: guestEmail,
          password: password,
          displayName: 'Critical Guest $displayNameSuffix',
        ),
      )).authUserId;

      final ownerLogin = await _request(
        publicClient.emailIdp.login(email: ownerEmail, password: password),
      );
      final guestLogin = await _request(
        publicClient.emailIdp.login(email: guestEmail, password: password),
      );
      _expect(
        ownerLogin.authUserId == registeredOwnerId &&
            guestLogin.authUserId == registeredGuestId,
        'Email login must return the accounts created at the public boundary.',
      );
      _requireRefreshToken(ownerLogin, 'owner login');
      _requireRefreshToken(guestLogin, 'guest login');

      final ownerClient = _authenticatedClient(host, ownerLogin);
      final guestClient = _authenticatedClient(host, guestLogin);
      final liveMatch = await _createAndStartLiveMatch(
        ownerClient: ownerClient,
        guestClient: guestClient,
        runId: runId,
      );
      final started = liveMatch.started;

      final ownerPlayer = started.players.singleWhere(
        (player) => player.userId == '${ownerLogin.authUserId}',
      );
      final guestPlayer = started.players.singleWhere(
        (player) => player.id != ownerPlayer.id,
      );

      final guestBefore = await _open(guestClient, started.id, 0);
      final guestBaseline = guestBefore.initialMessage;
      _expectInitialSnapshot(
        guestBaseline,
        matchId: started.id,
        offset: 0,
        context: 'guest baseline',
      );

      final ownerStream = await _open(ownerClient, started.id, 0);
      _expectInitialSnapshot(
        ownerStream.initialMessage,
        matchId: started.id,
        offset: 0,
        context: 'owner command stream',
      );
      await liveMatch.ownerLobbyStream.close();
      await liveMatch.guestLobbyStream.close();
      final retry = _submitTurnMessage(
        matchId: started.id,
        playerId: ownerPlayer.id,
        clientMessageId: 'owner-submit-$runId',
        offset: 0,
        tick: 1,
        turn: started.turn,
      );
      ownerStream
        ..send(retry)
        ..send(retry);
      final firstAck = (await ownerStream.nextAck()).ack!;
      final retryAck = (await ownerStream.nextAck()).ack!;
      _expect(
        firstAck.accepted &&
            retryAck.accepted &&
            firstAck.offset == 1 &&
            retryAck.offset == firstAck.offset &&
            firstAck.snapshot.offset == firstAck.offset &&
            retryAck.snapshot.offset == firstAck.offset,
        'A retried clientMessageId must reuse the accepted offset 1.',
      );
      await ownerStream.close();
      await guestBefore.close();

      final ownerEventsAfterRetry = await _request(
        ownerClient.multiplayer.listEvents(started.id, 0),
      );
      _expect(
        ownerEventsAfterRetry.length == 1 &&
            ownerEventsAfterRetry.single.offset == 1,
        'The idempotent retry must persist exactly one event at offset 1.',
      );
      final snapshotAfterRetry = await _request(
        ownerClient.multiplayer.loadSnapshot(started.id),
      );
      final turnAfterOwnerSubmit = GameSave.fromJson(
        snapshotAfterRetry.save,
      ).turn;
      _expect(
        snapshotAfterRetry.offset == 1 && turnAfterOwnerSubmit == started.turn,
        'The persisted snapshot must stay at turn ${started.turn} after only '
        'the owner submits; got offset ${snapshotAfterRetry.offset}, turn '
        '$turnAfterOwnerSubmit.',
      );

      final rotatedGuest = await _rotate(
        publicClient,
        guestLogin,
        context: 'guest',
      );
      final resumedGuestClient = _authenticatedClient(host, rotatedGuest);
      final guestReconnect = await _open(
        resumedGuestClient,
        started.id,
        guestBaseline.offset,
      );
      _expectInitialSnapshot(
        guestReconnect.initialMessage,
        matchId: started.id,
        offset: 1,
        context: 'refreshed guest reconnect',
      );

      guestReconnect.send(
        _submitTurnMessage(
          matchId: started.id,
          playerId: guestPlayer.id,
          clientMessageId: 'guest-submit-$runId',
          offset: 1,
          tick: 2,
          turn: started.turn,
        ),
      );
      final guestAck = (await guestReconnect.nextAck()).ack!;
      _expect(
        guestAck.accepted &&
            guestAck.offset == 2 &&
            guestAck.snapshot.offset == 2 &&
            GameSave.fromJson(guestAck.snapshot.save).turn == 2,
        'The refreshed guest client must complete turn 1 at offset 2.',
      );
      await guestReconnect.close();

      final persistedEvents = await _request(
        ownerClient.multiplayer.listEvents(started.id, 0),
      );
      final persistedSnapshot = await _request(
        ownerClient.multiplayer.loadSnapshot(started.id),
      );
      final reloadedMatch = await _request(
        ownerClient.multiplayer.loadMatch(started.id),
      );
      _expect(
        persistedEvents.length == 2 &&
            persistedEvents[0].offset == 1 &&
            persistedEvents[1].offset == 2 &&
            persistedSnapshot.offset == 2 &&
            GameSave.fromJson(persistedSnapshot.save).turn == 2 &&
            reloadedMatch.turn == 2,
        'Expected two persisted commands and the authoritative turn-2 '
        'snapshot.',
      );

      final rotatedOwner = await _rotate(
        publicClient,
        ownerLogin,
        context: 'owner',
      );
      final resumedOwnerClient = _authenticatedClient(host, rotatedOwner);
      final ownerReconnect = await _open(resumedOwnerClient, started.id, 1);
      _expectInitialSnapshot(
        ownerReconnect.initialMessage,
        matchId: started.id,
        offset: 2,
        context: 'refreshed owner reconnect',
      );
      _expect(
        GameSave.fromJson(ownerReconnect.initialMessage.snapshot!.save).turn ==
            2,
        'The owner reconnect must receive the persisted turn-2 state.',
      );
      await ownerReconnect.close();

      stdout
        ..writeln('Critical Serverpod E2E passed.')
        ..writeln('  match: ${started.id}')
        ..writeln('  owner: ${ownerLogin.authUserId}')
        ..writeln('  guest: ${guestLogin.authUserId}')
        ..writeln('  idempotent offset: ${retryAck.offset}')
        ..writeln('  reconnect offset: ${ownerReconnect.initialMessage.offset}')
        ..writeln('  final turn: ${reloadedMatch.turn}')
        ..writeln('  listener isolation: $loopbackProof');
    } catch (_) {
      await _closeCriticalE2eResources(
        streams: _streams.reversed,
        clients: _clients.reversed,
        suppressErrors: true,
      );
      rethrow;
    }
    await _closeCriticalE2eResources(
      streams: _streams.reversed,
      clients: _clients.reversed,
      suppressErrors: false,
    );
  }

  sp.Client _client(String host) {
    final client = sp.Client(host, connectionTimeout: config.requestTimeout);
    _clients.add(client);
    return client;
  }

  sp.Client _authenticatedClient(String host, sp_auth.AuthSuccess auth) {
    final client = createServerpodClient(
      host,
      token: AuthToken(auth.token, expiresAt: auth.tokenExpiresAt),
      connectionTimeout: config.requestTimeout,
    );
    _clients.add(client);
    return client;
  }

  Future<CriticalMatchStream> _open(
    sp.Client client,
    String matchId,
    int afterOffset,
  ) async {
    final stream = await CriticalMatchStream.open(
      client: client,
      matchId: matchId,
      afterOffset: afterOffset,
      timeout: config.streamTimeout,
    );
    _streams.add(stream);
    return stream;
  }

  Future<sp_auth.AuthSuccess> _rotate(
    sp.Client publicClient,
    sp_auth.AuthSuccess current, {
    required String context,
  }) async {
    final previousRefreshToken = _requireRefreshToken(current, context);
    final rotated = await _request(
      publicClient.jwtRefresh.refreshAccessToken(
        refreshToken: previousRefreshToken,
      ),
    );
    _expect(
      rotated.authUserId == current.authUserId &&
          _requireRefreshToken(rotated, '$context refresh') !=
              previousRefreshToken,
      'The $context refresh token must rotate for the same account.',
    );
    return rotated;
  }

  Future<T> _request<T>(Future<T> request) =>
      request.timeout(config.requestTimeout);

  static String _requireRefreshToken(sp_auth.AuthSuccess auth, String context) {
    final token = auth.refreshToken;
    if (token == null || token.isEmpty) {
      throw StateError('Expected a refresh token for $context.');
    }
    return token;
  }

  static sp.MultiplayerClientMessage _submitTurnMessage({
    required String matchId,
    required String playerId,
    required String clientMessageId,
    required int offset,
    required int tick,
    required int turn,
  }) => sp.MultiplayerClientMessage(
    clientMessageId: clientMessageId,
    lastSeenOffset: offset,
    requestSnapshot: false,
    command: WireCommand(
      matchId: matchId,
      tick: tick,
      turn: turn,
      actorPlayerId: playerId,
      command: DomainCommandCodec.toJson(SubmitTurnCommand(playerId)),
    ),
  );
}

Future<void> _closeCriticalE2eResources({
  required Iterable<CriticalMatchStream> streams,
  required Iterable<sp.Client> clients,
  required bool suppressErrors,
}) async {
  Object? firstError;
  StackTrace? firstStackTrace;

  void remember(Object error, StackTrace stackTrace) {
    firstError ??= error;
    firstStackTrace ??= stackTrace;
  }

  for (final stream in streams) {
    try {
      await stream.close();
    } catch (error, stackTrace) {
      remember(error, stackTrace);
    }
  }
  for (final client in clients) {
    try {
      client.close();
    } catch (error, stackTrace) {
      remember(error, stackTrace);
    }
  }

  if (!suppressErrors && firstError != null) {
    Error.throwWithStackTrace(firstError!, firstStackTrace!);
  }
}

void _expectInitialSnapshot(
  sp.MultiplayerServerMessage message, {
  required String matchId,
  required int offset,
  required String context,
}) {
  _expect(
    message.matchId == matchId &&
        message.offset == offset &&
        message.snapshot?.matchId == matchId &&
        message.snapshot?.offset == offset &&
        message.event == null &&
        message.ack == null,
    'Expected $context to start with only snapshot $offset for $matchId.',
  );
}

String _normalizeHost(String host) => host.endsWith('/') ? host : '$host/';

Future<String> _verifyLoopbackOnly(Uri host) async {
  if (host.scheme != 'http' ||
      host.host != InternetAddress.loopbackIPv4.address ||
      host.userInfo.isNotEmpty ||
      host.path != '/' ||
      host.hasQuery ||
      host.hasFragment) {
    throw StateError(
      'The critical E2E host must be an HTTP IPv4-loopback origin; got $host.',
    );
  }

  final interfaces = await NetworkInterface.list(
    includeLoopback: false,
    type: InternetAddressType.IPv4,
  );
  final addresses = <InternetAddress>{
    for (final interface in interfaces)
      for (final address in interface.addresses)
        if (!address.isLoopback) address,
  }.toList()..sort((left, right) => left.address.compareTo(right.address));
  if (addresses.isEmpty) {
    return 'runtime probe skipped (no non-loopback IPv4 interface)';
  }

  for (final address in addresses) {
    for (final port in [host.port, host.port + 1, host.port + 2]) {
      final socket = await _tryConnect(address, port);
      if (socket == null) continue;
      socket.destroy();
      throw StateError(
        'Critical E2E listener $port is reachable through non-loopback '
        '${address.address}.',
      );
    }
  }
  return 'verified across ${addresses.length} non-loopback IPv4 '
      '${addresses.length == 1 ? 'address' : 'addresses'}';
}

Future<Socket?> _tryConnect(InternetAddress address, int port) async {
  try {
    return await Socket.connect(
      address,
      port,
      timeout: const Duration(seconds: 2),
    );
  } on SocketException {
    return null;
  } on TimeoutException {
    return null;
  }
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
