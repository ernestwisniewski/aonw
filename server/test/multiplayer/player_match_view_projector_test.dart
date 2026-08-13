import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/lossless_match_snapshot_codec.dart';
import 'package:aonw_server/src/multiplayer/player_match_event_audience.dart';
import 'package:aonw_server/src/multiplayer/player_match_view_projector.dart';
import 'package:test/test.dart';

import 'support/player_match_view_projection_fixture.dart';

part 'support/player_match_view_projection_guard_cases.dart';

void main() {
  const projector = PlayerMatchViewProjector();
  const owner = MatchRecipient(
    userIdentifier: 'owner-auth-id',
    playerId: 'player-owner',
  );
  const guest = MatchRecipient(
    userIdentifier: 'guest-auth-id',
    playerId: 'player-guest',
  );

  test('redacts account identifiers and private invite codes from matches', () {
    final canonical = _match();

    final ownerView = projector.matchFor(
      canonical,
      userIdentifier: owner.userIdentifier,
    );
    final guestView = projector.matchFor(
      canonical,
      userIdentifier: 'guest-auth-id',
    );

    expect(ownerView.ownerUserId, owner.userIdentifier);
    expect(ownerView.inviteCode, 'SECRET-CODE');
    expect(ownerView.players.map((player) => player.userId), [
      owner.userIdentifier,
      'player-guest',
    ]);
    expect(guestView.ownerUserId, 'player-owner');
    expect(guestView.inviteCode, isNull);
    expect(guestView.players.map((player) => player.userId), [
      'player-owner',
      'guest-auth-id',
    ]);
    expect(guestView.toJson().toString(), isNot(contains('owner-auth-id')));
  });

  test('projects a fail-closed player-visible snapshot', () {
    final canonical = playerMatchViewProjectionFixture;
    final canonicalJson = canonical.toJson().toString();

    final projected = projector.snapshotFor(canonical, owner);
    final projectedGuest = projector.snapshotFor(canonical, guest);
    final save = GameSave.fromJson(projected.save);
    final state = CanonicalGameSnapshotCodec.decodeDomainState(projected.state);
    final guestState = CanonicalGameSnapshotCodec.decodeDomainState(
      projectedGuest.state,
    );

    _expectPublicSave(save);
    _expectOwnerRuleProjection(state);
    _expectOwnerRuntimeProjection(state);
    _expectGuestProjection(guestState);
    _expectProjectionSecrecy(
      canonical: canonical,
      canonicalJson: canonicalJson,
      projected: projected,
      projectedGuest: projectedGuest,
    );
  });

  test('projects only recipient events and command acknowledgements', () {
    final snapshot = playerMatchViewProjectionFixture;
    final state = CanonicalGameSnapshotCodec.decodeDomainState(snapshot.state);
    final storedEvents = PlayerMatchEventAudience.annotateForStorage(
      events: const [
        TechnologyResearchedEvent(
          playerId: 'player-owner',
          technologyId: TechnologyId.agriculture,
        ),
        DiplomaticMessageSentEvent(
          messageId: 'message-1',
          fromPlayerId: 'player-guest',
          toPlayerId: 'player-owner',
          topic: DiplomaticMessageTopic.troopsNearCities,
          category: DiplomaticMessageCategory.warning,
          expiresOnTurn: 5,
        ),
        StrategicResourceDiscoveredEvent(
          playerId: 'player-guest',
          resourceType: ResourceType.uranium,
          controlledCount: 1,
          rivalControlledCount: 0,
          unclaimedCount: 0,
          pressure: StrategicResourceDiscoveryPressure.securedSupply,
        ),
      ],
      participantPlayerIds: const ['player-owner', 'player-guest'],
      previous: GameEventOwnershipIndex.from(state.units, state.cities),
      next: GameEventOwnershipIndex.from(state.units, state.cities),
    );
    final ownEvent = WireEvent(
      matchId: snapshot.matchId,
      offset: 7,
      timestamp: DateTime.utc(2026, 7, 10),
      actorPlayerId: owner.playerId,
      tick: 3,
      turn: 5,
      command: const {'type': 'own-command', 'secret': 'actor-secret'},
      events: storedEvents,
      movementExecutions: WireMovementExecutionList(const []),
    );
    final otherEvent = ownEvent.copyWith(
      actorPlayerId: 'player-guest',
      command: const {'type': 'guest-secret-command'},
    );

    final projectedOwn = projector.eventFor(ownEvent, owner);
    final projectedOther = projector.eventFor(otherEvent, owner);
    final ack = projector.ackFor(
      WireCommandAck(
        matchId: snapshot.matchId,
        clientMessageId: 'command-1',
        accepted: true,
        offset: 7,
        tick: ownEvent.tick,
        timestamp: ownEvent.timestamp,
        snapshot: snapshot,
        events: ownEvent.events,
        movementExecutions: WireMovementExecutionList(const []),
      ),
      owner,
    );

    expect(projectedOwn.command?['type'], 'own-command');
    expect(projectedOwn.events, hasLength(2));
    expect(projectedOwn.events.map((event) => event['type']), [
      'TechnologyResearched',
      'DiplomaticMessageSent',
    ]);
    expect(
      projectedOwn.events.expand((event) => event.keys),
      isNot(contains('_serverAudiencePlayerIds')),
    );
    expect(projectedOther.actorPlayerId, 'player-guest');
    expect(ack.tick, ownEvent.tick);
    expect(ack.clientMessageId, 'command-1');
    expect(ack.timestamp, ownEvent.timestamp);
    expect(projectedOther.tick, isNull);
    expect(projectedOther.turn, 5);
    expect(projectedOther.command, isNull);
    expect(projectedOther.events, hasLength(2));
    expect(ack.events, hasLength(2));
    expect(GameSave.fromJson(ack.snapshot.save).origin, GameSaveOrigin.network);
    expect(
      CanonicalGameSnapshotCodec.decodeDomainState(
        ack.snapshot.state,
      ).playerGold,
      {'player-owner': 111},
    );

    final guestOnlyEvent = ownEvent.copyWith(
      actorPlayerId: 'player-guest',
      command: const {'type': 'guest-secret-command'},
      events: PlayerMatchEventAudience.annotateForStorage(
        events: const [
          StrategicResourceDiscoveredEvent(
            playerId: 'player-guest',
            resourceType: ResourceType.uranium,
            controlledCount: 1,
            rivalControlledCount: 0,
            unclaimedCount: 0,
            pressure: StrategicResourceDiscoveryPressure.securedSupply,
          ),
        ],
        participantPlayerIds: const ['player-owner', 'player-guest'],
        previous: GameEventOwnershipIndex.from(state.units, state.cities),
        next: GameEventOwnershipIndex.from(state.units, state.cities),
      ),
    );
    final redactedGuestOnly = projector.eventFor(guestOnlyEvent, owner);
    expect(redactedGuestOnly.actorPlayerId, isNull);
    expect(redactedGuestOnly.command, isNull);
    expect(redactedGuestOnly.events, isEmpty);
  });

  test('allows only explicit lifecycle fields in lobby snapshots', () {
    final projected = projector.snapshotFor(
      const WireSnapshot(
        matchId: 'match-1',
        offset: 0,
        save: {},
        state: {
          'phase': 'lobby',
          'mapName': 'test-map',
          'leftUserIdentifier': 'raw-auth-id',
        },
      ),
      owner,
    );

    expect(projected.state, {'phase': 'lobby', 'mapName': 'test-map'});
  });

  _registerPlayerMatchProjectionGuardTests(
    projector: projector,
    owner: owner,
    guest: guest,
  );
}

