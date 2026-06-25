import 'package:aonw/game/domain/hex_assessment/hex_score.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';

enum HexAssessmentKind {
  idealCitySite,
  goodCitySite,
  fertileField,
  fertilePlains,
  richPlain,
  strategicBorderland,
  strategicField,
  defensivePosition,
  fertileForest,
  forestBackline,
  forestForge,
  wildLand,
  richWilds,
  exoticBackline,
  difficultStrategicTerrain,
  highGround,
  riverHills,
  industrialStronghold,
  richHills,
  barrenLand,
  oasis,
  tradeOasis,
  desertDeposits,
  harshLand,
  coldPastures,
  resourceOutpost,
  hostileLand,
  arcticDeposits,
  coast,
  fishingCoast,
  richCoast,
  riverPort,
  regionalPortHeart,
  openSea,
  naturalBarrier,
  promisingLand,
  weakLand,
  ordinaryLand,
  mapTile,
}

enum HexRecommendation { foundCity, defendHere, exploitEconomy, avoid, neutral }

enum HexAssessmentTag {
  city,
  defense,
  trade,
  fertile,
  production,
  hostile,
  strategic,
  water,
}

class HexAssessment {
  final TerrainType? baseTerrain;
  final bool hasRiver;
  final bool canFoundCity;
  final TileYield yield;
  final HexScore score;
  final HexAssessmentKind kind;
  final HexRecommendation recommendation;
  final List<HexAssessmentTag> tags;

  const HexAssessment({
    required this.baseTerrain,
    required this.hasRiver,
    required this.canFoundCity,
    required this.yield,
    required this.score,
    required this.kind,
    required this.recommendation,
    required this.tags,
  });
}
