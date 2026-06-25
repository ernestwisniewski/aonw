import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/game/presentation/screens/lobby_match_action_coordinator.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LobbyMatchActionCoordinator', () {
    test(
      'quickplay remembers, watches and schedules a waiting match',
      () async {
        final harness = _Harness(quickplayMatch: _match(state: 'open'));

        await harness.coordinator.joinQuickplay(_config());

        expect(harness.validationCount, 1);
        expect(harness.quickplayRequest?.mapName, 'verdantia');
        expect(harness.quickplayRequest?.displayName, 'Alice');
        expect(harness.quickplayRequest?.country, PlayerCountry.china);
        expect(harness.remembered.map((entry) => entry.match.id), ['match_1']);
        expect(harness.watched.map((entry) => entry.match.id), ['match_1']);
        expect(harness.scheduled.map((match) => match.id), ['match_1']);
        expect(harness.entered, isEmpty);
      },
    );

    test('quickplay enters a runnable match with enough humans', () async {
      final harness = _Harness(quickplayMatch: _match(state: 'running'));

      await harness.coordinator.joinQuickplay(_config());

      expect(harness.stoppedCount, 1);
      expect(harness.entered.single.match.state, 'running');
      expect(harness.scheduled, isEmpty);
    });

    test('validation errors stop quickplay before network calls', () async {
      final harness = _Harness(validation: _invalidValidation());

      await expectLater(
        harness.coordinator.joinQuickplay(_config()),
        throwsStateError,
      );

      expect(harness.quickplayRequest, isNull);
      expect(harness.remembered, isEmpty);
    });

    test('cancel leaves open quickplay and clears active match', () async {
      final harness = _Harness();

      await harness.coordinator.cancelQuickplay(
        activeMatch: _match(state: 'open'),
      );

      expect(harness.stoppedCount, 1);
      expect(harness.leftMatchIds, ['match_1']);
      expect(harness.clearedSessions, [harness.session]);
    });

    test('private create and join remember and watch matches', () async {
      final harness = _Harness(
        createdPrivateMatch: _match(id: 'private_1'),
        joinedPrivateMatch: _match(id: 'private_2'),
      );

      await harness.coordinator.createPrivate(_config());
      await harness.coordinator.joinPrivate(
        inviteCode: '  ABC123  ',
        inviteCodeRequiredMessage: 'Code required',
        config: _config(),
      );

      expect(harness.createdPrivateRequest?.displayName, 'Alice');
      expect(harness.createdPrivateRequest?.country, PlayerCountry.china);
      expect(harness.joinPrivateRequest?.inviteCode, 'ABC123');
      expect(harness.joinPrivateRequest?.country, PlayerCountry.china);
      expect(harness.remembered.map((entry) => entry.match.id), [
        'private_1',
        'private_2',
      ]);
      expect(harness.watched.map((entry) => entry.match.id), [
        'private_1',
        'private_2',
      ]);
    });

    test('private join requires an invite code', () async {
      final harness = _Harness();

      await expectLater(
        harness.coordinator.joinPrivate(
          inviteCode: ' ',
          inviteCodeRequiredMessage: 'Code required',
          config: _config(),
        ),
        throwsStateError,
      );

      expect(harness.joinPrivateRequest, isNull);
    });

    test('start and refresh route runnable matches', () async {
      final harness = _Harness(
        startedMatch: _match(id: 'private_1', state: 'running'),
        loadedMatch: _match(id: 'match_2', state: 'loading'),
      );

      await harness.coordinator.startPrivate(
        activeMatch: _match(id: 'private_1', state: 'open'),
      );
      await harness.coordinator.refreshActiveMatch(matchId: 'match_2');

      expect(harness.startedMatchIds, ['private_1']);
      expect(harness.loadedMatchIds, ['match_2']);
      expect(harness.entered.map((entry) => entry.match.id), [
        'private_1',
        'match_2',
      ]);
      expect(harness.stoppedCount, 2);
    });
  });
}

LobbyMatchActionConfig _config() {
  return const LobbyMatchActionConfig(
    mapName: 'verdantia',
    displayName: 'Alice',
    country: PlayerCountry.china,
    mapNotReadyMessage: 'Map is not ready',
  );
}

MapValidationResult _validValidation() {
  return MapValidationResult(
    mapName: 'verdantia',
    playerCount: 2,
    totalTiles: 64,
    passableTiles: 64,
    resources: const MapResourceSummary(
      resourceTiles: 0,
      foodResources: 0,
      luxuryResources: 0,
      strategicResources: 0,
    ),
    startSites: const [],
    issues: const [],
  );
}

