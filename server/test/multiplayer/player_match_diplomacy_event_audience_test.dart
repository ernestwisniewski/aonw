import 'dart:convert';

import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/player_match_event_audience.dart';
import 'package:aonw_server/src/multiplayer/player_match_view_projector.dart';
import 'package:test/test.dart';

void main() {
  test(
    'projects accepted friendship events exactly once without mutating storage',
    () {
      final fixture = _projectAcceptedFriendship();

      _expectExactRecipientViews(fixture);
      _expectProjectionImmutability(fixture);
    },
  );
}

typedef _FriendshipProjectionFixture = ({
  CanonicalGameSnapshot source,
  GameEngineAccepted accepted,
  List<Map<String, dynamic>> stored,
  String sourceDiplomacyBeforeProjection,
  String resultDiplomacyBeforeProjection,
  String storedBeforeProjection,
  List<Map<String, dynamic>> engineEventsBeforeProjection,
  ProjectedWireEvent owner,
  ProjectedWireEvent guest,
  ProjectedWireEvent hidden,
});

_FriendshipProjectionFixture _projectAcceptedFriendship() {
  final source = _diplomacySnapshot();
  final result = const GameEngine().apply(
    snapshot: source,
    command: const RespondDiplomaticProposalCommand(
      playerId: 'player-2',
      proposalId: 'proposal-1',
      accepted: true,
    ),
    context: GameEngineContext(
      actorPlayerId: 'player-2',
      mapView: _map,
      ruleset: GameRuleset.defaults,
      commandTick: 9,
    ),
  );
  expect(result, isA<GameEngineAccepted>());
  final accepted = result as GameEngineAccepted;
  final stored = PlayerMatchEventAudience.annotateForStorage(
    events: accepted.events,
    participantPlayerIds: const ['player-1', 'player-2', 'hidden'],
    previous: GameEventOwnershipIndex.empty,
    next: GameEventOwnershipIndex.empty,
  );
  for (var index = 0; index < stored.length; index += 1) {
    stored[index]['_storageOnlyTestMarker'] = 'row-$index';
  }
  final canonicalEvent = _storedWireEvent(stored);
  const projector = PlayerMatchViewProjector();

  return (
    source: source,
    accepted: accepted,
    stored: stored,
    sourceDiplomacyBeforeProjection: jsonEncode(
      source.domain.diplomacy.toJson(),
    ),
    resultDiplomacyBeforeProjection: jsonEncode(
      accepted.snapshot.domain.diplomacy.toJson(),
    ),
    storedBeforeProjection: jsonEncode(stored),
    engineEventsBeforeProjection: [
      for (final event in accepted.events) GameEventSerializer.toJson(event),
    ],
    owner: projector.eventFor(canonicalEvent, _owner),
    guest: projector.eventFor(canonicalEvent, _guest),
    hidden: projector.eventFor(canonicalEvent, _hidden),
  );
}

WireEvent _storedWireEvent(List<Map<String, dynamic>> stored) {
  return WireEvent(
    matchId: 'diplomacy-audience',
    offset: 12,
    timestamp: DateTime.utc(2026, 7, 30, 12),
    actorPlayerId: 'player-2',
    tick: 9,
    turn: 5,
    command: DomainCommandCodec.toJson(
      const RespondDiplomaticProposalCommand(
        playerId: 'player-2',
        proposalId: 'proposal-1',
        accepted: true,
      ),
    ),
    events: stored,
    movementExecutions: WireMovementExecutionList(const []),
  );
}

