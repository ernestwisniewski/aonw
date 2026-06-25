import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';

enum CityTileYieldContributionKind {
  center,
  population,
  worker,
  passiveImprovement,
  artifact,
}

class CityTileYieldContribution {
  final CityTileYieldContributionKind kind;
  final CityHex hex;
  final TileYield yield;

  const CityTileYieldContribution({
    required this.kind,
    required this.hex,
    required this.yield,
  });
}

class CityTileYieldBreakdown {
  final CityTileYieldContribution center;
  final List<CityTileYieldContribution> population;
  final List<CityTileYieldContribution> workers;
  final List<CityTileYieldContribution> passiveImprovements;
  final List<CityTileYieldContribution> artifacts;

  const CityTileYieldBreakdown({
    required this.center,
    this.population = const [],
    this.workers = const [],
    this.passiveImprovements = const [],
    this.artifacts = const [],
  });

  TileYield get centerYield => center.yield;

  TileYield get populationYield => _sum(population);

  TileYield get workerYield => _sum(workers);

  TileYield get passiveImprovementYield => _sum(passiveImprovements);

  TileYield get artifactYield => _sum(artifacts);

  TileYield get total =>
      centerYield +
      populationYield +
      workerYield +
      passiveImprovementYield +
      artifactYield;

  List<CityTileYieldContribution> get allContributions => [
    center,
    ...population,
    ...workers,
    ...passiveImprovements,
    ...artifacts,
  ];

  static TileYield _sum(Iterable<CityTileYieldContribution> contributions) {
    var total = TileYield.zero;
    for (final contribution in contributions) {
      total = total + contribution.yield;
    }
    return total;
  }
}
