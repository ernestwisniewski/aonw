import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

enum CombatResolutionMode { instant, simultaneous }

class CombatRuleset {
  final CombatResolutionMode resolutionMode;
  final int varianceRange;
  final int rangedRetaliationPercent;
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
    this.varianceRange = 2,
    this.rangedRetaliationPercent = 50,
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
    this.unitBaseStats = const {},
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

  CombatRuleset copyWith({
    CombatResolutionMode? resolutionMode,
    int? varianceRange,
    int? rangedRetaliationPercent,
    int? retreatThresholdPercent,
    int? defendedCityDefenseBonus,
    int? mixedCommanderArmyAttackBonus,
    CombatStats? cityBaseStats,
    CombatStats? commanderBaseStats,
    Map<GameUnitType, CombatStats>? unitBaseStats,
    Map<TroopType, CombatStats>? troopBaseStats,
    Map<TerrainType, CombatStats>? terrainStatModifiers,
  }) {
    return CombatRuleset(
      resolutionMode: resolutionMode ?? this.resolutionMode,
      varianceRange: varianceRange ?? this.varianceRange,
      rangedRetaliationPercent:
          rangedRetaliationPercent ?? this.rangedRetaliationPercent,
      retreatThresholdPercent:
          retreatThresholdPercent ?? this.retreatThresholdPercent,
      defendedCityDefenseBonus:
          defendedCityDefenseBonus ?? this.defendedCityDefenseBonus,
      mixedCommanderArmyAttackBonus:
          mixedCommanderArmyAttackBonus ?? this.mixedCommanderArmyAttackBonus,
      cityBaseStats: cityBaseStats ?? this.cityBaseStats,
      commanderBaseStats: commanderBaseStats ?? this.commanderBaseStats,
      unitBaseStats: unitBaseStats ?? this.unitBaseStats,
      troopBaseStats: troopBaseStats ?? this.troopBaseStats,
      terrainStatModifiers: terrainStatModifiers ?? this.terrainStatModifiers,
    );
  }

  CombatStats baseStatsFor(GameUnitType type) {
    return unitBaseStats[type] ?? UnitCatalog.specFor(type).baseStats;
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
