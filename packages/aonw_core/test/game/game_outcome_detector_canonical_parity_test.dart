import 'package:aonw_core/game/domain/match_rules/game_length_config.dart';
import 'package:aonw_core/game/domain/match_rules/match_rules.dart';
import 'package:aonw_core/game/domain/outcome/game_outcome.dart';
import 'package:aonw_core/game/domain/outcome/game_outcome_detector.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/state/game_mode.dart';
import 'package:aonw_core/game/domain/state/match_session_state.dart';
import 'package:aonw_core/game/domain/state/persistent_game_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:test/test.dart';

void main() {
  test('canonical outcome matches legacy outcome for the active roster', () {
    final matchRules = MatchRules.forGameLength(GameLengthConfig.standard60);
    final units = [
      _unit('p1', GameUnitType.warrior, col: 0),
      _unit('p2', GameUnitType.warrior, col: 1),
      _unit('p3', GameUnitType.tank, col: 2),
    ];
    final domain = DomainState.snapshot(
      turn: matchRules.victory.turnLimit!,
      matchRules: matchRules,
      participants: const [
        Player(id: 'p3', name: 'p3', colorValue: 3),
        Player(id: 'p2', name: 'p2', colorValue: 2),
        Player(id: 'p1', name: 'p1', colorValue: 1),
      ],
      units: units,
      playerGold: const {'p1': 100},
    );
    final session = MatchSessionState.snapshot(
      gameMode: GameMode.multiplayer,
      kickedPlayerIds: const {'p3'},
    );
    final persistent = PersistentGameState(
      units: units,
      playerGold: const {'p1': 100},
    );
    const detector = GameOutcomeDetector();

    final legacy = detector.evaluate(
      playerIds: const ['p2', 'p1'],
      state: persistent,
      matchRules: matchRules,
      turn: matchRules.victory.turnLimit,
    );
    final canonical = detector.evaluateCanonical(
      state: domain,
      session: session,
    );

    expect(canonical, legacy);
    expect(
      canonical,
      GameOutcome.score(
        winnerPlayerId: 'p1',
        scoreByPlayerId: const {'p1': 17, 'p2': 15},
      ),
    );
  });
}

GameUnit _unit(String playerId, GameUnitType type, {required int col}) {
  return GameUnit.produced(
    id: '${type.name}_$playerId',
    ownerPlayerId: playerId,
    type: type,
    col: col,
    row: 0,
  );
}
