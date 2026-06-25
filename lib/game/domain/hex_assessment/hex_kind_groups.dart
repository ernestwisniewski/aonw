import 'package:aonw/game/domain/hex_assessment/hex_assessment_model.dart';

abstract final class HexKindGroups {
  static const city = {
    HexAssessmentKind.idealCitySite,
    HexAssessmentKind.goodCitySite,
    HexAssessmentKind.fertileField,
    HexAssessmentKind.fertilePlains,
    HexAssessmentKind.fertileForest,
    HexAssessmentKind.oasis,
    HexAssessmentKind.riverPort,
    HexAssessmentKind.regionalPortHeart,
  };

  static const defense = {
    HexAssessmentKind.defensivePosition,
    HexAssessmentKind.highGround,
    HexAssessmentKind.riverHills,
    HexAssessmentKind.industrialStronghold,
    HexAssessmentKind.forestForge,
    HexAssessmentKind.naturalBarrier,
  };

  static const economy = {
    HexAssessmentKind.richPlain,
    HexAssessmentKind.richWilds,
    HexAssessmentKind.exoticBackline,
    HexAssessmentKind.richHills,
    HexAssessmentKind.tradeOasis,
    HexAssessmentKind.desertDeposits,
    HexAssessmentKind.resourceOutpost,
    HexAssessmentKind.arcticDeposits,
    HexAssessmentKind.fishingCoast,
    HexAssessmentKind.richCoast,
    HexAssessmentKind.promisingLand,
  };

  static const production = {
    HexAssessmentKind.forestForge,
    HexAssessmentKind.industrialStronghold,
    HexAssessmentKind.highGround,
    HexAssessmentKind.riverHills,
  };

  static const fertile = {
    HexAssessmentKind.idealCitySite,
    HexAssessmentKind.fertileField,
    HexAssessmentKind.fertilePlains,
    HexAssessmentKind.fertileForest,
    HexAssessmentKind.forestBackline,
    HexAssessmentKind.richWilds,
    HexAssessmentKind.exoticBackline,
    HexAssessmentKind.coldPastures,
    HexAssessmentKind.fishingCoast,
  };

  static const avoid = {
    HexAssessmentKind.barrenLand,
    HexAssessmentKind.harshLand,
    HexAssessmentKind.hostileLand,
    HexAssessmentKind.openSea,
    HexAssessmentKind.naturalBarrier,
    HexAssessmentKind.weakLand,
    HexAssessmentKind.wildLand,
    HexAssessmentKind.difficultStrategicTerrain,
  };
}
