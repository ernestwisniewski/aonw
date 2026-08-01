import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

void main() {
  group('research engine handler', () {
    test('selects research and clears only the matching pending action', () {
      final snapshot = _snapshot(
        interaction: PersistedInteractionState(
          pendingAction: const PendingResearchSelection(
            ownerPlayerId: _playerId,
          ),
        ),
      );

      final result = _apply(
        snapshot,
        const SelectTechnologyCommand(_playerId, TechnologyId.agriculture),
      );

      final accepted = _expectAccepted(result);
      expect(
        accepted.snapshot.domain.research
            .forPlayer(_playerId)
            .activeTechnologyId,
        TechnologyId.agriculture,
      );
      expect(accepted.snapshot.interaction.pendingAction, isNull);
      expect(accepted.events, isEmpty);
      expect(
        accepted.snapshot.domain.participants,
        same(snapshot.domain.participants),
      );
      expect(accepted.snapshot.session, same(snapshot.session));
      expect(accepted.snapshot.metadata, same(snapshot.metadata));
      expect(accepted.snapshot.eventLogOffset, snapshot.eventLogOffset);
    });

    test('rejects a forged player and preserves snapshot identity', () {
      final snapshot = _snapshot();

      final result = _apply(
        snapshot,
        const SelectTechnologyCommand(_playerId, TechnologyId.agriculture),
        actorPlayerId: _otherPlayerId,
      );

      _expectRejected(result, snapshot, 'technology_player_not_controlled');
    });

    test('rejects unavailable research and preserves snapshot identity', () {
      final snapshot = _snapshot();

      final result = _apply(
        snapshot,
        const SelectTechnologyCommand(_playerId, TechnologyId.storage),
      );

      _expectRejected(result, snapshot, 'technology_not_available');
    });

    test('reselecting the active technology is a rejected identity no-op', () {
      final snapshot = _snapshot(
        research: ResearchState(
          players: {
            _playerId: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );

      final result = _apply(
        snapshot,
        const SelectTechnologyCommand(_playerId, TechnologyId.agriculture),
      );

      _expectRejected(result, snapshot, 'technology_not_available');
    });
  });

  test('research player wire JSON remains byte-shape compatible', () {
    const command = SelectTechnologyCommand(
      _playerId,
      TechnologyId.agriculture,
    );
    const expected = <String, dynamic>{
      'type': 'SelectTechnology',
      'playerId': _playerId,
      'technologyId': 'agriculture',
    };

    expect(DomainCommandCodec.toJson(command), expected);
    expect(DomainCommandCodec.fromJson(expected), command);
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
      commandTick: 5,
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

CanonicalGameSnapshot _snapshot({
  ResearchState research = ResearchState.empty,
  PersistedInteractionState interaction = PersistedInteractionState.empty,
}) {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 5,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: _playerId, name: 'One', colorValue: 1),
        Player(id: _otherPlayerId, name: 'Two', colorValue: 2),
      ],
      research: research,
    ),
    session: MatchSessionState.snapshot(
      gameMode: GameMode.multiplayer,
      turnStatesByPlayerId: const {
        _playerId: PlayerTurnState.active,
        _otherPlayerId: PlayerTurnState.active,
      },
    ),
    metadata: GameSnapshotMetadata(
      id: 'research',
      schemaVersion: 3,
      name: 'Research',
      world: const WorldReference(name: 'research', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 30),
      camera: GameSnapshotCamera.zero,
    ),
    interaction: interaction,
    eventLogOffset: 17,
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
