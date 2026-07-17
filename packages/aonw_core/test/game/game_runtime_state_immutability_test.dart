import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('GameRuntimeState immutability', () {
    test('snapshot is detached from all collection sources', _sourceMutation);
    test('collection getters reject mutation', _getterMutation);
    test('scalar copy shares unchanged collections', _scalarCopySharing);
    test('collection replacements are copied', _replacementCopying);
    test('copyWith clears all nullable fields', _nullableFieldClearing);
    test('legacy state can become an immutable snapshot', _legacySnapshot);
    test('stripping interaction shares persistent state', _stripInteraction);
  });
}

void _sourceMutation() {
  final sources = _collections('source');
  final state = _snapshot(sources);
  final expected = GameRuntimeState.fromJson(state.toJson());
  final originalHash = state.hashCode;
  final originalJson = state.toJson();

  _mutate(sources);

  _expectCollectionsEqual(state, expected);
  expect(state.hashCode, originalHash);
  expect(state.toJson(), originalJson);
}

void _getterMutation() {
  final state = _snapshot(_collections('getter'));
  final mutations = <String, void Function()>{
    'submittedPlayerIds': () => state.submittedPlayerIds.add('other'),
    'timeoutStreaksByPlayerId': () {
      state.timeoutStreaksByPlayerId['other'] = 2;
    },
    'afkPlayerIds': () => state.afkPlayerIds.add('other'),
    'kickedPlayerIds': () => state.kickedPlayerIds.add('other'),
    'intendedAttacks': () => state.intendedAttacks.add(_extraAttack),
    'dominationHoldTurnsByPlayerId': () {
      state.dominationHoldTurnsByPlayerId['other'] = 2;
    },
    'culturalVictoryHoldTurnsByPlayerId': () {
      state.culturalVictoryHoldTurnsByPlayerId['other'] = 2;
    },
    'mapObjectiveHoldStatesByObjectiveId': () {
      state.mapObjectiveHoldStatesByObjectiveId['other'] = _extraObjective;
    },
    'resourceTradeAgreements': () {
      state.resourceTradeAgreements.add(_extraAgreement);
    },
  };

  for (final mutation in mutations.entries) {
    expect(mutation.value, throwsUnsupportedError, reason: mutation.key);
  }
}

void _scalarCopySharing() {
  final state = _snapshot(_collections('shared'));
  final copied = state.copyWith(turnStartedAt: DateTime.utc(2026, 7, 18));

  expect(copied.turnStartedAt, DateTime.utc(2026, 7, 18));
  _expectCollectionsShared(copied, state);
}

void _replacementCopying() {
  final initial = _snapshot(_collections('initial'));
  final replacements = _collections('replacement');
  final copied = initial.copyWith(
    submittedPlayerIds: replacements.submittedPlayerIds,
    timeoutStreaksByPlayerId: replacements.timeoutStreaksByPlayerId,
    afkPlayerIds: replacements.afkPlayerIds,
    kickedPlayerIds: replacements.kickedPlayerIds,
    intendedAttacks: replacements.intendedAttacks,
    dominationHoldTurnsByPlayerId: replacements.dominationHoldTurnsByPlayerId,
    culturalVictoryHoldTurnsByPlayerId:
        replacements.culturalVictoryHoldTurnsByPlayerId,
    mapObjectiveHoldStatesByObjectiveId:
        replacements.mapObjectiveHoldStatesByObjectiveId,
    resourceTradeAgreements: replacements.resourceTradeAgreements,
  );
  final expected = GameRuntimeState.fromJson(copied.toJson());

  _expectCollectionsDetached(copied, replacements);
  _mutate(replacements);
  _expectCollectionsEqual(copied, expected);
}

void _nullableFieldClearing() {
  final state = GameRuntimeState.snapshot(
    cityFoundingDraft: CityFoundingDraft(
      unitId: 'settler',
      ownerPlayerId: 'player',
      center: const CityHex(col: 1, row: 2),
    ),
    pendingAction: const PendingResearchSelection(ownerPlayerId: 'player'),
    turnStartedAt: DateTime.utc(2026, 7, 17),
  );

  final cleared = state.copyWith(
    cityFoundingDraft: null,
    pendingAction: null,
    turnStartedAt: null,
  );

  expect(cleared.cityFoundingDraft, isNull);
  expect(cleared.pendingAction, isNull);
  expect(cleared.turnStartedAt, isNull);
}