void _expectExactRecipientViews(_FriendshipProjectionFixture fixture) {
  final owner = fixture.owner;
  final guest = fixture.guest;
  final hidden = fixture.hidden;
  expect(owner.events, _expectedFriendshipEvents);
  expect(guest.events, _expectedFriendshipEvents);
  expect(owner.actorPlayerId, 'player-2');
  expect(owner.tick, isNull);
  expect(owner.command, isNull);
  expect(guest.actorPlayerId, 'player-2');
  expect(guest.tick, 9);
  expect(guest.command, const {
    'type': 'RespondDiplomaticProposal',
    'playerId': 'player-2',
    'proposalId': 'proposal-1',
    'accepted': true,
  });
  expect(hidden.events, isEmpty);
  expect(hidden.command, isNull);
  expect(hidden.actorPlayerId, isNull);
  expect(hidden.tick, isNull);
  expect(hidden.movementExecutions.isEmpty, isTrue);
  expect(
    jsonEncode(hidden.toJson()),
    allOf(
      isNot(contains('Diplomatic')),
      isNot(contains('proposal-1')),
      isNot(contains('player-1')),
      isNot(contains('player-2')),
      isNot(contains('_serverAudience')),
    ),
  );
}

void _expectProjectionImmutability(_FriendshipProjectionFixture fixture) {
  expect(jsonEncode(fixture.stored), fixture.storedBeforeProjection);
  expect(
    jsonEncode(fixture.source.domain.diplomacy.toJson()),
    fixture.sourceDiplomacyBeforeProjection,
  );
  expect(
    jsonEncode(fixture.accepted.snapshot.domain.diplomacy.toJson()),
    fixture.resultDiplomacyBeforeProjection,
  );
  expect(
    fixture.accepted.events.map(GameEventSerializer.toJson),
    fixture.engineEventsBeforeProjection,
  );
}

CanonicalGameSnapshot _diplomacySnapshot() {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 5,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: 'player-1', name: 'One', colorValue: 1),
        Player(id: 'player-2', name: 'Two', colorValue: 2),
        Player(id: 'hidden', name: 'Hidden', colorValue: 3),
      ],
      diplomacy: DiplomacyState.empty
          .addContact('player-1', 'player-2')
          .addProposal(
            const DiplomaticProposal(
              id: 'proposal-1',
              fromPlayerId: 'player-1',
              toPlayerId: 'player-2',
              kind: DiplomaticProposalKind.friendship,
              createdTurn: 4,
              expiresOnTurn: 9,
            ),
          ),
    ),
    session: MatchSessionState.snapshot(
      gameMode: GameMode.multiplayer,
      turnStatesByPlayerId: const {
        'player-1': PlayerTurnState.active,
        'player-2': PlayerTurnState.active,
        'hidden': PlayerTurnState.active,
      },
    ),
    metadata: GameSnapshotMetadata(
      id: 'diplomacy-audience',
      schemaVersion: 3,
      name: 'Diplomacy audience',
      world: const WorldReference(name: 'test', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 30),
      camera: GameSnapshotCamera.zero,
    ),
  );
}

const _owner = MatchRecipient(
  userIdentifier: 'owner-user',
  playerId: 'player-1',
);
const _guest = MatchRecipient(
  userIdentifier: 'guest-user',
  playerId: 'player-2',
);
const _hidden = MatchRecipient(
  userIdentifier: 'hidden-user',
  playerId: 'hidden',
);
const _expectedFriendshipEvents = <Map<String, dynamic>>[
  {
    'type': 'DiplomaticProposalResponded',
    'proposalId': 'proposal-1',
    'fromPlayerId': 'player-1',
    'toPlayerId': 'player-2',
    'kind': 'friendship',
    'accepted': true,
  },
  {
    'type': 'DiplomaticRelationChanged',
    'playerAId': 'player-1',
    'playerBId': 'player-2',
    'oldStatus': 'neutral',
    'newStatus': 'friendly',
    'reason': 'proposalAccepted',
  },
  {
    'type': 'DiplomaticScoreChanged',
    'playerAId': 'player-1',
    'playerBId': 'player-2',
    'delta': 18,
    'scoreAfter': 18,
    'reason': 'proposalAccepted',
    'sourceId': 'proposal-1',
  },
];

final _map = WorldMapReadView(
  WorldMap(
    cols: 1,
    rows: 1,
    tiles: [
      WorldTile(
        coordinate: const HexCoord(col: 0, row: 0),
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
    ],
  ),
);
