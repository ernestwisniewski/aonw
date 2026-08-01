import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reducer_parity_fixture.dart';
import 'reducer_parity_movement_characterization.dart';

void main() {
  late List<ReducerParityFixture> fixtures;

  setUpAll(() {
    fixtures =
        MovementReducerParityCharacterization.extend(
              ReducerParityCorpus.load(Directory.current),
            )
            .where((fixture) {
              return fixture.id.startsWith('movement-characterization-');
            })
            .toList(growable: false);
  });

  _registerMovementCorpusGuards(() => fixtures);
  _registerMovementOracleGuards(() => fixtures);
  _registerMovementIndependenceGuards();
}

typedef _FixtureProvider = List<ReducerParityFixture> Function();

void _registerMovementCorpusGuards(_FixtureProvider fixtureProvider) {
  test('movement corpus has exactly 18 reviewed wire-safe shared cases', () {
    final fixtures = fixtureProvider();
    expect(fixtures, hasLength(18));
    expect(
      () => MovementReducerParityCharacterization.validateForTest(fixtures),
      returnsNormally,
    );
    for (final fixture in fixtures) {
      final encoded = DomainCommandCodec.toJson(fixture.command);
      expect(DomainCommandCodec.fromJson(encoded), fixture.command);
    }
  });

  test('movement corpus fails closed when a reviewed case is removed', () {
    expect(
      () => MovementReducerParityCharacterization.validateForTest(
        fixtureProvider().sublist(1),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('characterization is incomplete'),
        ),
      ),
    );
  });

  test('movement corpus fails closed on outcome and reason drift', () {
    final fixtures = fixtureProvider();
    final source = fixtures.singleWhere(
      (fixture) => fixture.id.endsWith('unit-working-rejected'),
    );
    for (final drifted in [
      _copyMovementFixture(
        source,
        expectedAccepted: true,
        expectedReason: null,
      ),
      _copyMovementFixture(source, expectedReason: 'different_reason'),
    ]) {
      expect(
        () => MovementReducerParityCharacterization.validateForTest(
          _replaceMovementFixture(fixtures, source, drifted),
        ),
        throwsStateError,
      );
    }
  });

  test('movement corpus fails closed on state and event oracle drift', () {
    final fixtures = fixtureProvider();
    final source = fixtures.singleWhere(
      (fixture) => fixture.id.endsWith('partial-queued-accepted'),
    );
    final driftedState = Map<String, dynamic>.from(source.expectedState)
      ..['units'] = const <Map<String, dynamic>>[];
    for (final drifted in [
      _copyMovementFixture(source, expectedState: driftedState),
      _copyMovementFixture(source, expectedEvents: const []),
    ]) {
      expect(
        () => MovementReducerParityCharacterization.validateForTest(
          _replaceMovementFixture(fixtures, source, drifted),
        ),
        throwsStateError,
      );
    }
  });
}

void _registerMovementOracleGuards(_FixtureProvider fixtureProvider) {
  test('every expected state preserves unrelated movement sentinels', () {
    for (final fixture in fixtureProvider()) {
      final expected = CanonicalGameSnapshotCodec.decodeDomainState(
        fixture.expectedState,
      );
      expect(
        expected.units.map((unit) => unit.id),
        contains('movement_sentinel'),
        reason: fixture.id,
      );
      expect(fixture.state.cities, isNotEmpty, reason: fixture.id);
      expect(expected.cities, fixture.state.cities, reason: fixture.id);
      expect(fixture.state.artifacts, isNotEmpty, reason: fixture.id);
      expect(expected.artifacts, fixture.state.artifacts, reason: fixture.id);
      expect(fixture.state.fieldImprovements, isNotEmpty, reason: fixture.id);
      expect(
        expected.fieldImprovements,
        fixture.state.fieldImprovements,
        reason: fixture.id,
      );
      expect(fixture.state.research.players, isNotEmpty, reason: fixture.id);
      expect(expected.research, fixture.state.research, reason: fixture.id);
      expect(
        fixture.state.wonderRegistry.completedBy,
        isNotEmpty,
        reason: fixture.id,
      );
      expect(
        expected.wonderRegistry,
        fixture.state.wonderRegistry,
        reason: fixture.id,
      );
      expect(
        fixture.state.actions.cityFoundingDraft,
        isNotNull,
        reason: fixture.id,
      );
      expect(
        expected.actions.cityFoundingDraft,
        fixture.state.actions.cityFoundingDraft,
        reason: fixture.id,
      );
      expect(
        fixture.state.actions.pendingAction,
        isNotNull,
        reason: fixture.id,
      );
      expect(
        expected.actions.pendingAction,
        fixture.state.actions.pendingAction,
        reason: fixture.id,
      );
      expect(
        expected.submittedPlayerIds,
        fixture.state.submittedPlayerIds,
        reason: fixture.id,
      );
      expect(
        expected.timeoutStreaksByPlayerId,
        fixture.state.timeoutStreaksByPlayerId,
        reason: fixture.id,
      );
      expect(
        expected.mapObjectiveHoldStatesByObjectiveId,
        fixture.state.mapObjectiveHoldStatesByObjectiveId,
        reason: fixture.id,
      );
      expect(
        fixture.state.resourceTradeAgreements,
        isNotEmpty,
        reason: fixture.id,
      );
      expect(
        expected.resourceTradeAgreements,
        fixture.state.resourceTradeAgreements,
        reason: fixture.id,
      );
      expect(
        expected.turnStartedAt,
        fixture.state.turnStartedAt,
        reason: fixture.id,
      );
    }
  });

  test('queued, hidden, contact, and ordered-event outcomes are pinned', () {
    final fixtures = fixtureProvider();
    final partial = _movementFixtureBySuffix(
      fixtures,
      'partial-queued-accepted',
    );
    final partialState = CanonicalGameSnapshotCodec.decodeDomainState(
      partial.expectedState,
    );
    final partialUnit = partialState.units.first;
    expect((partialUnit.col, partialUnit.movementPoints), (2, 0));
    expect(partialUnit.queuedPath?.targetCol, 4);
    expect(partialUnit.queuedPath?.steps.map((step) => step.cumulativeCost), [
      0,
      1,
      2,
      3,
      4,
    ]);
    expect(partial.expectedEvents.single['type'], 'UnitMoved');

    for (final suffix in [
      'hidden-target-no-op-accepted',
      'hidden-intermediate-no-op-accepted',
    ]) {
      final hidden = _movementFixtureBySuffix(fixtures, suffix);
      expect(
        hidden.expectedState,
        CanonicalGameSnapshotCodec.encodeDomainState(hidden.state),
      );
      expect(hidden.expectedEvents, isEmpty);
    }

    final contact = _movementFixtureBySuffix(
      fixtures,
      'contact-discovery-accepted',
    );
    final contactState = CanonicalGameSnapshotCodec.decodeDomainState(
      contact.expectedState,
    );
    expect(contactState.diplomacy.contactKeys, {'player_1|player_2'});
    expect(
      contactState.fogOfWar.fogForPlayer('player_1').visibleHexes,
      hasLength(4),
    );
  });
}

