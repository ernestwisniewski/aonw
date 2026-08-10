import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat/combat_modifier.dart';
import 'package:aonw_core/game/domain/combat/combat_ruleset.dart';
import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/combat/unit_combat_stats.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

part 'combat_environment_modifiers.dart';
part 'combat_unit_modifiers.dart';

abstract final class CombatModifierCollector {
  static List<CombatModifier> forAttacker({
    required GameUnit unit,
    required MapTileView tile,
    required PlayerResearchState research,
    GameUnit? defender,
    MapTileView? defenderTile,
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
    required MapTileView tile,
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

  static List<CombatModifier> _counterModifiers({
    required GameUnit unit,
    required GameUnit? opponent,
    required MapTileView unitTile,
    MapTileView? opponentTile,
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
