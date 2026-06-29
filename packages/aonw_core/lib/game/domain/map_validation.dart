import 'dart:math' as math;

import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/terrain.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

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

abstract final class MapValidator {
  static const MapValidationRules defaultRules = MapValidationRules();

  static MapValidationResult validate({
    required MapData mapData,
    required int playerCount,
    GameLengthConfig gameLength = GameLengthConfig.unlimited,
    MapValidationRules rules = defaultRules,
  }) {
    final issues = <MapValidationIssue>[];
    final mapName = mapData.mapName ?? 'unnamed';
    final totalTiles = mapData.tiles.length;
    final passableTiles = mapData.tiles.where(_isPassable).length;
    final resources = _resourceSummary(mapData);

    if (playerCount < rules.minPlayerCount ||
        playerCount > rules.maxPlayerCount) {
      issues.add(
        MapValidationIssue(
          severity: MapValidationSeverity.error,
          code: 'invalid_player_count',
          message:
              '$mapName supports ${rules.minPlayerCount}-${rules.maxPlayerCount} players, got $playerCount.',
        ),
      );
    }
    if (totalTiles == 0) {
      issues.add(
        MapValidationIssue(
          severity: MapValidationSeverity.error,
          code: 'map_has_no_tiles',
          message: '$mapName has no tiles.',
        ),
      );
    } else {
      final passableRatio = passableTiles / totalTiles;
      if (passableRatio < rules.minPassableTileRatio) {
        issues.add(
          MapValidationIssue(
            severity: MapValidationSeverity.error,
            code: 'low_passable_tile_ratio',
            message:
                '$mapName has ${(passableRatio * 100).round()}% passable tiles; expected at least ${(rules.minPassableTileRatio * 100).round()}%.',
          ),
        );
      }
    }

    _validateResourceDensity(
      mapName: mapName,
      playerCount: playerCount,
      resources: resources,
      issues: issues,
      rules: rules,
    );

    final startSites = _startSites(
      mapName: mapName,
      mapData: mapData,
      playerCount: playerCount,
      issues: issues,
    );
    _validateStartSites(
      mapName: mapName,
      mapData: mapData,
      startSites: startSites,
      issues: issues,
      rules: rules,
    );
    _validateFirstContact(
      mapName: mapName,
      mapData: mapData,
      playerCount: playerCount,
      startSites: startSites,
      gameLength: gameLength,
      issues: issues,
      rules: rules,
    );

    return MapValidationResult(
      mapName: mapName,
      playerCount: playerCount,
      totalTiles: totalTiles,
      passableTiles: passableTiles,
      resources: resources,
      startSites: startSites,
      issues: issues,
    );
  }

  static void _validateResourceDensity({
    required String mapName,
    required int playerCount,
    required MapResourceSummary resources,
    required List<MapValidationIssue> issues,
    required MapValidationRules rules,
  }) {
    final requiredFood = playerCount * rules.minFoodResourcesPerPlayer;
    final requiredStrategic = math.max(
      rules.minStrategicResources,
      playerCount,
    );
    final requiredLuxury = math.max(rules.minLuxuryResources, playerCount);

    if (resources.foodResources < requiredFood) {
      issues.add(
        MapValidationIssue(
          severity: MapValidationSeverity.error,
          code: 'low_food_resource_density',
          message:
              '$mapName has ${resources.foodResources} food resources; expected at least $requiredFood for $playerCount players.',
        ),
      );
    }
    if (resources.strategicResources < requiredStrategic) {
      issues.add(
        MapValidationIssue(
          severity: MapValidationSeverity.error,
          code: 'low_strategic_resource_density',
          message:
              '$mapName has ${resources.strategicResources} strategic resources; expected at least $requiredStrategic.',
        ),
      );
    }
    if (resources.luxuryResources < requiredLuxury) {
      issues.add(
        MapValidationIssue(
          severity: MapValidationSeverity.error,
          code: 'low_luxury_resource_density',
          message:
              '$mapName has ${resources.luxuryResources} luxury resources; expected at least $requiredLuxury.',
        ),
      );
    }
  }

