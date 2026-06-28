import 'package:aonw_core/ai.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/state.dart';

final class CityThreatAssessment {
  final Set<String> activeHostilePlayerIds;
  final List<PendingCityAttackThreat> pendingCityAttackThreats;

  CityThreatAssessment({
    required Iterable<String> activeHostilePlayerIds,
    required Iterable<PendingCityAttackThreat> pendingCityAttackThreats,
  }) : activeHostilePlayerIds = Set.unmodifiable(activeHostilePlayerIds),
       pendingCityAttackThreats = List.unmodifiable(pendingCityAttackThreats);
}

final class CityThreatAssessor {
  const CityThreatAssessor();

  CityThreatAssessment assess({
    required PersistentGameState state,
    required String playerId,
  }) {
    return CityThreatAssessment(
      activeHostilePlayerIds: _pendingHostilePlayerIds(
        state: state,
        playerId: playerId,
      ),
      pendingCityAttackThreats: _pendingCityAttackThreats(
        state: state,
        playerId: playerId,
      ),
    );
  }

  Set<String> _pendingHostilePlayerIds({
    required PersistentGameState state,
    required String playerId,
  }) {
    final hostilePlayerIds = <String>{};
    for (final attack in state.runtimeState.intendedAttacks) {
      if (attack.declaringPlayerId == playerId) continue;
      if (_targetsPlayer(state, playerId: playerId, attack: attack)) {
        hostilePlayerIds.add(attack.declaringPlayerId);
      }
    }
    return hostilePlayerIds;
  }

  bool _targetsPlayer(
    PersistentGameState state, {
    required String playerId,
    required IntendedAttack attack,
  }) {
    final unit = state.units.unitAt(attack.defenderCol, attack.defenderRow);
    if (unit?.ownerPlayerId == playerId) return true;
    final city = state.cities.cityAt(attack.defenderCol, attack.defenderRow);
    return city?.ownerPlayerId == playerId;
  }

  List<PendingCityAttackThreat> _pendingCityAttackThreats({
    required PersistentGameState state,
    required String playerId,
  }) {
    final unitsById = {for (final unit in state.units) unit.id: unit};
    final threats = <PendingCityAttackThreat>[];
    for (final attack in state.runtimeState.intendedAttacks) {
      if (attack.declaringPlayerId == playerId) continue;
      final attacker = unitsById[attack.attackerUnitId];
      if (attacker == null || attacker.ownerPlayerId == playerId) continue;
      final city = state.cities.cityAt(attack.defenderCol, attack.defenderRow);
      if (city == null || city.ownerPlayerId != playerId) continue;
      threats.add(
        PendingCityAttackThreat(
          attackerPlayerId: attack.declaringPlayerId,
          attackerUnitId: attack.attackerUnitId,
          attackerHex: HexCoordinate(col: attacker.col, row: attacker.row),
          cityId: city.id,
          cityCenter: city.center,
        ),
      );
    }
    return threats;
  }
}
