import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reducer_parity_auto_explore_characterization.dart';
import 'reducer_parity_fixture.dart';

void main() {
  late List<ReducerParityFixture> fixtures;
  late List<ReducerParityFixture> family;

  setUpAll(() {
    family =
        AutoExploreReducerParityCharacterization.extend(
              ReducerParityCorpus.load(Directory.current),
            )
            .where((fixture) => fixture.family == 'auto-explore')
            .toList(growable: false);
    fixtures = family
        .where(
          (fixture) => fixture.id.startsWith('auto-explore-characterization-'),
        )
        .toList(growable: false);
  });

  _registerAutoExploreCorpusGuards(() => fixtures, () => family);
  _registerAutoExploreOracleGuards(() => fixtures);
  _registerAutoExploreIndependenceGuards();
}

typedef _FixtureProvider = List<ReducerParityFixture> Function();

void _registerAutoExploreCorpusGuards(
  _FixtureProvider fixtureProvider,
  _FixtureProvider familyProvider,
) {
  test('extends three seeds with exactly 12 wire-safe shared cases', () {
    expect(fixtureProvider(), hasLength(12));
    expect(familyProvider(), hasLength(15));
    expect(
      familyProvider().map((fixture) => fixture.id),
      containsAll(const {
        'auto-explore-adjacent-accepted',
        'auto-explore-wrong-actor-rejected',
        'auto-explore-no-target-rejected',
      }),
    );
    expect(
      () => AutoExploreReducerParityCharacterization.validateForTest(
        fixtureProvider(),
      ),
      returnsNormally,
    );
    for (final fixture in fixtureProvider()) {
      final encoded = DomainCommandCodec.toJson(fixture.command);
      expect(DomainCommandCodec.fromJson(encoded), fixture.command);
    }
  });

  test('fails closed when a reviewed case is removed', () {
    expect(
      () => AutoExploreReducerParityCharacterization.validateForTest(
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

  test('fails closed on outcome and reason drift', () {
    final fixtures = fixtureProvider();
    final source = _autoExploreFixtureBySuffix(
      fixtures,
      'working-precedence-rejected',
    );
    for (final drifted in [
      _copyAutoExploreFixture(
        source,
        expectedAccepted: true,
        expectedReason: null,
      ),
      _copyAutoExploreFixture(source, expectedReason: 'different_reason'),
    ]) {
      expect(
        () => AutoExploreReducerParityCharacterization.validateForTest(
          _replaceAutoExploreFixture(fixtures, source, drifted),
        ),
        throwsStateError,
      );
    }
  });

  test('fails closed on state and event oracle drift', () {
    final fixtures = fixtureProvider();
    final source = _autoExploreFixtureBySuffix(
      fixtures,
      'partial-queued-accepted',
    );
    final driftedState = Map<String, dynamic>.from(source.expectedState)
      ..['units'] = const <Map<String, dynamic>>[];
    for (final drifted in [
      _copyAutoExploreFixture(source, expectedState: driftedState),
      _copyAutoExploreFixture(source, expectedEvents: const []),
    ]) {
      expect(
        () => AutoExploreReducerParityCharacterization.validateForTest(
          _replaceAutoExploreFixture(fixtures, source, drifted),
        ),
        throwsStateError,
      );
    }
  });
}

void _registerAutoExploreOracleGuards(_FixtureProvider fixtureProvider) {
  test('every expected state preserves unrelated sentinels', () {
    for (final fixture in fixtureProvider()) {
      final expected = PersistentGameState.fromJson(fixture.expectedState);
      expect(
        expected.units.map((unit) => unit.id),
        contains('auto_explore_sentinel_unit'),
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
        expected.wonderRegistry,
        fixture.state.wonderRegistry,
        reason: fixture.id,
      );
      expect(
        expected.runtimeState.submittedPlayerIds,
        fixture.state.runtimeState.submittedPlayerIds,
        reason: fixture.id,
      );
      expect(
        expected.runtimeState.timeoutStreaksByPlayerId,
        fixture.state.runtimeState.timeoutStreaksByPlayerId,
        reason: fixture.id,
      );
      expect(
        expected.runtimeState.resourceTradeAgreements,
        fixture.state.runtimeState.resourceTradeAgreements,
        reason: fixture.id,
      );
      expect(
        expected.runtimeState.turnStartedAt,
        fixture.state.runtimeState.turnStartedAt,
        reason: fixture.id,
      );
    }
  });

  test('accepted outcomes pin posture, queue, no-op, fog, and contact', () {
    final fixtures = fixtureProvider();
    final partial = _autoExploreFixtureBySuffix(
      fixtures,
      'partial-queued-accepted',
    );
    final partialState = PersistentGameState.fromJson(partial.expectedState);
    final partialUnit = partialState.units.singleWhere(
      (unit) => unit.id == 'auto_explore_scout',
    );
    expect(
      (partialUnit.col, partialUnit.movementPoints, partialUnit.posture),
      (1, 0, UnitPosture.autoExploring),
    );
    expect(partialUnit.queuedPath?.targetCol, 5);
    expect(partialUnit.queuedPath?.steps, hasLength(6));
    expect(partial.expectedEvents.single['type'], 'UnitMoved');

    final tieBreak = PersistentGameState.fromJson(
      _autoExploreFixtureBySuffix(fixtures, 'tie-break-accepted').expectedState,
    );
    expect(
      tieBreak.units.singleWhere((unit) => unit.id == 'auto_explore_scout').col,
      0,
    );

    final hidden = _autoExploreFixtureBySuffix(
      fixtures,
      'hidden-city-no-op-accepted',
    );
    final hiddenState = PersistentGameState.fromJson(hidden.expectedState);
    final hiddenUnit = hiddenState.units.singleWhere(
      (unit) => unit.id == 'auto_explore_scout',
    );
    expect(
      (hiddenUnit.col, hiddenUnit.posture),
      (0, UnitPosture.autoExploring),
    );
    expect(hidden.expectedEvents, isEmpty);

    final noFog = PersistentGameState.fromJson(
      _autoExploreFixtureBySuffix(fixtures, 'no-fog-accepted').expectedState,
    );
    expect(noFog.fogOfWar.fogForPlayer('player_1').visibleHexes, hasLength(3));

    final contact = PersistentGameState.fromJson(
      _autoExploreFixtureBySuffix(
        fixtures,
        'contact-discovery-accepted',
      ).expectedState,
    );
    expect(contact.runtimeState.diplomacy.contactKeys, {
      'player_1|player_2',
      'player_2|player_3',
    });
  });

  test('accepted cases clear owned interaction; rejections preserve it', () {
    for (final fixture in fixtureProvider()) {
      final expected = PersistentGameState.fromJson(fixture.expectedState);
      if (fixture.expectedAccepted) {
        expect(expected.runtimeState.pendingAction, isNull, reason: fixture.id);
        expect(
          expected.runtimeState.cityFoundingDraft,
          isNull,
          reason: fixture.id,
        );
      } else {
        expect(
          expected.runtimeState.pendingAction,
          fixture.state.runtimeState.pendingAction,
          reason: fixture.id,
        );
        expect(
          expected.runtimeState.cityFoundingDraft,
          fixture.state.runtimeState.cityFoundingDraft,
          reason: fixture.id,
        );
      }
    }
  });
}

void _registerAutoExploreIndependenceGuards() {
  test('expectation sources cannot call production calculators', () {
    final support = '${Directory.current.path}/test/support';
    final sources = [
      File('$support/reducer_parity_auto_explore_characterization_cases.dart'),
      File(
        '$support/reducer_parity_auto_explore_characterization_fixture.dart',
      ),
      File('$support/reducer_parity_auto_explore_characterization_oracle.dart'),
    ];
    const forbidden = [
      'PersistentUnitActionResolver',
      'PersistentMoveUnitResolver',
      'ScoutAutoExplorePlanner',
      'MovementCommandResolver',
      'MovementReducer.',
      'GameStateReducer',
      'LocalCommandResolver',
      'ServerCommandReducer',
      'UnitMovementPathfinder',
      'FogOfWarService',
      'FogRevealCalculator',
      'DiplomaticContact',
      'recomputeAfterUnitMove',
      'mergeDiscoveredContacts',
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
    expect(
      names,
      isNot(contains(startsWith('auto-explore-characterization-'))),
    );
  });
}

ReducerParityFixture _autoExploreFixtureBySuffix(
  List<ReducerParityFixture> fixtures,
  String suffix,
) {
  return fixtures.singleWhere((fixture) => fixture.id.endsWith(suffix));
}

List<ReducerParityFixture> _replaceAutoExploreFixture(
  List<ReducerParityFixture> fixtures,
  ReducerParityFixture source,
  ReducerParityFixture replacement,
) {
  return [
    for (final fixture in fixtures)
      if (identical(fixture, source)) replacement else fixture,
  ];
}

ReducerParityFixture _copyAutoExploreFixture(
  ReducerParityFixture source, {
  bool? expectedAccepted,
  Object? expectedReason = _autoExploreUnchanged,
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
    expectedReason: identical(expectedReason, _autoExploreUnchanged)
        ? source.expectedReason
        : expectedReason as String?,
    expectedSave: source.expectedSave,
    expectedState: expectedState ?? source.expectedState,
    expectedEvents: expectedEvents ?? source.expectedEvents,
  );
}

const _autoExploreUnchanged = Object();
