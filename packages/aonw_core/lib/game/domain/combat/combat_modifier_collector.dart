import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat/combat_modifier.dart';
import 'package:aonw_core/game/domain/combat/combat_ruleset.dart';
import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/combat/unit_combat_stats.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class CombatModifierCollector {
  static List<CombatModifier> forAttacker({
    required GameUnit unit,
    required TileData tile,
    required PlayerResearchState research,
    GameUnit? defender,
    TileData? defenderTile,
    CombatRuleset ruleset = CombatRuleset.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    return [
      ..._terrainModifiers(tile: tile, ruleset: ruleset),
      ..._counterModifiers(
        unit: unit,
        opponent: defender,
        unitTile: tile,
        opponentTile: defenderTile,
        isAttacker: true,
      ),
      ..._technologyModifiers(
        unit: unit,
        research: research,
        ruleset: ruleset,
        technologyRuleset: technologyRuleset,
        includeCityDefense: false,
      ),
      ..._veterancyModifiers(unit),
      ..._troopCompositionModifiers(unit: unit, ruleset: ruleset),
    ];
  }

  static List<CombatModifier> forDefender({
    required GameUnit unit,
    required TileData tile,
    required GameCity? defendedCity,
    required PlayerResearchState research,
    GameUnit? attacker,
    CombatRuleset ruleset = CombatRuleset.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    return [
      ..._terrainModifiers(tile: tile, ruleset: ruleset),
      ..._counterModifiers(
        unit: unit,
        opponent: attacker,
        unitTile: tile,
        isAttacker: false,
      ),
      ..._fortificationModifiers(defendedCity: defendedCity, ruleset: ruleset),
      ..._technologyModifiers(
        unit: unit,
        research: research,
        ruleset: ruleset,
        technologyRuleset: technologyRuleset,
        includeCityDefense: defendedCity != null,
      ),
      ..._veterancyModifiers(unit),
      ..._troopCompositionModifiers(unit: unit, ruleset: ruleset),
    ];
  }

  static List<CombatModifier> _terrainModifiers({
    required TileData tile,
    required CombatRuleset ruleset,
  }) {
    final modifiers = <CombatModifier>[];
    for (final terrain in tile.terrains) {
      modifiers.addAll(
        _modifiersFromStats(
          stats: ruleset.terrainStatsFor(terrain),
          labelPrefix: 'terrain.${terrain.name}',
          create: ({required label, required target, required delta}) =>
              TerrainModifier(label: label, target: target, delta: delta),
        ),
      );
    }
    return modifiers;
  }

  static List<CombatModifier> _counterModifiers({
    required GameUnit unit,
    required GameUnit? opponent,
    required TileData unitTile,
    TileData? opponentTile,
    required bool isAttacker,
  }) {
    if (opponent == null) return const [];

    final modifiers = <CombatModifier>[];
    final targetTile = isAttacker ? opponentTile : unitTile;

    if (unit.type == GameUnitType.spearman &&
        _mountedOrArmoredTypes.contains(opponent.type)) {
      modifiers.add(
        CounterModifier(
          label: isAttacker
              ? 'counter.spearmanVsMounted.attack'
              : 'counter.spearmanVsMounted.defense',
          target: isAttacker
              ? CombatStatTarget.attack
              : CombatStatTarget.defense,
          delta: isAttacker ? 2 : 3,
        ),
      );
    }

    if (unit.type == GameUnitType.archer &&
        !isAttacker &&
        _hasDefensiveTerrain(unitTile)) {
      modifiers.add(
        const CounterModifier(
          label: 'counter.archerDefensiveTerrain.defense',
          target: CombatStatTarget.defense,
          delta: 2,
        ),
      );
    }

    if (unit.type == GameUnitType.cavalry &&
        isAttacker &&
        targetTile != null &&
        _hasRoughTerrain(targetTile)) {
      modifiers.add(
        const CounterModifier(
          label: 'counter.cavalryRoughAttack.attack',
          target: CombatStatTarget.attack,
          delta: -2,
        ),
      );
    }

    if (unit.type == GameUnitType.cavalry &&
        isAttacker &&
        targetTile != null &&
        _hasOpenTerrain(targetTile) &&
        _raidTargetTypes.contains(opponent.type)) {
      modifiers.add(
        const CounterModifier(
          label: 'counter.cavalryOpenRaid.attack',
          target: CombatStatTarget.attack,
          delta: 2,
        ),
      );
    }

    if (unit.type == GameUnitType.heavyInfantry &&
        isAttacker &&
        _lineHolderTypes.contains(opponent.type)) {
      modifiers.add(
        const CounterModifier(
          label: 'counter.heavyInfantryBreakthrough.attack',
          target: CombatStatTarget.attack,
          delta: 2,
        ),
      );
    }

    return modifiers;
  }

  static bool _hasDefensiveTerrain(TileData tile) {
    return tile.terrains.any(_defensiveTerrain.contains);
  }

  static bool _hasRoughTerrain(TileData tile) {
    return tile.terrains.any(_roughTerrain.contains);
  }

  static bool _hasOpenTerrain(TileData tile) {
    return tile.terrains.any(_openTerrain.contains) && !_hasRoughTerrain(tile);
  }

  static List<CombatModifier> _fortificationModifiers({
    required GameCity? defendedCity,
    required CombatRuleset ruleset,
  }) {
    if (defendedCity == null || ruleset.defendedCityDefenseBonus == 0) {
      return const [];
    }
    return [
      FortificationModifier(
        label: 'city.${defendedCity.id}.garrison',
        target: CombatStatTarget.defense,
        delta: ruleset.defendedCityDefenseBonus,
      ),
    ];
  }

  static List<CombatModifier> _technologyModifiers({
    required GameUnit unit,
    required PlayerResearchState research,
    required CombatRuleset ruleset,
    required TechnologyRuleset technologyRuleset,
    required bool includeCityDefense,
  }) {
    final modifiers = <CombatModifier>[];
    final technologyIds = research.unlockedTechnologyIds.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    for (final technologyId in technologyIds) {
      final technology = technologyRuleset.technologies[technologyId];
      if (technology == null) continue;
      for (final effect in technology.effects) {
        switch (effect) {
          case ArmyStrengthMultiplier(:final multiplier):
            final delta = _scaledDelta(
              UnitCombatStats.derive(unit, ruleset: ruleset).attack,
              multiplier,
            );
            if (delta != 0) {
              modifiers.add(
                TechnologyModifier(
                  label: 'tech.${technologyId.name}.armyStrength',
                  target: CombatStatTarget.attack,
                  delta: delta,
                ),
              );
            }
          case CityDefenseBonus(:final amount):
            if (includeCityDefense && amount != 0) {
              modifiers.add(
                TechnologyModifier(
                  label: 'tech.${technologyId.name}.cityDefense',
                  target: CombatStatTarget.defense,
                  delta: amount,
                ),
              );
            }
          case ArmyCombatStatsBonus(:final attack, :final defense, :final hp):
            if (_isArmyUnit(unit)) {
              modifiers.addAll(
                _armyCombatStatModifiers(
                  technologyId: technologyId,
                  attack: attack,
                  defense: defense,
                  hp: hp,
                ),
              );
            }
          case StrategicResourceProductionBonus() ||
              GlobalGoldMultiplier() ||
              ArmyProductionMultiplier() ||
              MaxCityPopulationBonus() ||
              MaxControlledHexesBonus() ||
              CityScienceBonus():
            break;
        }
      }
    }
    return modifiers;
  }

  static bool _isArmyUnit(GameUnit unit) {
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

  static List<CombatModifier> _armyCombatStatModifiers({
    required TechnologyId technologyId,
    required int attack,
    required int defense,
    required int hp,
  }) {
    return [
      if (attack != 0)
        TechnologyModifier(
          label: 'tech.${technologyId.name}.armyAttack',
          target: CombatStatTarget.attack,
          delta: attack,
        ),
      if (defense != 0)
        TechnologyModifier(
          label: 'tech.${technologyId.name}.armyDefense',
          target: CombatStatTarget.defense,
          delta: defense,
        ),
      if (hp != 0)
        TechnologyModifier(
          label: 'tech.${technologyId.name}.armyHitPoints',
          target: CombatStatTarget.hp,
          delta: hp,
        ),
    ];
  }

  static List<CombatModifier> _troopCompositionModifiers({
    required GameUnit unit,
    required CombatRuleset ruleset,
  }) {
    if (unit.type != GameUnitType.commander ||
        ruleset.mixedCommanderArmyAttackBonus == 0 ||
        unit.troopCount(TroopType.warrior) <= 0 ||
        unit.troopCount(TroopType.archer) <= 0) {
      return const [];
    }
    return [
      TroopCompositionModifier(
        label: 'troop.mixedCommanderArmy',
        target: CombatStatTarget.attack,
        delta: ruleset.mixedCommanderArmyAttackBonus,
      ),
    ];
  }

  static List<CombatModifier> _veterancyModifiers(GameUnit unit) {
    if (!UnitVeterancyRules.canGainExperience(unit)) return const [];
    final rank = UnitVeterancyRules.rankFor(unit);
    final stats = UnitVeterancyRules.statsBonusForRank(rank);
    return _modifiersFromStats(
      stats: stats,
      labelPrefix: 'veterancy.${rank.name}',
      create: ({required label, required target, required delta}) =>
          VeterancyModifier(label: label, target: target, delta: delta),
    );
  }

  static int _scaledDelta(int base, double multiplier) {
    if (base <= 0 || multiplier == 0) return 0;
    final delta = (base * multiplier).round();
    if (delta == 0) return multiplier > 0 ? 1 : -1;
    return delta;
  }

  static List<CombatModifier> _modifiersFromStats({
    required CombatStats stats,
    required String labelPrefix,
    required CombatModifier Function({
      required String label,
      required CombatStatTarget target,
      required int delta,
    })
    create,
  }) {
    return [
      if (stats.attack != 0)
        create(
          label: '$labelPrefix.attack',
          target: CombatStatTarget.attack,
          delta: stats.attack,
        ),
      if (stats.defense != 0)
        create(
          label: '$labelPrefix.defense',
          target: CombatStatTarget.defense,
          delta: stats.defense,
        ),
      if (stats.hp != 0)
        create(
          label: '$labelPrefix.hp',
          target: CombatStatTarget.hp,
          delta: stats.hp,
        ),
      if (stats.range != 1)
        create(
          label: '$labelPrefix.range',
          target: CombatStatTarget.range,
          delta: stats.range - 1,
        ),
      if (stats.mobility != 1)
        create(
          label: '$labelPrefix.mobility',
          target: CombatStatTarget.mobility,
          delta: stats.mobility - 1,
        ),
    ];
  }
}

const _mountedOrArmoredTypes = {GameUnitType.cavalry, GameUnitType.tank};

const _lineHolderTypes = {
  GameUnitType.warrior,
  GameUnitType.spearman,
  GameUnitType.rifleman,
};

const _raidTargetTypes = {
  GameUnitType.settler,
  GameUnitType.worker,
  GameUnitType.merchant,
  GameUnitType.scout,
  GameUnitType.catapult,
};

const _defensiveTerrain = {
  TerrainType.forest,
  TerrainType.jungle,
  TerrainType.hills,
  TerrainType.wetlands,
  TerrainType.mountain,
};

const _roughTerrain = {
  TerrainType.forest,
  TerrainType.jungle,
  TerrainType.hills,
  TerrainType.wetlands,
  TerrainType.mountain,
};

const _openTerrain = {
  TerrainType.plains,
  TerrainType.grassland,
  TerrainType.desert,
  TerrainType.tundra,
  TerrainType.snow,
};
