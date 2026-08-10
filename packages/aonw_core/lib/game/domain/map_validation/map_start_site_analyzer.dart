import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/map_validation/map_resource_analyzer.dart';
import 'package:aonw_core/game/domain/map_validation/map_validation_model.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class MapStartSiteAnalyzer {
  static List<MapStartSiteReport> reportsFor({
    required String mapName,
    required WorldMap mapData,
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
    required WorldMap mapData,
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
        mapTiles: mapData,
      )) {
        controlledCandidates++;
      }
    }

    return MapStartSiteReport(
      playerIndex: playerIndex,
      warrior: HexCoordinate(col: warrior.col, row: warrior.row),
      settler: settlerCoordinate,
      passableTilesInFirstRing: firstRing
          .where(MapResourceAnalyzer.isPassable)
          .length,
      foodResourcesInFirstRing: firstRing
          .expand((tile) => tile.resources)
          .where(MapResourceAnalyzer.isFoodResource)
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
}
