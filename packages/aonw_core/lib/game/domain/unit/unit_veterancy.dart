import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';

enum UnitVeterancyRank {
  recruit,
  seasoned,
  veteran,
  elite;

  String get displayName => switch (this) {
    UnitVeterancyRank.recruit => 'Recruit',
    UnitVeterancyRank.seasoned => 'Seasoned',
    UnitVeterancyRank.veteran => 'Veteran',
    UnitVeterancyRank.elite => 'Elite',
  };
}

abstract final class UnitVeterancyRules {
  static const int seasonedThreshold = 3;
  static const int veteranThreshold = 7;
  static const int eliteThreshold = 12;

  static const int survivalExperience = 1;
  static const int defeatedEnemyExperience = 2;

  static bool canGainExperience(GameUnit unit) {
    return switch (unit.type) {
      GameUnitType.commander ||
      GameUnitType.warrior ||
      GameUnitType.archer ||
      GameUnitType.scout ||
      GameUnitType.spearman ||
      GameUnitType.cavalry ||
      GameUnitType.catapult ||
      GameUnitType.heavyInfantry ||
      GameUnitType.fieldCannon ||
      GameUnitType.rifleman ||
      GameUnitType.tank ||
      GameUnitType.scoutShip ||
      GameUnitType.warship ||
      GameUnitType.reconPlane => true,
      GameUnitType.settler ||
      GameUnitType.worker ||
      GameUnitType.merchant => false,
    };
  }

  static UnitVeterancyRank rankFor(GameUnit unit) {
    return rankForExperience(unit.experiencePoints);
  }

  static UnitVeterancyRank rankForExperience(int experiencePoints) {
    if (experiencePoints >= eliteThreshold) return UnitVeterancyRank.elite;
    if (experiencePoints >= veteranThreshold) return UnitVeterancyRank.veteran;
    if (experiencePoints >= seasonedThreshold) {
      return UnitVeterancyRank.seasoned;
    }
    return UnitVeterancyRank.recruit;
  }

  static CombatStats statsBonusFor(GameUnit unit) {
    if (!canGainExperience(unit)) return const CombatStats();
    return statsBonusForRank(rankFor(unit));
  }

  static CombatStats statsBonusForRank(UnitVeterancyRank rank) {
    return switch (rank) {
      UnitVeterancyRank.recruit => const CombatStats(),
      UnitVeterancyRank.seasoned => const CombatStats(attack: 1),
      UnitVeterancyRank.veteran => const CombatStats(attack: 1, defense: 1),
      UnitVeterancyRank.elite => const CombatStats(
        attack: 2,
        defense: 1,
        hp: 2,
      ),
    };
  }

  static int experienceAwardForCombat({
    required GameUnit unit,
    required bool survived,
    required bool defeatedEnemy,
  }) {
    if (!survived || !canGainExperience(unit)) return 0;
    return survivalExperience + (defeatedEnemy ? defeatedEnemyExperience : 0);
  }

  static GameUnit addExperience(GameUnit unit, int amount) {
    if (amount <= 0) return unit;
    return unit.copyWith(experiencePoints: unit.experiencePoints + amount);
  }
}
