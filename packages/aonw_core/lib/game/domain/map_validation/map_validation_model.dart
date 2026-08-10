import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';

enum MapValidationSeverity { error, warning }

class MapValidationIssue {
  final MapValidationSeverity severity;
  final String code;
  final String message;
  final HexCoordinate? coordinate;

  const MapValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.coordinate,
  });

  bool get isError => severity == MapValidationSeverity.error;

  bool get isWarning => severity == MapValidationSeverity.warning;
}

class MapResourceSummary {
  final int resourceTiles;
  final int foodResources;
  final int luxuryResources;
  final int strategicResources;

  const MapResourceSummary({
    required this.resourceTiles,
    required this.foodResources,
    required this.luxuryResources,
    required this.strategicResources,
  });
}

class MapStartSiteReport {
  final int playerIndex;
  final HexCoordinate warrior;
  final HexCoordinate settler;
  final int passableTilesInFirstRing;
  final int foodResourcesInFirstRing;
  final int controlledCandidates;

  const MapStartSiteReport({
    required this.playerIndex,
    required this.warrior,
    required this.settler,
    required this.passableTilesInFirstRing,
    required this.foodResourcesInFirstRing,
    required this.controlledCandidates,
  });
}

class MapValidationResult {
  final String mapName;
  final int playerCount;
  final int totalTiles;
  final int passableTiles;
  final MapResourceSummary resources;
  final List<MapStartSiteReport> startSites;
  final List<MapValidationIssue> issues;

  MapValidationResult({
    required this.mapName,
    required this.playerCount,
    required this.totalTiles,
    required this.passableTiles,
    required this.resources,
    required Iterable<MapStartSiteReport> startSites,
    required Iterable<MapValidationIssue> issues,
  }) : startSites = List.unmodifiable(startSites),
       issues = List.unmodifiable(issues);

  bool get isValid => errors.isEmpty;

  List<MapValidationIssue> get errors =>
      issues.where((issue) => issue.isError).toList(growable: false);

  List<MapValidationIssue> get warnings =>
      issues.where((issue) => issue.isWarning).toList(growable: false);
}

class MapValidationRules {
  final int minPlayerCount;
  final int maxPlayerCount;
  final double minPassableTileRatio;
  final int minPassableTilesInFirstRing;
  final int minFoodResourcesInFirstRing;
  final int minControlledCandidates;
  final int minStartDistance;
  final int maxShortGameStartDistance;
  final int maxShortGameTilesPerPlayer;
  final int minFoodResourcesPerPlayer;
  final int minStrategicResources;
  final int minLuxuryResources;

  const MapValidationRules({
    this.minPlayerCount = 2,
    this.maxPlayerCount = 4,
    this.minPassableTileRatio = 0.45,
    this.minPassableTilesInFirstRing = 4,
    this.minFoodResourcesInFirstRing = 1,
    this.minControlledCandidates = CityFoundingDraft.requiredControlledHexes,
    this.minStartDistance = 6,
    this.maxShortGameStartDistance = 14,
    this.maxShortGameTilesPerPlayer = 180,
    this.minFoodResourcesPerPlayer = 2,
    this.minStrategicResources = 2,
    this.minLuxuryResources = 2,
  });
}