  static void _validateStartSites({
    required String mapName,
    required MapData mapData,
    required List<MapStartSiteReport> startSites,
    required List<MapValidationIssue> issues,
    required MapValidationRules rules,
  }) {
    for (final site in startSites) {
      final settlerTile = mapData.tileAt(site.settler.col, site.settler.row);
      if (settlerTile == null || !CitySiteRules.canFoundCityOn(settlerTile)) {
        issues.add(
          MapValidationIssue(
            severity: MapValidationSeverity.error,
            code: 'start_site_not_foundable',
            coordinate: site.settler,
            message:
                '$mapName player ${site.playerIndex + 1} starts on a tile where a city cannot be founded.',
          ),
        );
      }
      if (site.passableTilesInFirstRing < rules.minPassableTilesInFirstRing) {
        issues.add(
          MapValidationIssue(
            severity: MapValidationSeverity.error,
            code: 'start_site_low_land_ring',
            coordinate: site.settler,
            message:
                '$mapName player ${site.playerIndex + 1} has ${site.passableTilesInFirstRing} passable first-ring tiles; expected at least ${rules.minPassableTilesInFirstRing}.',
          ),
        );
      }
      if (site.foodResourcesInFirstRing < rules.minFoodResourcesInFirstRing) {
        issues.add(
          MapValidationIssue(
            severity: MapValidationSeverity.error,
            code: 'start_site_low_food',
            coordinate: site.settler,
            message:
                '$mapName player ${site.playerIndex + 1} has no visible food resource near the initial settler.',
          ),
        );
      }
      if (site.controlledCandidates < rules.minControlledCandidates) {
        issues.add(
          MapValidationIssue(
            severity: MapValidationSeverity.error,
            code: 'start_site_low_city_control',
            coordinate: site.settler,
            message:
                '$mapName player ${site.playerIndex + 1} has ${site.controlledCandidates} valid controlled hex candidates; expected at least ${rules.minControlledCandidates}.',
          ),
        );
      }
    }
  }

  static void _validateFirstContact({
    required String mapName,
    required MapData mapData,
    required int playerCount,
    required List<MapStartSiteReport> startSites,
    required GameLengthConfig gameLength,
    required List<MapValidationIssue> issues,
    required MapValidationRules rules,
  }) {
    if (startSites.length < 2) return;

    var maxDistance = 0;
    for (var i = 0; i < startSites.length; i++) {
      for (var j = i + 1; j < startSites.length; j++) {
        final distance = HexDistance.between(
          startSites[i].settler,
          startSites[j].settler,
        );
        if (distance > maxDistance) maxDistance = distance;
        if (distance < rules.minStartDistance) {
          issues.add(
            MapValidationIssue(
              severity: MapValidationSeverity.error,
              code: 'start_sites_too_close',
              message:
                  '$mapName players ${i + 1} and ${j + 1} start $distance hexes apart; expected at least ${rules.minStartDistance}.',
            ),
          );
        }
      }
    }

    if (!_isShortGame(gameLength)) return;
    if (maxDistance > rules.maxShortGameStartDistance) {
      issues.add(
        MapValidationIssue(
          severity: MapValidationSeverity.warning,
          code: 'short_game_slow_first_contact',
          message:
              '$mapName has max start distance $maxDistance, so 60m games may feel too quiet.',
        ),
      );
    }
    final tilesPerPlayer = mapData.tiles.length / playerCount;
    if (tilesPerPlayer > rules.maxShortGameTilesPerPlayer) {
      issues.add(
        MapValidationIssue(
          severity: MapValidationSeverity.warning,
          code: 'short_game_large_map',
          message:
              '$mapName has ${tilesPerPlayer.round()} tiles per player; 60m games should use more players or a smaller map.',
        ),
      );
    }
  }

  static List<MapStartSiteReport> _startSites({
    required String mapName,
    required MapData mapData,
    required int playerCount,
    required List<MapValidationIssue> issues,
  }) {
    if (playerCount <= 0) return const [];
    final players = [for (var i = 0; i < playerCount; i++) Player.forIndex(i)];
    final units = StartingUnits.unitsForPlayers(players, mapData: mapData);
    final reports = <MapStartSiteReport>[];
    for (var i = 0; i < playerCount; i++) {
      final playerId = players[i].id;
      final warrior = _unitFor(
        units,
        ownerPlayerId: playerId,
        type: GameUnitType.warrior,
      );
      final settler = _unitFor(
        units,
        ownerPlayerId: playerId,
        type: GameUnitType.settler,
      );
      if (warrior == null || settler == null) {
        _addMissingStartingUnitIssues(
          mapName: mapName,
          playerIndex: i,
          playerId: playerId,
          warrior: warrior,
          settler: settler,
          issues: issues,
        );
        continue;
      }
      reports.add(
        _startSiteReport(
          playerIndex: i,
          mapData: mapData,
          warrior: warrior,
          settler: settler,
        ),
      );
    }
    return reports;
  }

