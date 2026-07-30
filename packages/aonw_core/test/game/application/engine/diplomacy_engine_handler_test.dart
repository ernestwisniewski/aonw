import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';
const _hiddenPlayerId = 'player_3';

void main() {
  group('diplomacy engine handler', () {
    test('sends a proposal with exact canonical event order', () {
      final snapshot = _snapshot();

      final result = _apply(
        snapshot,
        const SendDiplomaticProposalCommand(
          playerId: _playerId,
          targetPlayerId: _otherPlayerId,
          kind: DiplomaticProposalKind.friendship,
          proposalId: 'proposal_1',
        ),
      );

      final accepted = _expectAccepted(result);
      expect(accepted.snapshot.domain.diplomacy.pendingProposals.keys, [
        'proposal_1',
      ]);
      expect(accepted.events.map(GameEventSerializer.toJson), [
        {
          'type': 'DiplomaticProposalSent',
          'proposalId': 'proposal_1',
          'fromPlayerId': _playerId,
          'toPlayerId': _otherPlayerId,
          'kind': 'friendship',
          'expiresOnTurn': 10,
        },
      ]);
      expect(
        accepted.snapshot.domain.playerGold,
        same(snapshot.domain.playerGold),
      );
      expect(
        accepted.snapshot.domain.intendedAttacks,
        same(snapshot.domain.intendedAttacks),
      );
      expect(accepted.snapshot.session, same(snapshot.session));
      expect(accepted.snapshot.metadata, same(snapshot.metadata));
      expect(accepted.snapshot.interaction, same(snapshot.interaction));
      expect(accepted.snapshot.eventLogOffset, snapshot.eventLogOffset);
    });

    test('responds with exact ordered relation and score events', () {
      final snapshot = _snapshot(
        diplomacy: DiplomacyState.empty
            .addContact(_playerId, _otherPlayerId)
            .addProposal(
              const DiplomaticProposal(
                id: 'proposal_1',
                fromPlayerId: _playerId,
                toPlayerId: _otherPlayerId,
                kind: DiplomaticProposalKind.friendship,
                createdTurn: 4,
                expiresOnTurn: 9,
              ),
            ),
      );

      final result = _apply(
        snapshot,
        const RespondDiplomaticProposalCommand(
          playerId: _otherPlayerId,
          proposalId: 'proposal_1',
          accepted: true,
        ),
        actorPlayerId: _otherPlayerId,
      );

      final accepted = _expectAccepted(result);
      expect(accepted.events.map(GameEventSerializer.toJson), [
        {
          'type': 'DiplomaticProposalResponded',
          'proposalId': 'proposal_1',
          'fromPlayerId': _playerId,
          'toPlayerId': _otherPlayerId,
          'kind': 'friendship',
          'accepted': true,
        },
        {
          'type': 'DiplomaticRelationChanged',
          'playerAId': _playerId,
          'playerBId': _otherPlayerId,
          'oldStatus': 'neutral',
          'newStatus': 'friendly',
          'reason': 'proposalAccepted',
        },
        {
          'type': 'DiplomaticScoreChanged',
          'playerAId': _playerId,
          'playerBId': _otherPlayerId,
          'delta': 18,
          'scoreAfter': 18,
          'reason': 'proposalAccepted',
          'sourceId': 'proposal_1',
        },
      ]);
      expect(
        () => accepted.events.add(
          const DiplomaticProposalRespondedEvent(
            proposalId: 'unexpected',
            fromPlayerId: _playerId,
            toPlayerId: _otherPlayerId,
            kind: DiplomaticProposalKind.friendship,
            accepted: false,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects an actor mismatch with input snapshot identity', () {
      final snapshot = _snapshot();

      final result = _apply(
        snapshot,
        const SendGoldGiftCommand(
          playerId: _playerId,
          targetPlayerId: _otherPlayerId,
          amount: 10,
        ),
        actorPlayerId: _otherPlayerId,
      );

      _expectRejected(result, snapshot, 'diplomacy_player_not_controlled');
    });

    test('rejects an undiscovered recipient without leaking state', () {
      final snapshot = _snapshot(diplomacy: DiplomacyState.empty);

      final result = _apply(
        snapshot,
        const SendDiplomaticMessageCommand(
          playerId: _playerId,
          targetPlayerId: _hiddenPlayerId,
          topic: DiplomaticMessageTopic.troopsNearCities,
          messageId: 'hidden_message',
        ),
      );

      _expectRejected(result, snapshot, 'diplomacy_target_not_discovered');
    });
  });

  test('all six diplomacy player-wire JSON shapes remain exact', () {
    const cases = <(DomainCommand, Map<String, dynamic>)>[
      (
        SendDiplomaticProposalCommand(
          playerId: _playerId,
          targetPlayerId: _otherPlayerId,
          kind: DiplomaticProposalKind.truce,
          proposalId: 'proposal_1',
          goldPayment: 4,
        ),
        {
          'type': 'SendDiplomaticProposal',
          'playerId': _playerId,
          'targetPlayerId': _otherPlayerId,
          'kind': 'truce',
          'proposalId': 'proposal_1',
          'goldPayment': 4,
        },
      ),
      (
        RespondDiplomaticProposalCommand(
          playerId: _otherPlayerId,
          proposalId: 'proposal_1',
          accepted: true,
        ),
        {
          'type': 'RespondDiplomaticProposal',
          'playerId': _otherPlayerId,
          'proposalId': 'proposal_1',
          'accepted': true,
        },
      ),
      (
        DeclareWarCommand(playerId: _playerId, targetPlayerId: _otherPlayerId),
        {
          'type': 'DeclareWar',
          'playerId': _playerId,
          'targetPlayerId': _otherPlayerId,
        },
      ),
      (
        SendGoldGiftCommand(
          playerId: _playerId,
          targetPlayerId: _otherPlayerId,
          amount: 7,
        ),
        {
          'type': 'SendGoldGift',
          'playerId': _playerId,
          'targetPlayerId': _otherPlayerId,
          'amount': 7,
        },
      ),
      (
        SendDiplomaticMessageCommand(
          playerId: _playerId,
          targetPlayerId: _otherPlayerId,
          topic: DiplomaticMessageTopic.troopsNearCities,
          messageId: 'message_1',
        ),
        {
          'type': 'SendDiplomaticMessage',
          'playerId': _playerId,
          'targetPlayerId': _otherPlayerId,
          'topic': 'troopsNearCities',
          'messageId': 'message_1',
        },
      ),
      (
        RespondDiplomaticMessageCommand(
          playerId: _otherPlayerId,
          messageId: 'message_1',
          response: DiplomaticMessageResponse.conciliatory,
        ),
        {
          'type': 'RespondDiplomaticMessage',
          'playerId': _otherPlayerId,
          'messageId': 'message_1',
          'response': 'conciliatory',
        },
      ),
    ];

    for (final (command, expected) in cases) {
      expect(GameCommandSerializer.toJson(command), expected);
      expect(GameCommandSerializer.fromJson(expected), command);
    }
  });
}

GameEngineResult _apply(
  CanonicalGameSnapshot snapshot,
  DomainCommand command, {
  String actorPlayerId = _playerId,
}) {
  return const GameEngine().apply(
    snapshot: snapshot,
    command: command,
    context: GameEngineContext(
      actorPlayerId: actorPlayerId,
      mapView: _map,
      ruleset: GameRuleset.defaults,
      commandTick: 8,
    ),
  );
}

GameEngineAccepted _expectAccepted(GameEngineResult result) {
  expect(result, isA<GameEngineAccepted>());
  return result as GameEngineAccepted;
}

void _expectRejected(
  GameEngineResult result,
  CanonicalGameSnapshot snapshot,
  String reason,
) {
  expect(result, isA<GameEngineRejected>());
  final rejected = result as GameEngineRejected;
  expect(rejected.snapshot, same(snapshot));
  expect(rejected.reason, reason);
  expect(rejected.events, isEmpty);
}

CanonicalGameSnapshot _snapshot({DiplomacyState? diplomacy}) {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 5,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: _playerId, name: 'One', colorValue: 1),
        Player(id: _otherPlayerId, name: 'Two', colorValue: 2),
        Player(id: _hiddenPlayerId, name: 'Hidden', colorValue: 3),
      ],
      playerGold: const {_playerId: 20, _otherPlayerId: 3, _hiddenPlayerId: 11},
      diplomacy:
          diplomacy ??
          DiplomacyState.empty.addContact(_playerId, _otherPlayerId),
    ),
    session: MatchSessionState.snapshot(
      gameMode: GameMode.multiplayer,
      turnStatesByPlayerId: const {
        _playerId: PlayerTurnState.active,
        _otherPlayerId: PlayerTurnState.active,
        _hiddenPlayerId: PlayerTurnState.active,
      },
    ),
    metadata: GameSnapshotMetadata(
      id: 'diplomacy',
      schemaVersion: 3,
      name: 'Diplomacy',
      world: const WorldReference(name: 'diplomacy', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 30),
      camera: GameSnapshotCamera.zero,
    ),
    eventLogOffset: 23,
  );
}

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
