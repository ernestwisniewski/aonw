import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live stream forwards recipient-safe combat animation facts', () async {
    final upstream = StreamController<sp.MultiplayerServerMessage>();
    late final StreamSubscription<sp.MultiplayerClientMessage> clientMessages;
    final live = LiveEventSubscription(
      serverpodHost: 'https://api.example.test',
      connector:
          ({
            required matchId,
            required token,
            required afterOffset,
            required input,
          }) {
            clientMessages = input.listen((_) {});
            return upstream.stream;
          },
    );
    final received = Completer<LiveServerEvent>();
    const codec = EventCodec();
    final combat = CombatResolvedEvent(
      attackerUnitId: 'attacker',
      defenderUnitId: 'defender',
      outcome: CombatOutcome(
        attackerUnitId: 'attacker',
        defenderUnitId: 'defender',
        attackerHpAfter: 7,
        defenderHpAfter: 0,
        attackerKilled: false,
        defenderKilled: true,
        steps: [AttackStep(damage: 10)],
      ),
    );
    final wire = codec.toWire(
      matchId: 'match_1',
      offset: 8,
      timestamp: DateTime.utc(2026, 4, 26, 12),
      actorPlayerId: 'player_1',
      command: const AttackHexCommand('attacker', 3, 4),
      events: [combat],
    );

    final handle = await live.subscribe(
      matchId: 'match_1',
      token: AuthToken('jwt-token'),
      fromOffset: 7,
      onEvent: received.complete,
      onSnapshotResync: (_) {},
    );
    upstream.add(
      sp.MultiplayerServerMessage(
        serverMessageId: 'server-8',
        matchId: 'match_1',
        offset: 8,
        event: wire.copyWith(
          events: [
            {
              ...wire.events.single,
              CombatAnimationFactCodec.eventPayloadKey:
                  CombatAnimationFactCodec.toJson(
                    const CombatAnimationFact(
                      eventIndex: 0,
                      attackerUnitId: 'attacker',
                      defenderId: 'defender',
                      attackerFromCol: 2,
                      attackerFromRow: 4,
                      attackerToCol: 3,
                      attackerToRow: 4,
                    ),
                  ),
            },
          ],
        ),
      ),
    );

    final event = await received.future;
    final resolved = event.events.single as CombatResolvedEvent;

    expect(resolved.attackerUnitId, combat.attackerUnitId);
    expect(resolved.defenderUnitId, combat.defenderUnitId);
    expect(resolved.outcome.attackerHpAfter, combat.outcome.attackerHpAfter);
    expect(resolved.outcome.defenderHpAfter, combat.outcome.defenderHpAfter);
    expect(event.combatAnimations, const [
      CombatAnimationFact(
        eventIndex: 0,
        attackerUnitId: 'attacker',
        defenderId: 'defender',
        attackerFromCol: 2,
        attackerFromRow: 4,
        attackerToCol: 3,
        attackerToRow: 4,
      ),
    ]);
    await handle.close();
    await clientMessages.cancel();
    await upstream.close();
  });
}