MapValidationResult _invalidValidation() {
  return MapValidationResult(
    mapName: 'verdantia',
    playerCount: 2,
    totalTiles: 64,
    passableTiles: 64,
    resources: const MapResourceSummary(
      resourceTiles: 0,
      foodResources: 0,
      luxuryResources: 0,
      strategicResources: 0,
    ),
    startSites: const [],
    issues: const [
      MapValidationIssue(
        severity: MapValidationSeverity.error,
        code: 'bad_map',
        message: 'Bad map',
      ),
    ],
  );
}

NetworkSession _session() {
  return NetworkSession(
    userId: 'user_1',
    token: AuthToken('token'),
    connectionState: const NetworkConnectionState(
      status: NetworkConnectionStatus.connected,
    ),
  );
}

WireMatch _match({String id = 'match_1', String state = 'open'}) {
  return WireMatch(
    id: id,
    ownerUserId: 'user_1',
    name: 'Quickplay',
    mapName: 'verdantia',
    players: const [
      WirePlayer(
        id: 'player_1',
        userId: 'user_1',
        name: 'Alice',
        colorValue: 0xFF2563EB,
        kind: WirePlayerKind.human,
        connectionState: WirePlayerConnectionState.connected,
      ),
      WirePlayer(
        id: 'player_2',
        userId: 'user_2',
        name: 'Bob',
        colorValue: 0xFFDC2626,
        kind: WirePlayerKind.human,
        connectionState: WirePlayerConnectionState.connected,
      ),
    ],
    maxPlayers: 4,
    minPlayers: 2,
    turn: 1,
    state: state,
    createdAt: DateTime.utc(2026, 6, 2),
  );
}

final class _Harness {
  final NetworkSession session;
  final MapValidationResult validation;
  final WireMatch quickplayMatch;
  final WireMatch createdPrivateMatch;
  final WireMatch joinedPrivateMatch;
  final WireMatch startedMatch;
  final WireMatch loadedMatch;

  var validationCount = 0;
  var stoppedCount = 0;
  QuickplayMatchRequest? quickplayRequest;
  CreatePrivateMatchRequest? createdPrivateRequest;
  JoinPrivateMatchRequest? joinPrivateRequest;
  final leftMatchIds = <String>[];
  final startedMatchIds = <String>[];
  final loadedMatchIds = <String>[];
  final remembered = <_MatchEntry>[];
  final watched = <_MatchEntry>[];
  final entered = <_MatchEntry>[];
  final scheduled = <WireMatch>[];
  final clearedSessions = <NetworkSession>[];

  _Harness({
    NetworkSession? session,
    MapValidationResult? validation,
    WireMatch? quickplayMatch,
    WireMatch? createdPrivateMatch,
    WireMatch? joinedPrivateMatch,
    WireMatch? startedMatch,
    WireMatch? loadedMatch,
  }) : session = session ?? _session(),
       validation = validation ?? _validValidation(),
       quickplayMatch = quickplayMatch ?? _match(),
       createdPrivateMatch = createdPrivateMatch ?? _match(id: 'private_1'),
       joinedPrivateMatch = joinedPrivateMatch ?? _match(id: 'private_2'),
       startedMatch = startedMatch ?? _match(state: 'running'),
       loadedMatch = loadedMatch ?? _match(state: 'loading');

  LobbyMatchActionCoordinator get coordinator {
    return LobbyMatchActionCoordinator(
      ensureSession: () async => session,
      validateMap: () async {
        validationCount += 1;
        return validation;
      },
      quickplay: ({required token, required request}) async {
        quickplayRequest = request;
        return quickplayMatch;
      },
      createPrivateMatch: ({required token, required request}) async {
        createdPrivateRequest = request;
        return createdPrivateMatch;
      },
      joinPrivateMatch: ({required token, required request}) async {
        joinPrivateRequest = request;
        return joinedPrivateMatch;
      },
      startMatch: ({required token, required matchId}) async {
        startedMatchIds.add(matchId);
        return startedMatch;
      },
      loadMatch: ({required token, required matchId}) async {
        loadedMatchIds.add(matchId);
        return loadedMatch;
      },
      leaveMatch: ({required token, required matchId}) async {
        leftMatchIds.add(matchId);
      },
      rememberMatch: ({required session, required match}) {
        remembered.add(_MatchEntry(session, match));
      },
      watchMatch: ({required session, required match}) {
        watched.add(_MatchEntry(session, match));
      },
      clearMatch: clearedSessions.add,
      enterMatch: ({required session, required match}) {
        entered.add(_MatchEntry(session, match));
      },
      scheduleAutoStartRefresh: scheduled.add,
      stopLobbyUpdates: () => stoppedCount += 1,
      canContinue: () => true,
    );
  }
}

final class _MatchEntry {
  final NetworkSession session;
  final WireMatch match;

  const _MatchEntry(this.session, this.match);
}
