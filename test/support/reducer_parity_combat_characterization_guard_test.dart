import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reducer_parity_combat_characterization.dart';
import 'reducer_parity_fixture.dart';

void main() {
  late List<ReducerParityFixture> fixtures;

  setUpAll(() {
    fixtures =
        CombatReducerParityCharacterization.extend(
              ReducerParityCorpus.load(Directory.current),
            )
            .where(
              (fixture) => fixture.id.startsWith('combat-characterization-'),
            )
            .toList(growable: false);
  });

  _registerCombatCorpusGuards(() => fixtures);
  _registerCombatOracleGuards(() => fixtures);
  _registerCombatIndependenceGuards();
}

typedef _FixtureProvider = List<ReducerParityFixture> Function();

void _registerCombatCorpusGuards(_FixtureProvider fixtureProvider) {
  test('combat corpus has exactly 17 reviewed wire-safe shared cases', () {
    final fixtures = fixtureProvider();
    expect(fixtures, hasLength(17));
    expect(
      () => CombatReducerParityCharacterization.validateForTest(fixtures),
      returnsNormally,
    );
    for (final fixture in fixtures) {
      final encoded = DomainCommandCodec.toJson(fixture.command);
      expect(DomainCommandCodec.fromJson(encoded), fixture.command);
    }
  });

  test('combat corpus fails closed when a reviewed case is removed', () {
    expect(
      () => CombatReducerParityCharacterization.validateForTest(
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

  test('combat corpus fails closed on outcome and reason drift', () {
    final fixtures = fixtureProvider();
    final source = _combatFixtureBySuffix(
      fixtures,
      'attacker-unavailable-rejected',
    );
    for (final drifted in [
      _copyCombatFixture(source, expectedAccepted: true, expectedReason: null),
      _copyCombatFixture(source, expectedReason: 'different_reason'),
    ]) {
      expect(
        () => CombatReducerParityCharacterization.validateForTest(
          _replaceCombatFixture(fixtures, source, drifted),
        ),
        throwsStateError,
      );
    }
  });

  test('combat corpus fails closed on state and event oracle drift', () {
    final fixtures = fixtureProvider();
    final source = _combatFixtureBySuffix(fixtures, 'unit-accepted');
    final driftedState = Map<String, dynamic>.from(source.expectedState)
      ..['units'] = const <Map<String, dynamic>>[];
    for (final drifted in [
      _copyCombatFixture(source, expectedState: driftedState),
      _copyCombatFixture(source, expectedEvents: const []),
    ]) {
      expect(
        () => CombatReducerParityCharacterization.validateForTest(
          _replaceCombatFixture(fixtures, source, drifted),
        ),
        throwsStateError,
      );
    }
  });
}

void _registerCombatOracleGuards(_FixtureProvider fixtureProvider) {
  test('every expected state preserves unrelated combat sentinels', () {
    for (final fixture in fixtureProvider()) {
      final before = fixture.state;
      final expected = PersistentGameState.fromJson(fixture.expectedState);
      expect(
        expected.units.map((unit) => unit.id),
        contains('combat_sentinel_unit'),
        reason: fixture.id,
      );
      expect(
        expected.cities.singleWhere(
          (city) => city.id == 'combat_sentinel_city',
        ),
        before.cities.singleWhere((city) => city.id == 'combat_sentinel_city'),
        reason: fixture.id,
      );
      expect(
        expected.artifacts.singleWhere(
          (artifact) => artifact.id == 'combat_sentinel_artifact',
        ),
        before.artifacts.singleWhere(
          (artifact) => artifact.id == 'combat_sentinel_artifact',
        ),
        reason: fixture.id,
      );
      expect(expected.fieldImprovements, before.fieldImprovements);
      expect(expected.research, before.research);
      expect(expected.wonderRegistry, before.wonderRegistry);
      expect(
        expected.runtimeState.submittedPlayerIds,
        before.runtimeState.submittedPlayerIds,
      );
      expect(
        expected.runtimeState.timeoutStreaksByPlayerId,
        before.runtimeState.timeoutStreaksByPlayerId,
      );
      expect(
        expected.runtimeState.afkPlayerIds,
        before.runtimeState.afkPlayerIds,
      );
      expect(
        expected.runtimeState.kickedPlayerIds,
        before.runtimeState.kickedPlayerIds,
      );
      expect(
        expected.runtimeState.intendedAttacks,
        before.runtimeState.intendedAttacks,
      );
      expect(
        expected.runtimeState.dominationHoldTurnsByPlayerId,
        before.runtimeState.dominationHoldTurnsByPlayerId,
      );
      expect(
        expected.runtimeState.culturalVictoryHoldTurnsByPlayerId,
        before.runtimeState.culturalVictoryHoldTurnsByPlayerId,
      );
      expect(
        expected.runtimeState.mapObjectiveHoldStatesByObjectiveId,
        before.runtimeState.mapObjectiveHoldStatesByObjectiveId,
      );
      expect(
        expected.runtimeState.resourceTradeAgreements.map(
          (agreement) => agreement.id,
        ),
        contains('combat_unrelated_trade'),
      );
      expect(
        expected.runtimeState.turnStartedAt,
        before.runtimeState.turnStartedAt,
      );
    }
  });

  test('all reachable standard rejection reasons pin precedence', () {
    final rejected = fixtureProvider()
        .where((fixture) => !fixture.expectedAccepted)
        .toList(growable: false);
    expect(rejected, hasLength(12));
    expect(rejected.map((fixture) => fixture.expectedReason), [
      'attacker_not_found',
      'attacker_not_controlled',
      'attacker_unavailable',
      'attacker_exhausted',
      'attacker_out_of_bounds',
      'attack_target_out_of_bounds',
      'attacker_cannot_attack',
      'attack_target_not_found',
      'attack_target_not_enemy',
      'attack_target_protected_by_treaty',
      'attack_target_not_visible',
      'attack_target_out_of_range',
    ]);
    for (final fixture in rejected) {
      expect(fixture.expectedState, fixture.state.toJson());
      expect(fixture.expectedEvents, isEmpty);
    }
  });

  test(
    'occupancy-sensitive reasons are only characterized on visible targets',
    () {
      final fixtures = fixtureProvider();
      for (final suffix in [
        'target-not-enemy-rejected',
        'target-protected-by-treaty-rejected',
      ]) {
        final fixture = _combatFixtureBySuffix(fixtures, suffix);
        final command = fixture.command as AttackHexCommand;
        expect(
          fixture.state.fogOfWar
              .fogForPlayer(fixture.actorPlayerId)
              .visibleHexes,
          contains(
            HexCoordinate(col: command.defenderCol, row: command.defenderRow),
          ),
          reason: fixture.id,
        );
      }

      final hidden = _combatFixtureBySuffix(
        fixtures,
        'target-not-visible-rejected',
      );
      final command = hidden.command as AttackHexCommand;
      expect(
        hidden.state.fogOfWar.fogForPlayer(hidden.actorPlayerId).visibleHexes,
        isNot(
          contains(
            HexCoordinate(col: command.defenderCol, row: command.defenderRow),
          ),
        ),
        reason: hidden.id,
      );
      expect(hidden.expectedReason, 'attack_target_not_visible');
    },
  );

  test('shared unit, garrison, retreat, and conquest outcomes are pinned', () {
    final fixtures = fixtureProvider();
    final unit = _combatFixtureBySuffix(fixtures, 'unit-accepted');
    expect(_combatEventTypes(unit), [
      'UnitAttacked',
      'CombatResolved',
      'UnitGainedExperience',
      'UnitGainedExperience',
    ]);
    final unitState = PersistentGameState.fromJson(unit.expectedState);
    expect(
      (
        unitState.units.byId('combat_attacker')?.hitPoints,
        unitState.units.byId('combat_defender')?.hitPoints,
      ),
      (7, 9),
    );

    final defended = _combatFixtureBySuffix(
      fixtures,
      'defended-city-unit-accepted',
    );
    expect(_combatEventTypes(defended), [
      'UnitAttacked',
      'CombatResolved',
      'UnitGainedExperience',
      'UnitKilled',
    ]);
    final defendedOutcome = _combatOutcomeJson(defended);
    expect(defendedOutcome['defenderKilled'], isTrue);
    expect(
      defendedOutcome['steps'],
      contains(
        containsPair(
          'modifier',
          containsPair('label', 'city.defended_city.garrison'),
        ),
      ),
    );

    final retreat = _combatFixtureBySuffix(fixtures, 'retreat-accepted');
    expect(_combatEventTypes(retreat), [
      'UnitAttacked',
      'CombatResolved',
      'UnitRetreated',
      'UnitGainedExperience',
      'UnitGainedExperience',
    ]);
    final retreatState = PersistentGameState.fromJson(retreat.expectedState);
    final retreated = retreatState.units.byId('retreat_defender');
    expect((retreated?.col, retreated?.row, retreated?.hitPoints), (1, 1, 1));

    final capture = _combatFixtureBySuffix(fixtures, 'city-capture-accepted');
    final captureState = PersistentGameState.fromJson(capture.expectedState);
    expect(_combatEventTypes(capture), [
      'CityAttacked',
      'CombatResolved',
      'UnitGainedExperience',
      'CityCaptured',
    ]);
    expect(captureState.cities.byId('capture_city')?.ownerPlayerId, 'player_1');
    expect(captureState.cities.byId('capture_city')?.hitPoints, 8);

    final destroy = _combatFixtureBySuffix(fixtures, 'city-destroy-accepted');
    final destroyState = PersistentGameState.fromJson(destroy.expectedState);
    expect(_combatEventTypes(destroy), [
      'CityAttacked',
      'CombatResolved',
      'UnitGainedExperience',
      'CityDestroyed',
    ]);
    expect(destroyState.cities.byId('destroy_city'), isNull);
    expect(
      destroyState.artifacts
          .singleWhere((artifact) => artifact.id == 'combat_stored_artifact')
          .location,
      const WorldArtifactLocation.map(col: 1, row: 0),
    );
  });
}

void _registerCombatIndependenceGuards() {
  test('combat expectation sources cannot call production calculators', () {
    final support = '${Directory.current.path}/test/support';
    final sources = [
      File('$support/reducer_parity_combat_characterization_cases.dart'),
      File('$support/reducer_parity_combat_characterization_fixture.dart'),
      File('$support/reducer_parity_combat_characterization_oracle.dart'),
    ];
    const forbidden = [
      'PersistentCombatCommandResolver',
      'PersistentTurnCombatResolver',
      'TurnCombatOrchestrator',
      'CombatReducer.',
      'CombatResolver',
      'CombatRng',
      'CombatModifierCollector',
      'UnitCombatStats',
      'UnitVeterancyRules',
      'FogOfWarService',
      'DiplomaticContact',
      'registerUnitAttack',
      'registerCityAttack',
      'GameStateReducer',
      'LocalCommandResolver',
      'ServerCommandReducer',
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
    expect(names, isNot(contains(startsWith('combat-characterization-'))));
  });
}

ReducerParityFixture _combatFixtureBySuffix(
  List<ReducerParityFixture> fixtures,
  String suffix,
) {
  return fixtures.singleWhere(
    (fixture) => fixture.id == 'combat-characterization-$suffix',
  );
}

List<String?> _combatEventTypes(ReducerParityFixture fixture) {
  return [for (final event in fixture.expectedEvents) event['type'] as String?];
}

Map<String, dynamic> _combatOutcomeJson(ReducerParityFixture fixture) {
  return fixture.expectedEvents.singleWhere(
        (event) => event['type'] == 'CombatResolved',
      )['outcome']
      as Map<String, dynamic>;
}

List<ReducerParityFixture> _replaceCombatFixture(
  List<ReducerParityFixture> fixtures,
  ReducerParityFixture source,
  ReducerParityFixture replacement,
) {
  return [
    for (final fixture in fixtures)
      if (identical(fixture, source)) replacement else fixture,
  ];
}

ReducerParityFixture _copyCombatFixture(
  ReducerParityFixture source, {
  bool? expectedAccepted,
  Object? expectedReason = _combatUnchanged,
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
    expectedReason: identical(expectedReason, _combatUnchanged)
        ? source.expectedReason
        : expectedReason as String?,
    expectedSave: source.expectedSave,
    expectedState: expectedState ?? source.expectedState,
    expectedEvents: expectedEvents ?? source.expectedEvents,
  );
}

const _combatUnchanged = Object();
