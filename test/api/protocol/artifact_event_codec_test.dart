import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips additive artifact lifecycle events through WireEvent', () {
    const codec = EventCodec();
    const events = <GameEvent>[
      ArtifactExcavationStartedEvent(
        artifactId: 'artifact_1',
        ownerPlayerId: 'player_1',
        unitId: 'worker_1',
        col: 2,
        row: 3,
      ),
      ArtifactCarriedEvent(
        artifactId: 'artifact_1',
        ownerPlayerId: 'player_1',
        unitId: 'worker_1',
        col: 4,
        row: 5,
      ),
      ArtifactStoredEvent(
        artifactId: 'artifact_1',
        ownerPlayerId: 'player_1',
        cityId: 'city_1',
        col: 4,
        row: 5,
      ),
    ];
    final wire = codec.toWire(
      matchId: 'match_1',
      offset: 10,
      timestamp: DateTime.utc(2026, 7, 30),
      actorPlayerId: 'player_1',
      tick: 8,
      turn: 3,
      command: null,
      events: events,
    );

    final restored = codec.eventsFromWire(WireEvent.fromJson(wire.toJson()));

    expect(
      restored.map(GameEventSerializer.toJson),
      events.map(GameEventSerializer.toJson),
    );
  });
}
