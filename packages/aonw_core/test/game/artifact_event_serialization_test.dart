import 'package:aonw_core/game/domain/event.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips every additive artifact lifecycle event', () {
    const events = <GameEvent>[
      ArtifactExcavationStartedEvent(
        artifactId: 'artifact_1',
        ownerPlayerId: 'player_1',
        unitId: 'scout_1',
        col: 1,
        row: 2,
      ),
      ArtifactCarriedEvent(
        artifactId: 'artifact_1',
        ownerPlayerId: 'player_1',
        unitId: 'scout_1',
        col: 1,
        row: 2,
      ),
      ArtifactStoredEvent(
        artifactId: 'artifact_1',
        ownerPlayerId: 'player_1',
        cityId: 'city_1',
        col: 2,
        row: 2,
      ),
    ];

    for (final event in events) {
      final payload = GameEventSerializer.toJson(event);
      expect(
        GameEventSerializer.toJson(GameEventSerializer.fromJson(payload)),
        payload,
      );
    }
    expect(GameEventSerializer.toJson(events.last), isNot(contains('unitId')));
  });
}
