import 'package:aonw/game/domain/hex_assessment/hex_assessment_model.dart';
import 'package:aonw/game/domain/hex_assessment/hex_score.dart';
import 'package:aonw/game/domain/hex_assessment/resource_groups.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/hex_assessment/hex_assessment_input.dart';

abstract final class HexKindRules {
  static HexAssessmentKind classify(HexAssessmentInput input, HexScore score) {
    return _specialKind(input) ?? classifyByScores(score);
  }

  static HexAssessmentKind classifyByScores(HexScore score) {
    return switch (score) {
      _ when score.city >= 7 => HexAssessmentKind.goodCitySite,
      _ when score.defense >= 6 => HexAssessmentKind.defensivePosition,
      _ when score.economy >= 6 => HexAssessmentKind.promisingLand,
      _ when score.city <= 0 && score.economy <= 0 =>
        HexAssessmentKind.weakLand,
      _ => HexAssessmentKind.ordinaryLand,
    };
  }

  static HexAssessmentKind? _specialKind(HexAssessmentInput input) {
    final context = _HexKindContext(input);
    return switch (context.terrain) {
      null => HexAssessmentKind.mapTile,
      TerrainType.mountain => HexAssessmentKind.naturalBarrier,
      TerrainType.ocean || TerrainType.lake => HexAssessmentKind.openSea,
      TerrainType.coast => _coastKind(context),
      TerrainType.hills => _hillsKind(context),
      TerrainType.desert => _desertKind(context),
      TerrainType.grassland => _grasslandKind(context),
      TerrainType.plains => _plainsKind(context),
      TerrainType.forest => _forestKind(context),
      TerrainType.jungle => _jungleKind(context),
      TerrainType.wetlands => _jungleKind(context),
      TerrainType.tundra => _tundraKind(context),
      TerrainType.snow => _snowKind(context),
      TerrainType.river => HexAssessmentKind.mapTile,
    };
  }

  static HexAssessmentKind _coastKind(_HexKindContext context) {
    return switch (context) {
      _ when context.isRegionalPortHeart => HexAssessmentKind.regionalPortHeart,
      _ when context.hasRiver => HexAssessmentKind.riverPort,
      _ when context.has(ResourceType.fish) => HexAssessmentKind.fishingCoast,
      _ when context.has(ResourceType.pearls) => HexAssessmentKind.richCoast,
      _ => HexAssessmentKind.coast,
    };
  }

  static HexAssessmentKind _hillsKind(_HexKindContext context) {
    return switch (context) {
      _ when context.hasIndustrialResource =>
        HexAssessmentKind.industrialStronghold,
      _ when context.hasHillWealth => HexAssessmentKind.richHills,
      _ when context.hasRiver => HexAssessmentKind.riverHills,
      _ => HexAssessmentKind.highGround,
    };
  }

  static HexAssessmentKind? _desertKind(_HexKindContext context) {
    return switch (context) {
      _ when context.isTradeOasis => HexAssessmentKind.tradeOasis,
      _ when context.has(ResourceType.oil) => HexAssessmentKind.desertDeposits,
      _ when context.hasRiver => HexAssessmentKind.oasis,
      _ when context.hasNoResources => HexAssessmentKind.barrenLand,
      _ => null,
    };
  }

  static HexAssessmentKind _grasslandKind(_HexKindContext context) {
    return switch (context) {
      _ when context.isRiverFoodCitySpot => HexAssessmentKind.idealCitySite,
      _ when context.hasPlainLuxury => HexAssessmentKind.richPlain,
      _ when context.hasBorderlandResource =>
        HexAssessmentKind.strategicBorderland,
      _ when context.hasRiver => HexAssessmentKind.fertileField,
      _ => HexAssessmentKind.goodCitySite,
    };
  }

  static HexAssessmentKind _plainsKind(_HexKindContext context) {
    return switch (context) {
      _ when context.hasFoodCityResource => HexAssessmentKind.idealCitySite,
      _ when context.hasBorderlandResource => HexAssessmentKind.strategicField,
      _ when context.hasRiver => HexAssessmentKind.fertilePlains,
      _ => HexAssessmentKind.goodCitySite,
    };
  }