  static void _addMissingStartingUnitIssues({
    required String mapName,
    required int playerIndex,
    required String playerId,
    required GameUnit? warrior,
    required GameUnit? settler,
    required List<MapValidationIssue> issues,
  }) {
    if (warrior == null) {
      issues.add(
        MapValidationIssue(
          severity: MapValidationSeverity.error,
          code: 'starting_unit_missing',
          message:
              '$mapName player ${playerIndex + 1} is missing a warrior starting unit ($playerId).',
        ),
      );
    }
    if (settler == null) {
      issues.add(
        MapValidationIssue(
          severity: MapValidationSeverity.error,
          code: 'starting_unit_missing',
          message:
              '$mapName player ${playerIndex + 1} is missing a settler starting unit ($playerId).',
        ),
      );
    }
  }

  static MapStartSiteReport _startSiteReport({
    required int playerIndex,
    required MapData mapData,
    required GameUnit warrior,
    required GameUnit settler,
  }) {
    final settlerCoordinate = HexCoordinate(col: settler.col, row: settler.row);
    final firstRing = [
      ?mapData.tileAt(settler.col, settler.row),
      for (final neighbor in HexNeighbors.existingAround(
        settlerCoordinate,
        mapData,
      ))
        ?mapData.tileAt(neighbor.col, neighbor.row),
    ];
    final draft = CityFoundingDraft(
      unitId: settler.id,
      ownerPlayerId: settler.ownerPlayerId,
      center: CityHex(col: settler.col, row: settler.row),
    );
    var controlledCandidates = 0;
    for (final tile in mapData.tiles) {
      final distance = HexDistance.between(
        settlerCoordinate,
        HexCoordinate(col: tile.col, row: tile.row),
      );
      if (distance > CityFoundingDraft.maxRadius) continue;
      if (CityFoundingRules.isControlledHexCandidate(
        draft: draft,
        tile: tile,
        mapData: mapData,
      )) {
        controlledCandidates++;
      }
    }

    return MapStartSiteReport(
      playerIndex: playerIndex,
      warrior: HexCoordinate(col: warrior.col, row: warrior.row),
      settler: settlerCoordinate,
      passableTilesInFirstRing: firstRing.where(_isPassable).length,
      foodResourcesInFirstRing: firstRing
          .expand((tile) => tile.resources)
          .where(_isFoodResource)
          .length,
      controlledCandidates: controlledCandidates,
    );
  }

  static GameUnit? _unitFor(
    Iterable<GameUnit> units, {
    required String ownerPlayerId,
    required GameUnitType type,
  }) {
    for (final unit in units) {
      if (unit.ownerPlayerId == ownerPlayerId && unit.type == type) {
        return unit;
      }
    }
    return null;
  }

  static MapResourceSummary _resourceSummary(MapData mapData) {
    var resourceTiles = 0;
    var foodResources = 0;
    var luxuryResources = 0;
    var strategicResources = 0;
    for (final tile in mapData.tiles) {
      if (tile.resources.isNotEmpty) resourceTiles++;
      for (final resource in tile.resources) {
        if (_isFoodResource(resource)) foodResources++;
        if (_isLuxuryResource(resource)) luxuryResources++;
        if (_isStrategicResource(resource)) strategicResources++;
      }
    }
    return MapResourceSummary(
      resourceTiles: resourceTiles,
      foodResources: foodResources,
      luxuryResources: luxuryResources,
      strategicResources: strategicResources,
    );
  }

  static bool _isPassable(TileData tile) {
    return !UnitMovementCostRules.costToEnter(
      TileTerrainProfileRules.fromTile(tile),
    ).blocked;
  }

  static bool _isShortGame(GameLengthConfig gameLength) {
    return gameLength.paceProfile == PaceProfile.standard60;
  }

  static bool _isFoodResource(ResourceType resource) {
    return switch (resource) {
      ResourceType.wheat ||
      ResourceType.fish ||
      ResourceType.deer ||
      ResourceType.sheep ||
      ResourceType.rice ||
      ResourceType.cow ||
      ResourceType.apple ||
      ResourceType.banana ||
      ResourceType.citrus => true,
      _ => false,
    };
  }

  static bool _isLuxuryResource(ResourceType resource) {
    return switch (resource) {
      ResourceType.gold ||
      ResourceType.silver ||
      ResourceType.gems ||
      ResourceType.silk ||
      ResourceType.spices ||
      ResourceType.cotton ||
      ResourceType.grapes ||
      ResourceType.ivory ||
      ResourceType.pearls ||
      ResourceType.coffee ||
      ResourceType.cocoa ||
      ResourceType.tobacco ||
      ResourceType.sugar => true,
      _ => false,
    };
  }

  static bool _isStrategicResource(ResourceType resource) {
    return switch (resource) {
      ResourceType.iron ||
      ResourceType.coal ||
      ResourceType.oil ||
      ResourceType.aluminium ||
      ResourceType.uranium ||
      ResourceType.horses ||
      ResourceType.marble => true,
      _ => false,
    };
  }
}