void _legacySnapshot() {
  final sources = _collections('legacy');
  final legacy = GameRuntimeState(
    submittedPlayerIds: sources.submittedPlayerIds,
    timeoutStreaksByPlayerId: sources.timeoutStreaksByPlayerId,
    afkPlayerIds: sources.afkPlayerIds,
    kickedPlayerIds: sources.kickedPlayerIds,
    intendedAttacks: sources.intendedAttacks,
    dominationHoldTurnsByPlayerId: sources.dominationHoldTurnsByPlayerId,
    culturalVictoryHoldTurnsByPlayerId:
        sources.culturalVictoryHoldTurnsByPlayerId,
    mapObjectiveHoldStatesByObjectiveId:
        sources.mapObjectiveHoldStatesByObjectiveId,
    resourceTradeAgreements: sources.resourceTradeAgreements,
  );
  final snapshot = legacy.immutableSnapshot();
  final expected = GameRuntimeState.fromJson(snapshot.toJson());

  expect(snapshot, isNot(same(legacy)));
  expect(snapshot.immutableSnapshot(), same(snapshot));
  _mutate(sources);
  _expectCollectionsEqual(snapshot, expected);
}

void _stripInteraction() {
  final sources = _collections('strip');
  final diplomacy = DiplomacyState.empty.registerCityAttack(
    attackerPlayerId: 'player',
    defenderPlayerId: 'other',
  );
  final state = GameRuntimeState.snapshot(
    cityFoundingDraft: CityFoundingDraft(
      unitId: 'settler',
      ownerPlayerId: 'player',
      center: const CityHex(col: 1, row: 2),
    ),
    pendingAction: const PendingResearchSelection(ownerPlayerId: 'player'),
    submittedPlayerIds: sources.submittedPlayerIds,
    timeoutStreaksByPlayerId: sources.timeoutStreaksByPlayerId,
    afkPlayerIds: sources.afkPlayerIds,
    kickedPlayerIds: sources.kickedPlayerIds,
    intendedAttacks: sources.intendedAttacks,
    diplomacy: diplomacy,
    dominationHoldTurnsByPlayerId: sources.dominationHoldTurnsByPlayerId,
    culturalVictoryHoldTurnsByPlayerId:
        sources.culturalVictoryHoldTurnsByPlayerId,
    mapObjectiveHoldStatesByObjectiveId:
        sources.mapObjectiveHoldStatesByObjectiveId,
    resourceTradeAgreements: sources.resourceTradeAgreements,
    turnStartedAt: _turnStartedAt,
  );

  final stripped = state.withoutClientInteractionState();

  expect(stripped.cityFoundingDraft, isNull);
  expect(stripped.pendingAction, isNull);
  expect(stripped.diplomacy, same(diplomacy));
  expect(stripped.turnStartedAt, same(state.turnStartedAt));
  _expectCollectionsShared(stripped, state);
}

_RuntimeCollections _collections(String prefix) {
  final objectiveId = '${prefix}_objective';
  return (
    submittedPlayerIds: <String>{'${prefix}_submitted'},
    timeoutStreaksByPlayerId: <String, int>{'${prefix}_timeout': 1},
    afkPlayerIds: <String>{'${prefix}_afk'},
    kickedPlayerIds: <String>{'${prefix}_kicked'},
    intendedAttacks: <IntendedAttack>[_attack],
    dominationHoldTurnsByPlayerId: <String, int>{'${prefix}_domination': 2},
    culturalVictoryHoldTurnsByPlayerId: <String, int>{'${prefix}_culture': 3},
    mapObjectiveHoldStatesByObjectiveId: <String, MapObjectiveHoldState>{
      objectiveId: MapObjectiveHoldState(
        objectiveId: objectiveId,
        playerId: '${prefix}_player',
        holdTurns: 4,
      ),
    },
    resourceTradeAgreements: <ResourceTradeAgreement>[_agreement],
  );
}

GameRuntimeState _snapshot(_RuntimeCollections values) {
  return GameRuntimeState.snapshot(
    submittedPlayerIds: values.submittedPlayerIds,
    timeoutStreaksByPlayerId: values.timeoutStreaksByPlayerId,
    afkPlayerIds: values.afkPlayerIds,
    kickedPlayerIds: values.kickedPlayerIds,
    intendedAttacks: values.intendedAttacks,
    dominationHoldTurnsByPlayerId: values.dominationHoldTurnsByPlayerId,
    culturalVictoryHoldTurnsByPlayerId:
        values.culturalVictoryHoldTurnsByPlayerId,
    mapObjectiveHoldStatesByObjectiveId:
        values.mapObjectiveHoldStatesByObjectiveId,
    resourceTradeAgreements: values.resourceTradeAgreements,
    turnStartedAt: _turnStartedAt,
  );
}

void _mutate(_RuntimeCollections values) {
  values.submittedPlayerIds.add('mutated');
  values.timeoutStreaksByPlayerId['mutated'] = 5;
  values.afkPlayerIds.add('mutated');
  values.kickedPlayerIds.add('mutated');
  values.intendedAttacks.add(_extraAttack);
  values.dominationHoldTurnsByPlayerId['mutated'] = 5;
  values.culturalVictoryHoldTurnsByPlayerId['mutated'] = 5;
  values.mapObjectiveHoldStatesByObjectiveId['mutated'] = _extraObjective;
  values.resourceTradeAgreements.add(_extraAgreement);
}

