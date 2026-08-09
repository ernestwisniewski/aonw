import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/lobby_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/match_turn_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:test/test.dart';

void main() {
  const presencePolicy = LobbyPresencePolicy();
  const policy = MatchTurnPresencePolicy(presencePolicy);
  final now = DateTime.utc(2026, 8, 8, 12);

  test('requires a live durable human connection to run the turn clock', () {
    final liveHumanLease = presencePolicy.connectedLease(
      userIdentifier: 'human-user',
      connectionGeneration: 'human-generation',
      nowUtc: now,
    );
    final connectedHuman = _human(
      connectionState: WirePlayerConnectionState.connected,
    );

    expect(
      policy.areAllHumanPlayersOffline(
        _state(players: [connectedHuman]),
        nowUtc: now,
      ),
      isTrue,
      reason: 'a connected projection without a lease is stale',
    );
    expect(
      policy.areAllHumanPlayersOffline(
        _state(
          players: [connectedHuman],
          presenceLeases: {'human-user': liveHumanLease},
        ),
        nowUtc: now,
      ),
      isFalse,
    );
    expect(
      policy.areAllHumanPlayersOffline(
        _state(
          players: [connectedHuman],
          presenceLeases: {'human-user': liveHumanLease},
        ),
        nowUtc: liveHumanLease.expiresAt,
      ),
      isTrue,
      reason: 'an expired lease cannot keep turn processing alive',
    );
  });

  test('ignores connected AI seats when every human is offline', () {
    final liveAiLease = presencePolicy.connectedLease(
      userIdentifier: 'ai-user',
      connectionGeneration: 'ai-generation',
      nowUtc: now,
    );
    final state = _state(
      players: [
        _human(connectionState: WirePlayerConnectionState.offline),
        _ai(connectionState: WirePlayerConnectionState.connected),
      ],
      presenceLeases: {'ai-user': liveAiLease},
    );

    expect(policy.areAllHumanPlayersOffline(state, nowUtc: now), isTrue);
    expect(
      policy.shouldRestartClockOnConnection(
        state,
        state.match.players.first,
        nowUtc: now,
      ),
      isTrue,
    );
    expect(
      policy.shouldRestartClockOnConnection(
        state,
        state.match.players.last,
        nowUtc: now,
      ),
      isFalse,
    );
  });

  test('does not classify an invalid human-free roster as offline', () {
    final state = _state(
      players: [_ai(connectionState: WirePlayerConnectionState.offline)],
    );

    expect(policy.areAllHumanPlayersOffline(state, nowUtc: now), isFalse);
  });
}

StoredMatchState _state({
  required List<WirePlayer> players,
  Map<String, StoredMatchPresenceLease> presenceLeases = const {},
}) {
  return StoredMatchState(
    match: WireMatch(
      id: 'turn-presence-match',
      ownerUserId: 'human-user',
      name: 'Turn presence',
      mapName: 'verdantia',
      players: players,
      maxPlayers: 2,
      minPlayers: 1,
      turn: 1,
      state: 'running',
      createdAt: DateTime.utc(2026, 8, 8, 12),
    ),
    snapshot: const WireSnapshot(
      matchId: 'turn-presence-match',
      offset: 0,
      save: {},
      state: {},
    ),
    presenceLeases: presenceLeases,
  );
}

WirePlayer _human({required WirePlayerConnectionState connectionState}) {
  return WirePlayer(
    id: 'human-player',
    userId: 'human-user',
    name: 'Human',
    colorValue: 0,
    country: PlayerCountry.poland,
    kind: WirePlayerKind.human,
    connectionState: connectionState,
  );
}

WirePlayer _ai({required WirePlayerConnectionState connectionState}) {
  return WirePlayer(
    id: 'ai-player',
    userId: 'ai-user',
    name: 'AI',
    colorValue: 1,
    country: PlayerCountry.egypt,
    kind: WirePlayerKind.ai,
    connectionState: connectionState,
    ai: const WireAiPlayer(
      strategyId: AiStrategyId.basic,
      difficulty: AiDifficulty.normal,
      persona: AiPersona.balanced,
    ),
  );
}
