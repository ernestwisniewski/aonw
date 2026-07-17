import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/combat/unit_combat_health.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/unit_veterancy.dart';

/// Mutable working set owned by a single combat resolution.
final class TurnCombatEffects {
  TurnCombatEffects.fromState(TurnCombatState state)
    : units = [...state.units],
      cities = [...state.cities],
      artifacts = [...state.artifacts],
      initialArtifacts = state.artifacts,
      intendedAttacks = state.intendedAttacks,
      diplomacy = state.diplomacy,
      resourceTradeAgreements = [...state.resourceTradeAgreements];

  final List<GameUnit> units;
  final List<GameCity> cities;
  final List<WorldArtifact> artifacts;

  /// City combat bonuses intentionally use the phase-entry snapshot.
  final List<WorldArtifact> initialArtifacts;
  final List<IntendedAttack> intendedAttacks;
  final List<GameEvent> events = [];
  DiplomacyState diplomacy;
  List<ResourceTradeAgreement> resourceTradeAgreements;

  TurnCombatResolution resolution() {
    return TurnCombatResolution(
      state: TurnCombatState(
        units: List.unmodifiable(units),
        cities: List.unmodifiable(cities),
        artifacts: List.unmodifiable(artifacts),
        intendedAttacks: intendedAttacks,
        diplomacy: diplomacy,
        resourceTradeAgreements: List.unmodifiable(resourceTradeAgreements),
      ),
      events: List.unmodifiable(events),
    );
  }

  int? unitIndexById(String unitId) {
    for (var index = 0; index < units.length; index++) {
      if (units[index].id == unitId) return index;
    }
    return null;
  }

  int? unitIndexAt(int col, int row) {
    for (var index = 0; index < units.length; index++) {
      if (units[index].occupies(col, row)) return index;
    }
    return null;
  }

  int? cityIndexAt(int col, int row) {
    for (var index = 0; index < cities.length; index++) {
      if (cities[index].occupiesCenter(col, row)) return index;
    }
    return null;
  }

  bool isProtectedRelation(String attackerPlayerId, String defenderPlayerId) {
    final status = diplomacy.statusBetween(attackerPlayerId, defenderPlayerId);
    return status == DiplomaticRelationStatus.friendly ||
        status == DiplomaticRelationStatus.truce;
  }

  void removeTradeAgreementsBetween(String playerAId, String playerBId) {
    final key = DiplomacyState.relationKey(playerAId, playerBId);
    resourceTradeAgreements = [
      for (final agreement in resourceTradeAgreements)
        if (DiplomacyState.relationKey(
              agreement.exporterPlayerId,
              agreement.importerPlayerId,
            ) !=
            key)
          agreement,
    ];
  }

  void dropUnitArtifacts(GameUnit unit) {
    final carriedId = unit.carriedArtifactId;
    final excavatingId = unit.excavatingArtifactId;
    if (carriedId == null && excavatingId == null) return;
    for (var index = 0; index < artifacts.length; index++) {
      final artifact = artifacts[index];
      if (artifact.id == carriedId || artifact.id == excavatingId) {
        artifacts[index] = artifact.copyWith(
          location: WorldArtifactLocation.map(col: unit.col, row: unit.row),
        );
      }
    }
  }

  void dropStoredArtifactsFromCity(GameCity city) {
    for (var index = 0; index < artifacts.length; index++) {
      final artifact = artifacts[index];
      final location = artifact.location;
      if (location.isStored && location.cityId == city.id) {
        artifacts[index] = artifact.copyWith(
          location: WorldArtifactLocation.map(
            col: city.center.col,
            row: city.center.row,
          ),
        );
      }
    }
  }

  GameUnit withCombatState(
    GameUnit unit, {
    required int hitPoints,
    required int maxHitPoints,
    int? movementPoints,
    HexCoordinate? retreatDestination,
    int experienceAward = 0,
  }) {
    final moved = unit.copyWith(
      col: retreatDestination?.col,
      row: retreatDestination?.row,
      movementPoints: retreatDestination == null ? movementPoints : 0,
    );
    final damaged = moved.copyWithHitPoints(
      UnitCombatHealth.storedHpForMax(hitPoints, maxHp: maxHitPoints),
    );
    return UnitVeterancyRules.addExperience(damaged, experienceAward);
  }

  UnitGainedExperienceEvent? experienceEvent({
    required GameUnit before,
    required GameUnit after,
    required int amount,
  }) {
    if (amount <= 0) return null;
    return UnitGainedExperienceEvent(
      unitId: after.id,
      ownerPlayerId: after.ownerPlayerId,
      amount: amount,
      totalExperience: after.experiencePoints,
      rank: UnitVeterancyRules.rankFor(after),
      promoted:
          UnitVeterancyRules.rankFor(before) !=
          UnitVeterancyRules.rankFor(after),
    );
  }
}