void _expectCollectionsEqual(
  GameRuntimeState actual,
  GameRuntimeState expected,
) {
  expect(actual.submittedPlayerIds, expected.submittedPlayerIds);
  expect(actual.timeoutStreaksByPlayerId, expected.timeoutStreaksByPlayerId);
  expect(actual.afkPlayerIds, expected.afkPlayerIds);
  expect(actual.kickedPlayerIds, expected.kickedPlayerIds);
  expect(actual.intendedAttacks, expected.intendedAttacks);
  expect(
    actual.dominationHoldTurnsByPlayerId,
    expected.dominationHoldTurnsByPlayerId,
  );
  expect(
    actual.culturalVictoryHoldTurnsByPlayerId,
    expected.culturalVictoryHoldTurnsByPlayerId,
  );
  expect(
    actual.mapObjectiveHoldStatesByObjectiveId,
    expected.mapObjectiveHoldStatesByObjectiveId,
  );
  expect(actual.resourceTradeAgreements, expected.resourceTradeAgreements);
}

void _expectCollectionsShared(
  GameRuntimeState actual,
  GameRuntimeState source,
) {
  expect(actual.submittedPlayerIds, same(source.submittedPlayerIds));
  expect(
    actual.timeoutStreaksByPlayerId,
    same(source.timeoutStreaksByPlayerId),
  );
  expect(actual.afkPlayerIds, same(source.afkPlayerIds));
  expect(actual.kickedPlayerIds, same(source.kickedPlayerIds));
  expect(actual.intendedAttacks, same(source.intendedAttacks));
  expect(
    actual.dominationHoldTurnsByPlayerId,
    same(source.dominationHoldTurnsByPlayerId),
  );
  expect(
    actual.culturalVictoryHoldTurnsByPlayerId,
    same(source.culturalVictoryHoldTurnsByPlayerId),
  );
  expect(
    actual.mapObjectiveHoldStatesByObjectiveId,
    same(source.mapObjectiveHoldStatesByObjectiveId),
  );
  expect(actual.resourceTradeAgreements, same(source.resourceTradeAgreements));
}

void _expectCollectionsDetached(
  GameRuntimeState actual,
  _RuntimeCollections sources,
) {
  expect(actual.submittedPlayerIds, isNot(same(sources.submittedPlayerIds)));
  expect(
    actual.timeoutStreaksByPlayerId,
    isNot(same(sources.timeoutStreaksByPlayerId)),
  );
  expect(actual.afkPlayerIds, isNot(same(sources.afkPlayerIds)));
  expect(actual.kickedPlayerIds, isNot(same(sources.kickedPlayerIds)));
  expect(actual.intendedAttacks, isNot(same(sources.intendedAttacks)));
  expect(
    actual.dominationHoldTurnsByPlayerId,
    isNot(same(sources.dominationHoldTurnsByPlayerId)),
  );
  expect(
    actual.culturalVictoryHoldTurnsByPlayerId,
    isNot(same(sources.culturalVictoryHoldTurnsByPlayerId)),
  );
  expect(
    actual.mapObjectiveHoldStatesByObjectiveId,
    isNot(same(sources.mapObjectiveHoldStatesByObjectiveId)),
  );
  expect(
    actual.resourceTradeAgreements,
    isNot(same(sources.resourceTradeAgreements)),
  );
}

typedef _RuntimeCollections = ({
  Set<String> submittedPlayerIds,
  Map<String, int> timeoutStreaksByPlayerId,
  Set<String> afkPlayerIds,
  Set<String> kickedPlayerIds,
  List<IntendedAttack> intendedAttacks,
  Map<String, int> dominationHoldTurnsByPlayerId,
  Map<String, int> culturalVictoryHoldTurnsByPlayerId,
  Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId,
  List<ResourceTradeAgreement> resourceTradeAgreements,
});

final _turnStartedAt = DateTime.utc(2026, 7, 17, 12);

const _attack = IntendedAttack(
  attackerUnitId: 'attacker',
  defenderCol: 1,
  defenderRow: 2,
  declaredAtTick: 3,
  declaringPlayerId: 'player',
);

const _extraAttack = IntendedAttack(
  attackerUnitId: 'other_attacker',
  defenderCol: 3,
  defenderRow: 4,
  declaredAtTick: 5,
  declaringPlayerId: 'other',
);

const _extraObjective = MapObjectiveHoldState(
  objectiveId: 'mutated',
  playerId: 'other',
  holdTurns: 1,
);

const _agreement = ResourceTradeAgreement(
  id: 'agreement',
  exporterPlayerId: 'player',
  importerPlayerId: 'other',
  resource: ResourceType.iron,
  goldPerTurn: 2,
  remainingTurns: 3,
);

const _extraAgreement = ResourceTradeAgreement(
  id: 'extra_agreement',
  exporterPlayerId: 'other',
  importerPlayerId: 'player',
  resource: ResourceType.horses,
  goldPerTurn: 1,
  remainingTurns: 2,
);
