import 'package:aonw/game/domain/hex_assessment.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class HexKindPresentation {
  final String label;
  final GameIconData icon;
  final Color color;

  const HexKindPresentation({
    required this.label,
    required this.icon,
    required this.color,
  });
}

HexKindPresentation presentationForHexKind(
  HexAssessmentKind kind,
  AppLocalizations l10n,
) {
  return switch (kind) {
    HexAssessmentKind.idealCitySite => HexKindPresentation(
      label: l10n.hexKindIdealCitySite,
      icon: GameIcons.city,
      color: const Color(0xFF87c96a),
    ),
    HexAssessmentKind.goodCitySite => HexKindPresentation(
      label: l10n.hexKindGoodCitySite,
      icon: GameIcons.city,
      color: const Color(0xFF87c96a),
    ),
    HexAssessmentKind.fertileField => HexKindPresentation(
      label: l10n.hexKindFertileField,
      icon: GameIcons.leaf,
      color: const Color(0xFF87c96a),
    ),
    HexAssessmentKind.fertilePlains => HexKindPresentation(
      label: l10n.hexKindFertilePlains,
      icon: GameIcons.leaf,
      color: const Color(0xFF87c96a),
    ),
    HexAssessmentKind.richPlain => HexKindPresentation(
      label: l10n.hexKindRichPlain,
      icon: GameIcons.route,
      color: const Color(0xFFe0c35c),
    ),
    HexAssessmentKind.strategicBorderland => HexKindPresentation(
      label: l10n.hexKindStrategicBorderland,
      icon: GameIcons.flag,
      color: const Color(0xFFd48f74),
    ),
    HexAssessmentKind.strategicField => HexKindPresentation(
      label: l10n.hexKindStrategicField,
      icon: GameIcons.flag,
      color: const Color(0xFFd48f74),
    ),
    HexAssessmentKind.defensivePosition => HexKindPresentation(
      label: l10n.hexKindDefensivePosition,
      icon: GameIcons.defense,
      color: const Color(0xFF8da8e8),
    ),
    HexAssessmentKind.fertileForest => HexKindPresentation(
      label: l10n.hexKindFertileForest,
      icon: GameIcons.forest,
      color: const Color(0xFF87c96a),
    ),
    HexAssessmentKind.forestBackline => HexKindPresentation(
      label: l10n.hexKindForestBackline,
      icon: GameIcons.forest,
      color: const Color(0xFF87c96a),
    ),
    HexAssessmentKind.forestForge => HexKindPresentation(
      label: l10n.hexKindForestForge,
      icon: GameIcons.production,
      color: const Color(0xFFc9a95f),
    ),
    HexAssessmentKind.wildLand => HexKindPresentation(
      label: l10n.hexKindWildLand,
      icon: GameIcons.warning,
      color: const Color(0xFFd48f74),
    ),
    HexAssessmentKind.richWilds => HexKindPresentation(
      label: l10n.hexKindRichWilds,
      icon: GameIcons.leaf,
      color: const Color(0xFF87c96a),
    ),
    HexAssessmentKind.exoticBackline => HexKindPresentation(
      label: l10n.hexKindExoticBackline,
      icon: GameIcons.leaf,
      color: const Color(0xFF87c96a),
    ),
    HexAssessmentKind.difficultStrategicTerrain => HexKindPresentation(
      label: l10n.hexKindDifficultStrategicTerrain,
      icon: GameIcons.flag,
      color: const Color(0xFFd48f74),
    ),
    HexAssessmentKind.highGround => HexKindPresentation(
      label: l10n.hexKindHighGround,
      icon: GameIcons.defense,
      color: const Color(0xFF8da8e8),
    ),
    HexAssessmentKind.riverHills => HexKindPresentation(
      label: l10n.hexKindRiverHills,
      icon: GameIcons.defense,
      color: const Color(0xFF8da8e8),
    ),
    HexAssessmentKind.industrialStronghold => HexKindPresentation(
      label: l10n.hexKindIndustrialStronghold,
      icon: GameIcons.production,
      color: const Color(0xFFc9a95f),
    ),
    HexAssessmentKind.richHills => HexKindPresentation(
      label: l10n.hexKindRichHills,
      icon: GameIcons.gold,
      color: const Color(0xFFe0c35c),
    ),
    HexAssessmentKind.barrenLand => HexKindPresentation(
      label: l10n.hexKindBarrenLand,
      icon: GameIcons.warning,
      color: const Color(0xFFd48f74),
    ),
    HexAssessmentKind.oasis => HexKindPresentation(
      label: l10n.hexKindOasis,
      icon: GameIcons.water,
      color: const Color(0xFF87c96a),
    ),
    HexAssessmentKind.tradeOasis => HexKindPresentation(
      label: l10n.hexKindTradeOasis,
      icon: GameIcons.route,
      color: const Color(0xFFe0c35c),
    ),
    HexAssessmentKind.desertDeposits => HexKindPresentation(
      label: l10n.hexKindDesertDeposits,
      icon: GameIcons.flag,
      color: const Color(0xFFd48f74),
    ),
    HexAssessmentKind.harshLand => HexKindPresentation(
      label: l10n.hexKindHarshLand,
      icon: GameIcons.snow,
      color: const Color(0xFFd48f74),
    ),
    HexAssessmentKind.coldPastures => HexKindPresentation(
      label: l10n.hexKindColdPastures,
      icon: GameIcons.snow,
      color: const Color(0xFF87c96a),
    ),
    HexAssessmentKind.resourceOutpost => HexKindPresentation(
      label: l10n.hexKindResourceOutpost,
      icon: GameIcons.flag,
      color: const Color(0xFFd48f74),
    ),
    HexAssessmentKind.hostileLand => HexKindPresentation(
      label: l10n.hexKindHostileLand,
      icon: GameIcons.warning,
      color: const Color(0xFFd48f74),
    ),
    HexAssessmentKind.arcticDeposits => HexKindPresentation(
      label: l10n.hexKindArcticDeposits,
      icon: GameIcons.flag,
      color: const Color(0xFFd48f74),
    ),
    HexAssessmentKind.coast => HexKindPresentation(
      label: l10n.hexKindCoast,
      icon: GameIcons.water,
      color: const Color(0xFF7a9fc4),
    ),
    HexAssessmentKind.fishingCoast => HexKindPresentation(
      label: l10n.hexKindFishingCoast,
      icon: GameIcons.fish,
      color: const Color(0xFF7a9fc4),
    ),
    HexAssessmentKind.richCoast => HexKindPresentation(
      label: l10n.hexKindRichCoast,
      icon: GameIcons.gold,
      color: const Color(0xFFe0c35c),
    ),
    HexAssessmentKind.riverPort => HexKindPresentation(
      label: l10n.hexKindRiverPort,
      icon: GameIcons.ship,
      color: const Color(0xFF7a9fc4),
    ),
    HexAssessmentKind.regionalPortHeart => HexKindPresentation(
      label: l10n.hexKindRegionalPortHeart,
      icon: GameIcons.ship,
      color: const Color(0xFF7a9fc4),
    ),
    HexAssessmentKind.openSea => HexKindPresentation(
      label: l10n.hexKindOpenSea,
      icon: GameIcons.water,
      color: const Color(0xFF7a9fc4),
    ),
    HexAssessmentKind.naturalBarrier => HexKindPresentation(
      label: l10n.hexKindNaturalBarrier,
      icon: GameIcons.terrain,
      color: const Color(0xFF8da8e8),
    ),
    HexAssessmentKind.promisingLand => HexKindPresentation(
      label: l10n.hexKindPromisingLand,
      icon: GameIcons.route,
      color: const Color(0xFFe0c35c),
    ),
    HexAssessmentKind.weakLand => HexKindPresentation(
      label: l10n.hexKindWeakLand,
      icon: GameIcons.warning,
      color: const Color(0xFFd48f74),
    ),
    HexAssessmentKind.ordinaryLand => HexKindPresentation(
      label: l10n.hexKindOrdinaryLand,
      icon: GameIcons.terrain,
      color: const Color(0xFF89b66f),
    ),
    HexAssessmentKind.mapTile => HexKindPresentation(
      label: l10n.hexKindMapTile,
      icon: GameIcons.terrain,
      color: const Color(0xFF89b66f),
    ),
  };
}
