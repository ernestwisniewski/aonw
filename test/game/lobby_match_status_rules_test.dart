import 'package:aonw/game/presentation/screens/lobby_match_status_rules.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LobbyMatchStatusRules', () {
    test('counts required human players with safe lobby defaults', () {
      final match = _match(
        minPlayers: 1,
        players: [_human('player_1', 'user_1'), _ai('player_ai')],
      );

      expect(LobbyMatchStatusRules.humanPlayerCount(null), 0);
      expect(LobbyMatchStatusRules.humanPlayerCount(null, whenMissing: 1), 1);
      expect(LobbyMatchStatusRules.humanPlayerCount(match), 1);
      expect(
        LobbyMatchStatusRules.requiredHumanPlayers(match),
        LobbyMatchStatusRules.defaultMinimumHumanPlayers,
      );
      expect(
        LobbyMatchStatusRules.maximumPlayers(null),
        LobbyMatchStatusRules.defaultMaximumPlayers,
      );
    });

    test('enters only running or loading matches with enough humans', () {
      final ready = _match(
        state: 'loading',
        players: [_human('player_1', 'user_1'), _human('player_2', 'user_2')],
      );
      final waiting = _match(state: 'loading');
      final open = _match(
        players: [_human('player_1', 'user_1'), _human('player_2', 'user_2')],
      );

      expect(LobbyMatchStatusRules.canEnter(ready), isTrue);
      expect(LobbyMatchStatusRules.canEnter(waiting), isFalse);
      expect(LobbyMatchStatusRules.canEnter(open), isFalse);
    });

    test('uses ownerUserId for host checks even when player order changes', () {
      final match = _match(
        ownerUserId: 'user_1',
        players: [_human('player_2', 'user_2'), _human('player_1', 'user_1')],
      );

      expect(LobbyMatchStatusRules.isOwner(match, 'user_1'), isTrue);
      expect(LobbyMatchStatusRules.isOwner(match, 'user_2'), isFalse);
      expect(
        LobbyMatchStatusRules.canStartPrivateMatch(
          match: match,
          userId: 'user_1',
          busy: false,
        ),
        isTrue,
      );
      expect(
        LobbyMatchStatusRules.canStartPrivateMatch(
          match: match,
          userId: 'user_1',
          busy: true,
        ),
        isFalse,
      );
    });

    test('maps users and terminal match states', () {
      final match = _match(
        state: 'finished',
        players: [_human('player_1', 'user_1')],
      );

      expect(
        LobbyMatchStatusRules.playerIdForUser(match, 'user_1'),
        'player_1',
      );
      expect(LobbyMatchStatusRules.playerIdForUser(match, 'missing'), isNull);
      expect(LobbyMatchStatusRules.isTerminal(match), isTrue);
      expect(
        LobbyMatchStatusRules.isTerminal(_match(state: 'abandoned')),
        isTrue,
      );
      expect(LobbyMatchStatusRules.isTerminal(_match(state: 'open')), isFalse);
    });
  });
}

WireMatch _match({
  String state = 'open',
  String ownerUserId = 'user_1',
  List<WirePlayer>? players,
  int minPlayers = 2,
  int maxPlayers = 4,
}) {
  return WireMatch(
    id: 'match_1',
    ownerUserId: ownerUserId,
    name: 'Duel',
    mapName: 'verdantia',
    players: players ?? [_human('player_1', 'user_1')],
    maxPlayers: maxPlayers,
    minPlayers: minPlayers,
    turn: 1,
    state: state,
    createdAt: DateTime.utc(2026),
  );
}

WirePlayer _human(String id, String userId) {
  return WirePlayer(
    id: id,
    userId: userId,
    name: id,
    colorValue: 0xFF2563EB,
    kind: WirePlayerKind.human,
    connectionState: WirePlayerConnectionState.connected,
  );
}

WirePlayer _ai(String id) {
  return WirePlayer(
    id: id,
    userId: 'ai:$id',
    name: id,
    colorValue: 0xFFDC2626,
    kind: WirePlayerKind.ai,
    connectionState: WirePlayerConnectionState.connected,
    ai: const WireAiPlayer(strategyId: AiStrategyId.random),
  );
}
