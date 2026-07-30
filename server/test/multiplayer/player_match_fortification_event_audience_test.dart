import 'package:aonw_core/domain.dart';
import 'package:aonw_server/src/multiplayer/player_match_event_audience.dart';
import 'package:test/test.dart';

void main() {
  test('keeps fortification threat targets owner-only', () {
    final canonical = PlayerMatchEventAudience.annotateForStorage(
      events: [
        FortifiedUnitThreatenedEvent(
          unitId: 'fortifier',
          ownerPlayerId: 'player-1',
          targets: const [
            FortifiedUnitThreatTarget(unitId: 'hidden-enemy', col: 4, row: 3),
          ],
        ),
      ],
      participantPlayerIds: const ['player-1', 'player-2'],
      previous: GameEventOwnershipIndex.empty,
      next: GameEventOwnershipIndex.empty,
    );

    final owner = PlayerMatchEventAudience.projectForRecipient(
      canonical,
      recipientPlayerId: 'player-1',
    );
    final opponent = PlayerMatchEventAudience.projectForRecipient(
      canonical,
      recipientPlayerId: 'player-2',
    );

    expect(owner, hasLength(1));
    expect(owner.single['targets'], [
      {'unitId': 'hidden-enemy', 'col': 4, 'row': 3},
    ]);
    expect(opponent, isEmpty);
    expect(opponent.toString(), isNot(contains('hidden-enemy')));
  });
}
