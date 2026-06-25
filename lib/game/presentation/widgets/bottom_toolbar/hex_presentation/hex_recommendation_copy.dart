import 'package:aonw/game/domain/hex_assessment.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

String hexRecommendationSubtitle(
  HexRecommendation recommendation,
  AppLocalizations l10n,
) {
  return switch (recommendation) {
    HexRecommendation.foundCity => l10n.hexRecommendationFoundCity,
    HexRecommendation.defendHere => l10n.hexRecommendationDefendHere,
    HexRecommendation.exploitEconomy => l10n.hexRecommendationExploitEconomy,
    HexRecommendation.avoid => l10n.hexRecommendationAvoid,
    HexRecommendation.neutral => l10n.hexRecommendationNeutral,
  };
}

String hexAssessmentDescription({
  required HexAssessmentKind kind,
  required HexRecommendation recommendation,
  required AppLocalizations l10n,
}) {
  return '${hexKindDescription(kind, l10n)} ${hexRecommendationDetail(recommendation, l10n)}';
}

String hexKindDescription(HexAssessmentKind kind, AppLocalizations l10n) {
  return switch (kind) {
    HexAssessmentKind.idealCitySite => l10n.hexKindIdealCitySiteDescription,
    HexAssessmentKind.goodCitySite => l10n.hexKindGoodCitySiteDescription,
    HexAssessmentKind.fertileField => l10n.hexKindFertileFieldDescription,
    HexAssessmentKind.fertilePlains => l10n.hexKindFertilePlainsDescription,
    HexAssessmentKind.richPlain => l10n.hexKindRichPlainDescription,
    HexAssessmentKind.strategicBorderland =>
      l10n.hexKindStrategicBorderlandDescription,
    HexAssessmentKind.strategicField => l10n.hexKindStrategicFieldDescription,
    HexAssessmentKind.defensivePosition =>
      l10n.hexKindDefensivePositionDescription,
    HexAssessmentKind.fertileForest => l10n.hexKindFertileForestDescription,
    HexAssessmentKind.forestBackline => l10n.hexKindForestBacklineDescription,
    HexAssessmentKind.forestForge => l10n.hexKindForestForgeDescription,
    HexAssessmentKind.wildLand => l10n.hexKindWildLandDescription,
    HexAssessmentKind.richWilds => l10n.hexKindRichWildsDescription,
    HexAssessmentKind.exoticBackline => l10n.hexKindExoticBacklineDescription,
    HexAssessmentKind.difficultStrategicTerrain =>
      l10n.hexKindDifficultStrategicTerrainDescription,
    HexAssessmentKind.highGround => l10n.hexKindHighGroundDescription,
    HexAssessmentKind.riverHills => l10n.hexKindRiverHillsDescription,
    HexAssessmentKind.industrialStronghold =>
      l10n.hexKindIndustrialStrongholdDescription,
    HexAssessmentKind.richHills => l10n.hexKindRichHillsDescription,
    HexAssessmentKind.barrenLand => l10n.hexKindBarrenLandDescription,
    HexAssessmentKind.oasis => l10n.hexKindOasisDescription,
    HexAssessmentKind.tradeOasis => l10n.hexKindTradeOasisDescription,
    HexAssessmentKind.desertDeposits => l10n.hexKindDesertDepositsDescription,
    HexAssessmentKind.harshLand => l10n.hexKindHarshLandDescription,
    HexAssessmentKind.coldPastures => l10n.hexKindColdPasturesDescription,
    HexAssessmentKind.resourceOutpost => l10n.hexKindResourceOutpostDescription,
    HexAssessmentKind.hostileLand => l10n.hexKindHostileLandDescription,
    HexAssessmentKind.arcticDeposits => l10n.hexKindArcticDepositsDescription,
    HexAssessmentKind.coast => l10n.hexKindCoastDescription,
    HexAssessmentKind.fishingCoast => l10n.hexKindFishingCoastDescription,
    HexAssessmentKind.richCoast => l10n.hexKindRichCoastDescription,
    HexAssessmentKind.riverPort => l10n.hexKindRiverPortDescription,
    HexAssessmentKind.regionalPortHeart =>
      l10n.hexKindRegionalPortHeartDescription,
    HexAssessmentKind.openSea => l10n.hexKindOpenSeaDescription,
    HexAssessmentKind.naturalBarrier => l10n.hexKindNaturalBarrierDescription,
    HexAssessmentKind.promisingLand => l10n.hexKindPromisingLandDescription,
    HexAssessmentKind.weakLand => l10n.hexKindWeakLandDescription,
    HexAssessmentKind.ordinaryLand => l10n.hexKindOrdinaryLandDescription,
    HexAssessmentKind.mapTile => l10n.hexKindMapTileDescription,
  };
}

String hexRecommendationDetail(
  HexRecommendation recommendation,
  AppLocalizations l10n,
) {
  return switch (recommendation) {
    HexRecommendation.foundCity => l10n.hexRecommendationFoundCityDetail,
    HexRecommendation.defendHere => l10n.hexRecommendationDefendHereDetail,
    HexRecommendation.exploitEconomy =>
      l10n.hexRecommendationExploitEconomyDetail,
    HexRecommendation.avoid => l10n.hexRecommendationAvoidDetail,
    HexRecommendation.neutral => l10n.hexRecommendationNeutralDetail,
  };
}