void _registerMovementIndependenceGuards() {
  test('movement expectation sources cannot call production calculators', () {
    final support = '${Directory.current.path}/test/support';
    final sources = [
      File('$support/reducer_parity_movement_characterization_cases.dart'),
      File('$support/reducer_parity_movement_characterization_fixture.dart'),
      File('$support/reducer_parity_movement_characterization_oracle.dart'),
    ];
    const forbidden = [
      'PersistentMoveUnitResolver',
      'MovementReducer.',
      'GameStateReducer',
      'LocalCommandResolver',
      'ServerCommandReducer',
      'UnitMovementPathfinder',
      'UnitMovementFeasibility',
      'UnitMovementCostRules',
      'FogOfWarService',
      'FogRevealCalculator',
      'DiplomaticContact',
      'planTowardBlockedTarget',
      'recomputeAfterUnitMove',
      'mergeDiscoveredContacts',
      'withDiscoveredDiplomaticContacts',
      'dart:convert',
    ];
    for (final source in sources) {
      final contents = source.readAsStringSync();
      for (final token in forbidden) {
        expect(contents, isNot(contains(token)), reason: source.path);
      }
    }
  });

  test('programmatic characterization is not duplicated as JSON', () {
    final directory = Directory(
      '${Directory.current.path}/test/fixtures/reducer_parity',
    );
    final names = directory.listSync().whereType<File>().map(
      (file) => file.uri.pathSegments.last,
    );
    expect(names, isNot(contains(startsWith('movement-characterization-'))));
  });
}

ReducerParityFixture _movementFixtureBySuffix(
  List<ReducerParityFixture> fixtures,
  String suffix,
) {
  return fixtures.singleWhere((fixture) => fixture.id.endsWith(suffix));
}

List<ReducerParityFixture> _replaceMovementFixture(
  List<ReducerParityFixture> fixtures,
  ReducerParityFixture source,
  ReducerParityFixture replacement,
) {
  return [
    for (final fixture in fixtures)
      if (identical(fixture, source)) replacement else fixture,
  ];
}

ReducerParityFixture _copyMovementFixture(
  ReducerParityFixture source, {
  bool? expectedAccepted,
  Object? expectedReason = _movementUnchanged,
  Map<String, dynamic>? expectedState,
  List<Map<String, dynamic>>? expectedEvents,
}) {
  return ReducerParityFixture(
    id: source.id,
    family: source.family,
    now: source.now,
    actorPlayerId: source.actorPlayerId,
    tick: source.tick,
    mapData: source.mapData,
    match: source.match,
    save: source.save,
    state: source.state,
    command: source.command,
    expectedAccepted: expectedAccepted ?? source.expectedAccepted,
    expectedReason: identical(expectedReason, _movementUnchanged)
        ? source.expectedReason
        : expectedReason as String?,
    expectedSave: source.expectedSave,
    expectedState: expectedState ?? source.expectedState,
    expectedEvents: expectedEvents ?? source.expectedEvents,
  );
}

const _movementUnchanged = Object();
