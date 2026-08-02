import 'package:aonw/game/domain/ai/city_threat_assessor.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityThreatAssessor', () {
    test('reports active hostility and pending city attack threats', () {
      final state = DomainState.snapshot(
        turn: 1,
        matchRules: MatchRules.standard,
        participants: const [
          Player(id: 'attacker', name: 'Attacker', colorValue: 0xFF000001),
          Player(
            id: 'ai',
            name: 'AI',
            colorValue: 0xFF000002,
            kind: PlayerKind.ai,
          ),
        ],
        units: [
          GameUnit.startingCommander(ownerPlayerId: 'attacker', col: 0, row: 0),
          GameUnit.startingCommander(ownerPlayerId: 'ai', col: 2, row: 0),
        ],
        cities: const [
          GameCity(
            id: 'ai_city',
            ownerPlayerId: 'ai',
            name: 'AI City',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        intendedAttacks: const [
          IntendedAttack(
            attackerUnitId: 'commander_attacker',
            defenderCol: 2,
            defenderRow: 0,
            declaredAtTick: 7,
            declaringPlayerId: 'attacker',
          ),
          IntendedAttack(
            attackerUnitId: 'commander_attacker',
            defenderCol: 1,
            defenderRow: 0,
            declaredAtTick: 8,
            declaringPlayerId: 'attacker',
          ),
          IntendedAttack(
            attackerUnitId: 'commander_ai',
            defenderCol: 0,
            defenderRow: 0,
            declaredAtTick: 9,
            declaringPlayerId: 'ai',
          ),
        ],
      );

      final result = const CityThreatAssessor().assess(
        state: state,
        playerId: 'ai',
      );

      expect(result.activeHostilePlayerIds, {'attacker'});
      expect(result.pendingCityAttackThreats, [
        const PendingCityAttackThreat(
          attackerPlayerId: 'attacker',
          attackerUnitId: 'commander_attacker',
          attackerHex: HexCoordinate(col: 0, row: 0),
          cityId: 'ai_city',
          cityCenter: CityHex(col: 1, row: 0),
        ),
      ]);
    });
  });
}
