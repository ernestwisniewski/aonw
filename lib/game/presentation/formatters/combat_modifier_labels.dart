import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class CombatModifierLabels {
  static String? source(
    AppLocalizations l10n,
    CombatModifier modifier, {
    required bool attacker,
  }) {
    if (modifier.delta == 0) return null;
    return switch (modifier) {
      TerrainModifier() =>
        attacker
            ? l10n.combatPreviewSourceAttackTerrain
            : l10n.combatPreviewSourceDefenseTerrain,
      TechnologyModifier() => l10n.combatPreviewSourceTechnology,
      CounterModifier(:final label) => rawLabel(l10n, label),
      VeterancyModifier() => l10n.combatPreviewSourceVeterancy,
      FortificationModifier() => l10n.combatPreviewSourceCityGarrison,
      TroopCompositionModifier() => l10n.combatPreviewSourceMixedArmy,
    };
  }

  static String rawLabel(AppLocalizations l10n, String label) {
    if (label.startsWith('terrain.')) {
      final parts = label.split('.');
      if (parts.length < 2) {
        throw ArgumentError('Invalid terrain modifier label: $label');
      }
      return l10n.eventCombatTerrainModifierLabel(
        _terrainName(l10n, TerrainType.values.byName(parts[1])),
      );
    }
    if (label.startsWith('tech.')) {
      final parts = label.split('.');
      if (parts.length < 2) {
        throw ArgumentError('Invalid technology modifier label: $label');
      }
      return l10n.eventCombatTechModifierLabel(
        GameDisplayNames.technology(l10n, TechnologyId.values.byName(parts[1])),
      );
    }
    if (label.startsWith('veterancy.')) {
      final parts = label.split('.');
      if (parts.length < 2) {
        throw ArgumentError('Invalid veterancy modifier label: $label');
      }
      return l10n.eventCombatRankModifierLabel(
        GameDisplayNames.unitVeterancyRank(
          l10n,
          UnitVeterancyRank.values.byName(parts[1]),
        ),
      );
    }
    if (label.startsWith('counter.')) return _counterLabel(l10n, label);
    if (label.startsWith('city.')) return l10n.eventCombatCityGarrisonModifier;
    if (label == 'troop.mixedCommanderArmy') {
      return l10n.eventCombatMixedArmyModifier;
    }
    throw ArgumentError('Unknown combat modifier label: $label');
  }

  static String _counterLabel(AppLocalizations l10n, String label) {
    return switch (label) {
      'counter.spearmanVsMounted.attack' =>
        l10n.combatCounterSpearmanVsMountedAttack,
      'counter.spearmanVsMounted.defense' =>
        l10n.combatCounterSpearmanVsMountedDefense,
      'counter.archerDefensiveTerrain.defense' =>
        l10n.combatCounterArcherDefensiveTerrainDefense,
      'counter.cavalryRoughAttack.attack' =>
        l10n.combatCounterCavalryRoughAttack,
      'counter.cavalryOpenRaid.attack' => l10n.combatCounterCavalryOpenRaid,
      'counter.heavyInfantryBreakthrough.attack' =>
        l10n.combatCounterHeavyInfantryBreakthrough,
      _ => throw ArgumentError('Unknown combat counter modifier label: $label'),
    };
  }

  static String _terrainName(AppLocalizations l10n, TerrainType terrain) {
    return switch (terrain) {
      TerrainType.ocean => l10n.terrainOcean,
      TerrainType.coast => l10n.terrainCoast,
      TerrainType.lake => l10n.terrainLake,
      TerrainType.plains => l10n.terrainPlains,
      TerrainType.grassland => l10n.terrainGrassland,
      TerrainType.desert => l10n.terrainDesert,
      TerrainType.tundra => l10n.terrainTundra,
      TerrainType.snow => l10n.terrainSnow,
      TerrainType.mountain => l10n.terrainMountain,
      TerrainType.hills => l10n.terrainHills,
      TerrainType.wetlands => l10n.terrainWetlands,
      TerrainType.jungle => l10n.terrainJungle,
      TerrainType.forest => l10n.terrainForest,
      TerrainType.river => l10n.terrainRiver,
    };
  }
}