void _expectPublicSave(GameSave save) {
  expect(save.camera, CameraState.zero);
  expect(save.players.last.ai?.seed, 0);
  expect(save.origin, GameSaveOrigin.network);
}

void _expectOwnerRuleProjection(DomainState state) {
  expect(state.playerColors, {
    'player-owner': 1,
    'player-guest': 2,
    'player-ai': 3,
  });
  expect(state.playerCountries, {
    'player-owner': PlayerCountry.poland,
    'player-guest': PlayerCountry.france,
    'player-ai': PlayerCountry.germany,
  });
  expect(state.playerGold, {'player-owner': 111});
  expect(state.playerWarWeariness, {'player-owner': 3});
  expect(state.playerStabilityNet, {'player-owner': 4});
  expect(state.strategicResources.byPlayerId.keys, ['player-owner']);
  expect(
    state.strategicResources
        .forPlayer('player-owner')
        .amountFor(ResourceType.oil),
    2,
  );
  expect(state.initialResourceDistribution.placements, const [
    InitialResourcePlacement(col: 3, row: 4, resource: ResourceType.marble),
  ]);
  expect(state.fogOfWar.playerIds, ['player-owner']);
  expect(state.research.players.keys, ['player-owner']);
  expect(state.units.map((unit) => unit.id), [
    'own-unit',
    'visible-enemy-unit',
  ]);
  final visibleEnemy = state.units.last;
  expect(visibleEnemy.movementPoints, 0);
  expect(visibleEnemy.army, isEmpty);
  expect(visibleEnemy.queuedPath, isNull);
  expect(visibleEnemy.experiencePoints, 0);
  expect(state.cities.map((city) => city.id), [
    'own-city',
    'visible-enemy-city',
  ]);
  final visibleEnemyCity = state.cities.last;
  expect(visibleEnemyCity.storedFood, GameCity.defaultStartStoredFood);
  expect(visibleEnemyCity.buildings, isEmpty);
  expect(visibleEnemyCity.productionQueue, isNull);
  expect(visibleEnemyCity.productionOverflow, 0);
  expect(visibleEnemyCity.controlledHexes, [const CityHex(col: 2, row: 3)]);
  expect(state.fieldImprovements, hasLength(2));
  expect(state.fieldImprovements.last.builtByCityId, isNull);
  expect(
    state.transportNetwork.segments.map((segment) => segment.hex).toSet(),
    {const HexCoord(col: 7, row: 7), const HexCoord(col: 4, row: 4)},
  );
  expect(state.artifacts.map((artifact) => artifact.id), [
    'visible-artifact',
    'own-carried-artifact',
  ]);
  expect(state.wonderRegistry.ownerOf(WonderType.greatLibrary), 'player-owner');
}

