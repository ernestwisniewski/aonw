part of '../player_match_event_audience_test.dart';

void _registerMovementEventAudienceTests() {
  test('projects coarse movement independently from exact path evidence', () {
    const origin = HexCoordinate(col: 0, row: 0);
    const destination = HexCoordinate(col: 3, row: 0);
    final previous = _ownership(
      units: [_unit('mover', ownerPlayerId: 'player-1', col: 0, row: 0)],
    );
    final next = _ownership(
      units: [_unit('mover', ownerPlayerId: 'player-1', col: 3, row: 0)],
    );
    final canonical = PlayerMatchEventAudience.annotateForStorage(
      events: const [
        UnitMovedEvent(
          unitId: 'mover',
          fromCol: 0,
          fromRow: 0,
          toCol: 3,
          toRow: 0,
        ),
      ],
      participantPlayerIds: const ['player-1', 'observer', 'hidden'],
      previous: previous,
      next: next,
      previousFog: _fog('observer', {origin}),
      nextFog: _fog('observer', {destination}),
    );

    expect(
      PlayerMatchEventAudience.projectForRecipient(
        canonical,
        recipientPlayerId: 'player-1',
      ),
      hasLength(1),
    );
    final observer = PlayerMatchEventAudience.projectForRecipient(
      canonical,
      recipientPlayerId: 'observer',
    );
    expect(observer, hasLength(1));
    expect(
      GameEventSerializer.fromJson(observer.single),
      isA<UnitMovedEvent>(),
    );
    expect(
      PlayerMatchEventAudience.projectForRecipient(
        canonical,
        recipientPlayerId: 'hidden',
      ),
      isEmpty,
    );
  });
}