  static HexAssessmentKind _forestKind(_HexKindContext context) {
    return switch (context) {
      _ when context.isRiverWildsSpot => HexAssessmentKind.richWilds,
      _ when context.hasForestForgeResource => HexAssessmentKind.forestForge,
      _ when context.has(ResourceType.deer) => HexAssessmentKind.forestBackline,
      _ when context.hasRiver => HexAssessmentKind.fertileForest,
      _ => HexAssessmentKind.defensivePosition,
    };
  }

  static HexAssessmentKind _jungleKind(_HexKindContext context) {
    return switch (context) {
      _ when context.has(ResourceType.oil) =>
        HexAssessmentKind.difficultStrategicTerrain,
      _ when context.isRiverWildsSpot => HexAssessmentKind.richWilds,
      _ when context.hasExoticResource => HexAssessmentKind.exoticBackline,
      _ when context.hasRiver => HexAssessmentKind.richWilds,
      _ => HexAssessmentKind.wildLand,
    };
  }

  static HexAssessmentKind _tundraKind(_HexKindContext context) {
    return switch (context) {
      _ when context.isColdStrategicSpot => HexAssessmentKind.resourceOutpost,
      _ when context.hasColdPastureResource => HexAssessmentKind.coldPastures,
      _ => HexAssessmentKind.harshLand,
    };
  }

  static HexAssessmentKind _snowKind(_HexKindContext context) {
    return switch (context) {
      _ when context.isColdStrategicSpot => HexAssessmentKind.arcticDeposits,
      _ => HexAssessmentKind.hostileLand,
    };
  }
}

final class _HexKindContext {
  _HexKindContext(HexAssessmentInput input)
    : terrain = input.baseTerrain,
      hasRiver = input.hasRiver,
      resources = input.resources.toSet();

  final TerrainType? terrain;
  final bool hasRiver;
  final Set<ResourceType> resources;

  bool get hasNoResources => resources.isEmpty;
  bool get isRegionalPortHeart => hasRiver && hasPortHeartResource;
  bool get isRiverFoodCitySpot {
    return (terrain == TerrainType.grassland ||
            terrain == TerrainType.plains) &&
        hasRiver &&
        hasFoodCityResource;
  }

  bool get isRiverWildsSpot {
    return (terrain == TerrainType.forest || terrain == TerrainType.jungle) &&
        hasRiver &&
        hasWildsResource;
  }

  bool get isTradeOasis => hasRiver && hasDesertTradeResource;
  bool get isColdStrategicSpot {
    return (terrain == TerrainType.tundra || terrain == TerrainType.snow) &&
        hasColdStrategicResource;
  }

  bool get hasFoodCityResource => hasAny(HexResourceGroups.foodCity);
  bool get hasPortHeartResource => hasAny(HexResourceGroups.portHeart);
  bool get hasIndustrialResource => hasAny(HexResourceGroups.industrial);
  bool get hasWildsResource => hasAny(HexResourceGroups.wilds);
  bool get hasDesertTradeResource => hasAny(HexResourceGroups.desertTrade);
  bool get hasColdStrategicResource => hasAny(HexResourceGroups.coldStrategic);
  bool get hasPlainLuxury => hasAny(HexResourceGroups.plainLuxury);
  bool get hasBorderlandResource => hasAny(HexResourceGroups.borderland);
  bool get hasHillWealth => hasAny(HexResourceGroups.hillWealth);
  bool get hasExoticResource => hasAny(HexResourceGroups.exotic);
  bool get hasForestForgeResource {
    return hasAny({ResourceType.iron, ResourceType.coal});
  }

  bool get hasColdPastureResource {
    return hasAny({ResourceType.deer, ResourceType.sheep});
  }

  bool has(ResourceType resource) => resources.contains(resource);

  bool hasAny(Set<ResourceType> expected) {
    return HexResourceGroups.hasAny(resources, expected);
  }
}
