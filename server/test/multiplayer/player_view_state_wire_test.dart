import 'dart:convert';

import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/player_match_view_projector.dart';
import 'package:test/test.dart';

void main() {
  test('preserves the projected state wire JSON bit for bit', () {
    final canonicalState = DomainState.snapshot(
      playerColors: const {'player-owner': 1},
      playerCountries: const {'player-owner': PlayerCountry.poland},
      playerGold: const {'player-owner': 111},
      playerWarWeariness: const {'player-owner': 3},
      playerStabilityNet: const {'player-owner': 4},
      fogOfWar: FogOfWarState(
        players: {'player-owner': PlayerFogOfWar(playerId: 'player-owner')},
      ),
      research: ResearchState(
        players: const {'player-owner': PlayerResearchState.empty},
      ),
    );
    final expectedState = {
      ...CanonicalGameSnapshotCodec.encodeDomainState(canonicalState),
      'phase': 'running',
    };
    final canonical = WireSnapshot(
      matchId: 'match-1',
      offset: 1,
      save: GameSave(
        id: 'match-1',
        name: 'Wire golden',
        mapName: 'test-map',
        turn: 1,
        playerStates: const {'player-owner': PlayerTurnState.active},
        savedAt: DateTime.utc(2026, 7, 18),
        camera: CameraState.zero,
        players: const [
          Player(id: 'player-owner', name: 'Owner', colorValue: 1),
        ],
        gameMode: GameMode.multiplayer,
      ).toJson(),
      state: expectedState,
    );

    final projected = const PlayerMatchViewProjector().snapshotFor(
      canonical,
      const MatchRecipient(
        userIdentifier: 'owner-auth-id',
        playerId: 'player-owner',
      ),
    );

    expect(jsonEncode(projected.state), jsonEncode(expectedState));
  });
}
