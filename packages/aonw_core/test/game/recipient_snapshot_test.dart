import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/view.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:test/test.dart';

void main() {
  final metadata = GameSnapshotMetadata(
    id: 'match-1',
    schemaVersion: 1,
    name: 'Match',
    world: const WorldReference(name: 'world', source: MapSource.asset),
    savedAtUtc: DateTime.utc(2026),
    camera: GameSnapshotCamera.zero,
  );

  test('owns one non-negative visible event offset', () {
    final snapshot = RecipientSnapshot(
      metadata: metadata,
      state: PlayerViewState(
        recipientPlayerId: 'player-1',
        projectedState: const {},
      ),
      visibleOffset: 7,
    );

    expect(snapshot.visibleOffset, 7);
    expect(snapshot.state.recipientPlayerId, 'player-1');
  });

  test('rejects a negative visible event offset', () {
    expect(
      () => RecipientSnapshot(
        metadata: metadata,
        state: PlayerViewState(
          recipientPlayerId: 'player-1',
          projectedState: const {},
        ),
        visibleOffset: -1,
      ),
      throwsArgumentError,
    );
  });
}
