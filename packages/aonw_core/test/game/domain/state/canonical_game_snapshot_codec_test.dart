import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('decodes current JSON directly to the canonical snapshot', () {
    final save = GameSave(
      id: 'save-1',
      name: 'Snapshot',
      mapName: 'world',
      turn: 4,
      playerStates: const {'p1': PlayerTurnState.active},
      savedAt: DateTime.utc(2026, 8, 1),
      camera: CameraState.zero,
      players: const [Player(id: 'p1', name: 'Player', colorValue: 0xFF123456)],
      gameMode: GameMode.multiplayer,
    );
    final state = DomainState.snapshot(
      playerColors: const {'p1': 0xFF123456},
      playerGold: const {'p1': 17},
      units: [GameUnit.startingCommander(ownerPlayerId: 'p1', col: 1, row: 2)],

      submittedPlayerIds: {'p1'},
      pendingAction: const PendingResearchSelection(ownerPlayerId: 'p1'),
      turnStartedAt: DateTime.utc(2026, 8, 1),
      initialResourceDistribution: InitialResourceDistribution(
        seed: 17,
        placements: const [
          InitialResourcePlacement(
            col: 3,
            row: 4,
            resource: ResourceType.marble,
          ),
        ],
      ),
    );
    final data = CanonicalGameSnapshotData(
      save: save.toJson(),
      state: CanonicalGameSnapshotCodec.encodeDomainState(state),
      eventLogOffset: 9,
    );

    final decoded = CanonicalGameSnapshotCodec.decode(data);

    expect(decoded.eventLogOffset, 9);
    expect(decoded.domain.turn, 4);
    expect(decoded.domain.gameMode, GameMode.multiplayer);
    expect(decoded.domain.participants, save.players);
    expect(decoded.domain.playerGold, const {'p1': 17});
    expect(decoded.domain.actions.pendingAction, isNotNull);
    expect(
      decoded.domain.initialResourceDistribution,
      state.initialResourceDistribution,
    );
  });

  test('canonical encode/decode is lossless and owns JSON data', () {
    final originalData = CanonicalGameSnapshotData(
      save: GameSave(
        id: 'save-2',
        name: 'Snapshot',
        mapName: 'world',
        turn: 1,
        playerStates: const {'p1': PlayerTurnState.active},
        savedAt: DateTime.utc(2026, 8, 1),
        camera: CameraState.zero,
        players: const [Player(id: 'p1', name: 'Player', colorValue: 1)],
      ).toJson(),
      state: const {
        'playerGold': {'p1': 3},
      },
      eventLogOffset: 2,
    );
    final snapshot = CanonicalGameSnapshotCodec.decode(originalData);

    final encoded = CanonicalGameSnapshotCodec.encode(snapshot);
    final restored = CanonicalGameSnapshotCodec.decode(encoded);

    expect(restored, snapshot);
    expect(encoded.eventLogOffset, snapshot.eventLogOffset);
    expect(
      () => encoded.state['playerGold'] = const {'p1': 99},
      throwsUnsupportedError,
    );
  });

  test('domain-only decoding infers a stable participant roster', () {
    final state = CanonicalGameSnapshotCodec.decodeDomainState(const {
      'playerColors': {'player_2': 0xFF123456},
      'playerCountries': {'player_1': 'poland'},
      'playerGold': {'player_3': 7},
    });

    expect(state.participants.map((player) => player.id), [
      'player_1',
      'player_2',
      'player_3',
    ]);
    expect(state.participants[0].country, PlayerCountry.poland);
    expect(state.participants[1].colorValue, 0xFF123456);
    expect(state.participants[2].name, 'player_3');
  });
}
