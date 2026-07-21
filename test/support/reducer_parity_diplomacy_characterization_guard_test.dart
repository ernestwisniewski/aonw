import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reducer_parity_diplomacy_characterization.dart';
import 'reducer_parity_fixture.dart';
import 'reducer_parity_resource_trade_characterization.dart';

void main() {
  late List<ReducerParityFixture> fixtures;

  setUpAll(() {
    fixtures = DiplomacyReducerParityCharacterization.extend(
      ResourceTradeReducerParityCharacterization.extend(
        ReducerParityCorpus.load(Directory.current),
      ),
    ).where((fixture) => fixture.family == 'diplomacy').toList();
  });

  _registerCorpusContractGuards(() => fixtures);
  _registerSentinelGuards(() => fixtures);
  _registerMultiEffectGuards(() => fixtures);
  _registerGeneratedIdGuards(() => fixtures);
}

typedef _FixtureProvider = List<ReducerParityFixture> Function();

void _registerCorpusContractGuards(_FixtureProvider fixtureProvider) {
  test('diplomacy corpus has exactly 39 reviewed wire-safe cases', () {
    final fixtures = fixtureProvider();
    expect(fixtures, hasLength(39));
    expect(
      () => DiplomacyReducerParityCharacterization.validateForTest(fixtures),
      returnsNormally,
    );
    for (final fixture in fixtures) {
      final encoded = GameCommandSerializer.toJson(fixture.command);
      expect(GameCommandSerializer.fromJson(encoded), fixture.command);
    }
  });

  test('diplomacy corpus fails closed when one reviewed case is removed', () {
    final fixtures = fixtureProvider();
    expect(
      () => DiplomacyReducerParityCharacterization.validateForTest(
        fixtures.sublist(1),
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

  test('diplomacy corpus fails closed when a mode drifts', () {
    final fixtures = fixtureProvider();
    final source = fixtures.singleWhere(
      (fixture) =>
          fixture.id == 'diplomacy-characterization-gift-transfer-accepted',
    );
    final drifted = _replace(
      fixtures,
      source,
      command: const DeclareWarCommand(
        playerId: 'player_1',
        targetPlayerId: 'player_2',
      ),
    );

    expect(
      () => DiplomacyReducerParityCharacterization.validateForTest(drifted),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('characterization drifted'),
        ),
      ),
    );
  });

  test('diplomacy corpus fails closed when acceptance or reason drifts', () {
    final fixtures = fixtureProvider();
    final source = fixtures.singleWhere(
      (fixture) => fixture.id.endsWith('war-target-rejected'),
    );
    for (final driftedFixture in [
      _copyFixture(source, expectedAccepted: true, expectedReason: null),
      _copyFixture(source, expectedReason: 'different_reason'),
    ]) {
      expect(
        () => DiplomacyReducerParityCharacterization.validateForTest(
          _replace(fixtures, source, replacement: driftedFixture),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('characterization drifted'),
          ),
        ),
      );
    }
  });
}

void _registerSentinelGuards(_FixtureProvider fixtureProvider) {
  test('every case carries unrelated state sentinels through its oracle', () {
    final fixtures = fixtureProvider();
    for (final fixture in fixtures) {
      final expected = PersistentGameState.fromJson(fixture.expectedState);
      expect(fixture.state.units, hasLength(3), reason: fixture.id);
      expect(expected.units, fixture.state.units, reason: fixture.id);
      expect(expected.cities, fixture.state.cities, reason: fixture.id);
      expect(expected.fogOfWar, fixture.state.fogOfWar, reason: fixture.id);
      expect(expected.research, fixture.state.research, reason: fixture.id);
      expect(
        expected.playerGold['player_3'],
        fixture.state.playerGold['player_3'],
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
        expected.runtimeState.mapObjectiveHoldStatesByObjectiveId,
        fixture.state.runtimeState.mapObjectiveHoldStatesByObjectiveId,
        reason: fixture.id,
      );
      expect(
        expected.runtimeState.intendedAttacks.map(
          (attack) => attack.attackerUnitId,
        ),
        containsAll(const ['warrior_player_1', 'missing_attacker']),
        reason: fixture.id,
      );
      expect(
        expected.runtimeState.resourceTradeAgreements.map(
          (agreement) => agreement.id,
        ),
        contains('sentinel_observer_trade'),
        reason: fixture.id,
      );
      expect(
        expected.runtimeState.diplomacy.pendingProposals,
        contains('sentinel_proposal'),
        reason: fixture.id,
      );
      expect(
        expected.runtimeState.diplomacy.messages,
        contains('sentinel_message'),
        reason: fixture.id,
      );
    }
  });
}

void _registerMultiEffectGuards(_FixtureProvider fixtureProvider) {
  test(
    'reviewed multi-effect cases pin selective removals and event order',
    () {
      final fixtures = fixtureProvider();
      final friendship = _fixture(
        fixtures,
        'proposal-response-friendship-accepted',
      );
      final friendshipState = PersistentGameState.fromJson(
        friendship.expectedState,
      );
      expect(
        friendshipState.runtimeState.intendedAttacks.map(
          (attack) => attack.declaredAtTick,
        ),
        [43, 44],
      );
      expect(_eventTypes(friendship), [
        'DiplomaticProposalResponded',
        'DiplomaticRelationChanged',
        'DiplomaticScoreChanged',
      ]);

      final war = _fixture(fixtures, 'war-selective-effects-accepted');
      final warState = PersistentGameState.fromJson(war.expectedState);
      expect(
        warState.runtimeState.resourceTradeAgreements.map(
          (agreement) => agreement.id,
        ),
        ['sentinel_observer_trade'],
      );
      expect(warState.runtimeState.diplomacy.pendingProposals.keys, [
        'sentinel_proposal',
      ]);
      expect(_eventTypes(war), [
        'DiplomaticRelationChanged',
        'DiplomaticScoreChanged',
        'DiplomaticScoreChanged',
      ]);

      final paidTruce = _fixture(
        fixtures,
        'proposal-response-paid-truce-accepted',
      );
      final truceState = PersistentGameState.fromJson(paidTruce.expectedState);
      expect(truceState.playerGold['player_1'], 10);
      expect(truceState.playerGold['player_2'], 30);
    },
  );
}

void _registerGeneratedIdGuards(_FixtureProvider fixtureProvider) {
  test('generated proposal and message ids are not supplied by commands', () {
    final fixtures = fixtureProvider();
    final generated = fixtures.where(
      (fixture) => fixture.id.contains('generated-id-accepted'),
    );
    expect(generated, hasLength(2));
    for (final fixture in generated) {
      final id = switch (fixture.command) {
        SendDiplomaticProposalCommand(:final proposalId) => proposalId,
        SendDiplomaticMessageCommand(:final messageId) => messageId,
        _ => 'unexpected',
      };
      expect(id, isNull, reason: fixture.id);
    }
  });
}

List<ReducerParityFixture> _replace(
  List<ReducerParityFixture> fixtures,
  ReducerParityFixture source, {
  GameCommand? command,
  ReducerParityFixture? replacement,
}) {
  final next = replacement ?? _copyFixture(source, command: command);
  return [
    for (final fixture in fixtures)
      if (identical(fixture, source)) next else fixture,
  ];
}

ReducerParityFixture _copyFixture(
  ReducerParityFixture source, {
  GameCommand? command,
  bool? expectedAccepted,
  Object? expectedReason = _unchanged,
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
    command: command ?? source.command,
    expectedAccepted: expectedAccepted ?? source.expectedAccepted,
    expectedReason: identical(expectedReason, _unchanged)
        ? source.expectedReason
        : expectedReason as String?,
    expectedSave: source.expectedSave,
    expectedState: source.expectedState,
    expectedEvents: source.expectedEvents,
  );
}

const _unchanged = Object();

ReducerParityFixture _fixture(
  List<ReducerParityFixture> fixtures,
  String idSuffix,
) {
  return fixtures.singleWhere((fixture) => fixture.id.endsWith(idSuffix));
}

List<Object?> _eventTypes(ReducerParityFixture fixture) {
  return fixture.expectedEvents.map((event) => event['type']).toList();
}
