import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_endpoint.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:test/test.dart';

import 'realtime_match_hub_test.dart';

void main() {
  test('rejects commands before the lobby match starts', () async {
    final mapCatalog = TestMapCatalog(testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = TestMatchStore();
    final match = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user-not-running',
      request: CreateMatchRequest(
        name: 'Not running command',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    final owner = match.players.single;
    final connection = await connectTestParticipantForTest(
      hub: hub,
      store: store,
      userIdentifier: owner.userId,
      matchId: match.id,
    );
    final acknowledgement = connection.stream.firstWhere(
      (message) => message.ack != null,
    );

    connection.input.add(
      MultiplayerClientMessage(
        clientMessageId: 'not-running-command',
        lastSeenOffset: 0,
        requestSnapshot: false,
        command: WireCommand(
          matchId: match.id,
          tick: 1,
          turn: 1,
          actorPlayerId: owner.id,
          command: DomainCommandCodec.toJson(SubmitTurnCommand(owner.id)),
        ),
      ),
    );
    final ack = (await acknowledgement).ack!;

    expect(ack.accepted, isFalse);
    expect(ack.clientMessageId, 'not-running-command');
    expect(ack.reason, 'match_not_running');
    expect(ack.offset, 0);
    expect(ack.events, isEmpty);
    expect(ack.movementExecutions, isEmpty);
    expect(await store.listEvents(match.id, 0), isEmpty);
    expect((await store.findState(match.id))!.offset, 0);
  });

  test(
    'returns reducer payload rejections without persisting an event',
    () async {
      final fixture = await startRunningMatchFixtureForTest(
        'invalid-command',
        disconnectOwnerSetup: true,
        disconnectGuestSetup: true,
      );
      final owner = fixture.match.players.first;
      final connection = await connectTestParticipantForTest(
        hub: fixture.hub,
        store: fixture.store,
        userIdentifier: fixture.ownerUserIdentifier,
        matchId: fixture.match.id,
      );
      final before = (await fixture.store.findState(fixture.match.id))!;
      final acknowledgement = connection.stream.firstWhere(
        (message) => message.ack != null,
      );

      connection.input.add(
        MultiplayerClientMessage(
          clientMessageId: 'invalid-payload-command',
          lastSeenOffset: before.offset,
          requestSnapshot: false,
          command: WireCommand(
            matchId: fixture.match.id,
            tick: 1,
            turn: fixture.match.turn,
            actorPlayerId: owner.id,
            command: const {'type': 'SelectUnit', 'unitId': 'unit_1'},
          ),
        ),
      );
      final ack = (await acknowledgement).ack!;
      final after = (await fixture.store.findState(fixture.match.id))!;

      expect(ack.accepted, isFalse);
      expect(ack.clientMessageId, 'invalid-payload-command');
      expect(ack.reason, 'invalid_command_payload');
      expect(ack.offset, before.offset);
      expect(ack.events, isEmpty);
      expect(ack.movementExecutions, isEmpty);
      expect(await fixture.store.listEvents(fixture.match.id, 0), isEmpty);
      expect(after.match.toJson(), before.match.toJson());
      expect(after.snapshot.toJson(), before.snapshot.toJson());
    },
  );
}
