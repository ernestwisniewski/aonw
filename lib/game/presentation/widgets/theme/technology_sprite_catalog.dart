import 'package:aonw/game/presentation/widgets/theme/sprite_atlas_icon.dart';
import 'package:aonw/shared/assets/preferred_image_assets.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';

abstract final class TechnologySpriteCatalog {
  static const String assetPath = PreferredImageAssets.technologyAtlas;
  static const int columns = 8;
  static const int rows = 7;

  static SpriteAtlasIconData iconFor(TechnologyId id) {
    final index = switch (id) {
      TechnologyId.agriculture => 0,
      TechnologyId.mining => 1,
      TechnologyId.hunting => 2,
      TechnologyId.woodworking => 3,
      TechnologyId.animalHusbandry => 4,
      TechnologyId.fishing => 5,
      TechnologyId.craftsmanship => 6,
      TechnologyId.trade => 7,
      TechnologyId.storage => 8,
      TechnologyId.waterEngineering => 9,
      TechnologyId.stoneworking => 10,
      TechnologyId.militaryOrganization => 11,
      TechnologyId.advancedTrade => 12,
      TechnologyId.construction => 13,
      TechnologyId.navigation => 14,
      TechnologyId.irrigation => 15,
      TechnologyId.banking => 16,
      TechnologyId.engineering => 17,
      TechnologyId.metallurgy => 18,
      TechnologyId.horsebackRiding => 19,
      TechnologyId.shipbuilding => 20,
      TechnologyId.administration => 21,
      TechnologyId.logistics => 22,
      TechnologyId.ironWorking => 23,
      TechnologyId.coalMining => 24,
      TechnologyId.machinery => 25,
      TechnologyId.tactics => 26,
      TechnologyId.economy => 27,
      TechnologyId.fortifications => 28,
      TechnologyId.urbanization => 29,
      TechnologyId.strategy => 30,
      TechnologyId.specialization => 31,
      TechnologyId.writing => 32,
      TechnologyId.mathematics => 33,
      TechnologyId.medicine => 34,
      TechnologyId.civilService => 35,
      TechnologyId.siegecraft => 36,
      TechnologyId.cartography => 37,
      TechnologyId.guilds => 38,
      TechnologyId.law => 39,
      TechnologyId.education => 40,
      TechnologyId.urbanPlanning => 41,
      TechnologyId.navalDoctrine => 42,
      TechnologyId.steel => 43,
      TechnologyId.bureaucracy => 44,
      TechnologyId.nationalism => 45,
      TechnologyId.scientificMethod => 46,
      TechnologyId.steamPower => 47,
      TechnologyId.electricity => 48,
      TechnologyId.combustion => 49,
      TechnologyId.flight => 50,
      TechnologyId.massProduction => 51,
      TechnologyId.radio => 52,
      TechnologyId.nuclearPhysics => 53,
    };
    return SpriteAtlasIconData(
      assetPath: assetPath,
      columns: columns,
      rows: rows,
      column: index % columns,
      row: index ~/ columns,
      cropToContent: false,
    );
  }
}

class TechnologySpriteIcon extends StatelessWidget {
  final TechnologyId id;
  final double size;
  final Widget? fallback;
  final double opacity;

  const TechnologySpriteIcon({
    required this.id,
    required this.size,
    this.fallback,
    this.opacity = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SpriteAtlasIcon(
      data: TechnologySpriteCatalog.iconFor(id),
      size: size,
      fallback: fallback,
      opacity: opacity,
    );
  }
}
