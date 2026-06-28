import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

enum CombatResolutionMode { instant, simultaneous }

class CombatRuleset {
  final CombatResolutionMode resolutionMode;
  final int varianceRange;
  final int retreatThresholdPercent;
  final int defendedCityDefenseBonus;
  final int mixedCommanderArmyAttackBonus;
  final CombatStats cityBaseStats;
  final CombatStats commanderBaseStats;
  final Map<GameUnitType, CombatStats> unitBaseStats;
  final Map<TroopType, CombatStats> troopBaseStats;
  final Map<TerrainType, CombatStats> terrainStatModifiers;

  const CombatRuleset({
    this.resolutionMode = CombatResolutionMode.instant,
    this.varianceRange = 1,
    this.retreatThresholdPercent = 25,
    this.defendedCityDefenseBonus = 1,
    this.mixedCommanderArmyAttackBonus = 1,
    this.cityBaseStats = const CombatStats(
      attack: 0,
      defense: 2,
      hp: 16,
      range: 1,
      mobility: 0,
    ),
    this.commanderBaseStats = const CombatStats(
      attack: 1,
      defense: 1,
      hp: 8,
      range: 1,
      mobility: 2,
    ),
    this.unitBaseStats = const {
      GameUnitType.commander: CombatStats(
        attack: 1,
        defense: 1,
        hp: 8,
        range: 1,
        mobility: 2,
      ),
      GameUnitType.warrior: CombatStats(
        attack: 4,
        defense: 3,
        hp: 10,
        range: 1,
        mobility: 1,
      ),
      GameUnitType.archer: CombatStats(
        attack: 3,
        defense: 1,
        hp: 7,
        range: 2,
        mobility: 1,
      ),
      GameUnitType.settler: CombatStats(
        attack: 0,
        defense: 1,
        hp: 1,
        range: 1,
        mobility: 1,
      ),
      GameUnitType.worker: CombatStats(
        attack: 0,
        defense: 1,
        hp: 1,
        range: 1,
        mobility: 1,
      ),
      GameUnitType.merchant: CombatStats(
        attack: 0,
        defense: 1,
        hp: 1,
        range: 1,
        mobility: 1,
      ),
      GameUnitType.scout: CombatStats(
        attack: 1,
        defense: 1,
        hp: 5,
        range: 1,
        mobility: 3,
      ),
      GameUnitType.spearman: CombatStats(
        attack: 3,
        defense: 5,
        hp: 10,
        range: 1,
        mobility: 1,
      ),
      GameUnitType.cavalry: CombatStats(
        attack: 6,
        defense: 3,
        hp: 10,
        range: 1,
        mobility: 3,
      ),
      GameUnitType.catapult: CombatStats(
        attack: 7,
        defense: 1,
        hp: 7,
        range: 2,
        mobility: 1,
      ),
      GameUnitType.heavyInfantry: CombatStats(
        attack: 7,
        defense: 6,
        hp: 13,
        range: 1,
        mobility: 1,
      ),
      GameUnitType.fieldCannon: CombatStats(
        attack: 10,
        defense: 2,
        hp: 8,
        range: 2,
        mobility: 1,
      ),
      GameUnitType.rifleman: CombatStats(
        attack: 8,
        defense: 6,
        hp: 11,
        range: 2,
        mobility: 1,
      ),
      GameUnitType.tank: CombatStats(
        attack: 13,
        defense: 9,
        hp: 16,
        range: 1,
        mobility: 3,
      ),
      GameUnitType.scoutShip: CombatStats(
        attack: 3,
        defense: 3,
        hp: 8,
        range: 1,
        mobility: 3,
      ),
      GameUnitType.warship: CombatStats(
        attack: 10,
        defense: 7,
        hp: 14,
        range: 2,
        mobility: 2,
      ),
      GameUnitType.reconPlane: CombatStats(
        attack: 1,
        defense: 3,
        hp: 6,
        range: 3,
        mobility: 5,
      ),
    },
    this.troopBaseStats = const {
      TroopType.warrior: CombatStats(
        attack: 2,
        defense: 2,
        hp: 3,
        range: 1,
        mobility: 1,
      ),
      TroopType.archer: CombatStats(
        attack: 2,
        defense: 1,
        hp: 2,
        range: 2,
        mobility: 1,
      ),
      TroopType.settler: CombatStats(
        attack: 0,
        defense: 1,
        hp: 1,
        range: 1,
        mobility: 1,
      ),
    },
    this.terrainStatModifiers = const {
      TerrainType.forest: CombatStats(defense: 1),
      TerrainType.jungle: CombatStats(defense: 1),
      TerrainType.hills: CombatStats(defense: 1),
      TerrainType.wetlands: CombatStats(defense: 1),
      TerrainType.mountain: CombatStats(defense: 2),
      TerrainType.river: CombatStats(defense: 1),
      TerrainType.desert: CombatStats(defense: -1),
    },
  });

  static const CombatRuleset standard = CombatRuleset();

  CombatRuleset copyWith({CombatResolutionMode? resolutionMode}) {
    return CombatRuleset(
      resolutionMode: resolutionMode ?? this.resolutionMode,
      varianceRange: varianceRange,
      retreatThresholdPercent: retreatThresholdPercent,
      defendedCityDefenseBonus: defendedCityDefenseBonus,
      mixedCommanderArmyAttackBonus: mixedCommanderArmyAttackBonus,
      cityBaseStats: cityBaseStats,
      commanderBaseStats: commanderBaseStats,
      unitBaseStats: unitBaseStats,
      troopBaseStats: troopBaseStats,
      terrainStatModifiers: terrainStatModifiers,
    );
  }

  CombatStats baseStatsFor(GameUnitType type) {
    return unitBaseStats[type] ?? const CombatStats();
  }

  CombatStats statsForTroop(TroopType type) {
    return troopBaseStats[type] ?? const CombatStats();
  }

  CombatStats terrainStatsFor(TerrainType type) {
    return terrainStatModifiers[type] ?? const CombatStats();
  }

  bool isDefensiveTerrain(TerrainType type) {
    return terrainStatsFor(type).defense > 0;
  }
}
