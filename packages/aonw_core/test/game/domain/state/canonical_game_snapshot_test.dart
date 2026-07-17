import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:test/test.dart';

void main() {
  test('persisted interaction owns drafts and supports explicit clearing', () {
    final draft = CityFoundingDraft(
      unitId: 'settler-1',
      ownerPlayerId: 'player-1',
      center: const CityHex(col: 1, row: 2),
      controlledHexes: const [CityHex(col: 1, row: 3)],
    );
    final interaction = PersistedInteractionState(
      cityFoundingDraft: draft,
      pendingAction: const PendingResearchSelection(ownerPlayerId: 'player-1'),
    );

    expect(interaction.cityFoundingDraft, draft);
    expect(identical(interaction.cityFoundingDraft, draft), isFalse);
    expect(
      interaction.copyWith(cityFoundingDraft: null).cityFoundingDraft,
      isNull,
    );
    expect(interaction.copyWith(pendingAction: null).pendingAction, isNull);
  });

  test('canonical envelope validates offsets and has value semantics', () {
    final first = _snapshot();
    final second = _snapshot();

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first.copyWith(eventLogOffset: 8).eventLogOffset, 8);
    expect(() => first.copyWith(eventLogOffset: -1), throwsArgumentError);
  });
}

CanonicalGameSnapshot _snapshot() {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 1,
      matchRules: MatchRules.standard,
      participants: const [],
    ),
    session: MatchSessionState.snapshot(gameMode: GameMode.multiplayer),
    metadata: GameSnapshotMetadata(
      id: 'save-1',
      schemaVersion: 3,
      name: 'Campaign',
      world: const WorldReference(name: 'verdantia', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 17),
      camera: GameSnapshotCamera.zero,
    ),
    interaction: PersistedInteractionState(
      pendingAction: const PendingResearchSelection(ownerPlayerId: 'player-1'),
    ),
    eventLogOffset: 7,
  );
}