void _expectOwnerRuntimeProjection(DomainState state) {
  final runtime = state;
  expect(runtime.actions.cityFoundingDraft, isNull);
  expect(runtime.actions.pendingAction, isNull);
  expect(runtime.submittedPlayerIds, {'player-owner', 'player-guest'});
  expect(runtime.timeoutStreaksByPlayerId, {'player-owner': 1});
  expect(runtime.afkPlayerIds, {'player-guest'});
  expect(runtime.kickedPlayerIds, {'player-ai'});
  expect(runtime.turnStartedAt, DateTime.utc(2026, 7, 10));
  expect(runtime.intendedAttacks, hasLength(1));
  expect(runtime.intendedAttacks.single.declaringPlayerId, 'player-owner');
  expect(runtime.diplomacy.relations.keys, {
    DiplomacyState.relationKey('player-owner', 'player-guest'),
  });
  expect(runtime.diplomacy.contactKeys, {
    DiplomacyState.relationKey('player-owner', 'player-guest'),
    DiplomacyState.relationKey('player-owner', 'player-ai'),
  });
  expect(runtime.diplomacy.pendingProposals.keys, {'owner-proposal'});
  expect(runtime.diplomacy.messages.keys, {'owner-message'});
  expect(
    runtime.diplomacy.scoreHistory.values
        .expand((scores) => scores)
        .map((score) => score.sourceId),
    unorderedEquals({'shared-score', 'owner-secret-score'}),
  );
  expect(runtime.dominationHoldTurnsByPlayerId, {'player-owner': 2});
  expect(runtime.culturalVictoryHoldTurnsByPlayerId, {'player-owner': 3});
  expect(runtime.mapObjectiveHoldStatesByObjectiveId.keys, ['objective-own']);
  expect(runtime.resourceTradeAgreements, hasLength(1));
}

