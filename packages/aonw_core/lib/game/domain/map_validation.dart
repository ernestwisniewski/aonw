import 'dart:math' as math;

import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/map_validation/map_resource_analyzer.dart';
import 'package:aonw_core/game/domain/map_validation/map_start_site_analyzer.dart';
import 'package:aonw_core/game/domain/map_validation/map_validation_model.dart';
import 'package:aonw_core/game/domain/match_rules.dart';

export 'map_validation/map_validation_model.dart';

abstract final class MapValidator {
  static const MapValidationRules defaultRules = MapValidationRules();

  static MapValidationResult validate({
    required WorldMap mapData,
    required int playerCount,
    GameLengthConfig gameLength = GameLengthConfig.unlimited,
    MapValidationRules rules = defaultRules,
  }) {
    final issues = <MapValidationIssue>[];
    final mapName = mapData.mapName ?? 'unnamed';
    final totalTiles = mapData.tiles.length;
    final passableTiles = MapResourceAnalyzer.passableTileCount(mapData);
    final resources = MapResourceAnalyzer.summary(mapData);

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

    final startSites = MapStartSiteAnalyzer.reportsFor(
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
    required WorldMap mapData,
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
    required WorldMap mapData,
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

  static bool _isShortGame(GameLengthConfig gameLength) {
    return gameLength.paceProfile == PaceProfile.standard60;
  }
}