void _expectGuestProjection(DomainState state) {
  final runtime = state;
  expect(state.strategicResources.byPlayerId.keys, ['player-guest']);
  expect(
    state.strategicResources
        .forPlayer('player-guest')
        .amountFor(ResourceType.aluminium),
    1,
  );
  expect(state.initialResourceDistribution.placements, const [
    InitialResourcePlacement(col: 3, row: 4, resource: ResourceType.marble),
  ]);
  expect(
    runtime.transportNetwork.segments.map((segment) => segment.hex).toSet(),
    {const HexCoord(col: 4, row: 4), const HexCoord(col: 6, row: 6)},
  );
  expect(runtime.actions.cityFoundingDraft?.ownerPlayerId, 'player-guest');
  expect(runtime.actions.pendingAction, isA<PendingResearchSelection>());
  expect(runtime.timeoutStreaksByPlayerId, {'player-guest': 9});
  expect(runtime.intendedAttacks, hasLength(1));
  expect(runtime.dominationHoldTurnsByPlayerId, {'player-guest': 8});
  expect(runtime.culturalVictoryHoldTurnsByPlayerId, {'player-guest': 7});
  expect(runtime.diplomacy.relations.keys, {
    DiplomacyState.relationKey('player-owner', 'player-guest'),
    DiplomacyState.relationKey('player-guest', 'player-ai'),
  });
  expect(runtime.diplomacy.contactKeys, {
    DiplomacyState.relationKey('player-owner', 'player-guest'),
    DiplomacyState.relationKey('player-guest', 'player-ai'),
  });
  expect(runtime.diplomacy.pendingProposals.keys, {'guest-secret-proposal'});
  expect(runtime.diplomacy.messages.keys, {'guest-secret-message'});
}

void _expectProjectionSecrecy({
  required WireSnapshot canonical,
  required String canonicalJson,
  required WireSnapshot projected,
  required WireSnapshot projectedGuest,
}) {
  expect(projected.state['reason'], 'owner_left');
  expect(projected.state, isNot(contains('leftUserIdentifier')));
  expect(canonical.toJson().toString(), canonicalJson);
  expect(canonical.state.toString(), contains('hidden-enemy-unit'));
  expect(projected.state.toString(), isNot(contains('hidden-enemy-unit')));
  expect(projected.state.toString(), isNot(contains('guest-secret')));
  expect(projectedGuest.state.toString(), isNot(contains('owner-proposal')));
  expect(projectedGuest.state.toString(), isNot(contains('owner-message')));
  expect(
    projectedGuest.state.toString(),
    isNot(contains('owner-secret-score')),
  );
}

WireMatch _match() {
  return WireMatch(
    id: 'match-1',
    ownerUserId: 'owner-auth-id',
    name: 'Private match',
    mapName: 'test-map',
    players: [
      _wirePlayer(id: 'player-owner', userId: 'owner-auth-id', name: 'Owner'),
      _wirePlayer(id: 'player-guest', userId: 'guest-auth-id', name: 'Guest'),
    ],
    turn: 1,
    state: 'running',
    createdAt: DateTime.utc(2026, 7, 10),
    inviteCode: 'SECRET-CODE',
  );
}

WirePlayer _wirePlayer({
  required String id,
  required String userId,
  required String name,
}) => WirePlayer(
  id: id,
  userId: userId,
  name: name,
  colorValue: 1,
  kind: WirePlayerKind.human,
  connectionState: WirePlayerConnectionState.connected,
);
