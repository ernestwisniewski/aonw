import 'package:aonw_core/ai/city_founding_safety.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

final class MctsFoundingCandidateCollector {
  const MctsFoundingCandidateCollector();

  int candidateReserve(GameView view, int candidateLimit) {
    if (candidateLimit < 6) return 0;
    for (final unit in view.ownUnits) {
      if (_isReadyFounder(unit)) {
        return candidateLimit < 10 ? 2 : 4;
      }
    }
    return 0;
  }

  Iterable<GameCommand> foundingCommandsFor(GameView view) {
    final founders = [
      for (final unit in view.ownUnits)
        if (_isReadyFounder(unit)) unit,
    ]..sort((a, b) => a.id.compareTo(b.id));
    if (founders.isEmpty) return const [];

    final cities = _knownCities(view);
    final commands = <GameCommand>[];
    for (final founder in founders) {
      final centerTile = view.mapData.tileAt(founder.col, founder.row);
      if (centerTile == null) continue;
      if (CityFoundingRules.startFailure(
            unit: founder,
            centerTile: centerTile,
            cities: cities,
          ) !=
          null) {
        continue;
      }

      final center = CityHex(col: founder.col, row: founder.row);
      if (!AiCityFoundingSafety.hasKnownCenterExclusionZone(
        view: view,
        center: center,
      )) {
        continue;
      }

      final draft = CityFoundingDraft(
        unitId: founder.id,
        ownerPlayerId: founder.ownerPlayerId,
        center: center,
      );
      final visibleResourceTypes = _visibleResourceTypes(view);
      final controlledCandidates = <({CityHex hex, double score})>[];
      for (final neighbor in HexNeighbors.existingAround(
        HexCoordinate(col: founder.col, row: founder.row),
        view.mapData,
      )) {
        final tile = view.mapData.tileAt(neighbor.col, neighbor.row);
        if (tile == null) continue;
        if (!CityFoundingRules.isControlledHexCandidate(
          draft: draft,
          tile: tile,
          mapData: view.mapData,
          cities: cities,
        )) {
          continue;
        }
        controlledCandidates.add((
          hex: CityHex(col: neighbor.col, row: neighbor.row),
          score: _foundingControlledHexScore(tile, visibleResourceTypes),
        ));
      }
      controlledCandidates.sort((left, right) {
        final score = right.score.compareTo(left.score);
        if (score != 0) return score;
        final col = left.hex.col.compareTo(right.hex.col);
        if (col != 0) return col;
        return left.hex.row.compareTo(right.hex.row);
      });

      final controlledHexes = [
        for (final candidate in controlledCandidates.take(
          CityFoundingDraft.requiredControlledHexes,
        ))
          candidate.hex,
      ];
      if (controlledHexes.length < CityFoundingDraft.requiredControlledHexes) {
        continue;
      }

      commands.add(
        FoundCityCommand(founder.id, controlledHexes: controlledHexes),
      );
    }
    return commands;
  }

  Iterable<GameCommand> spacingMovementCommandsFor(GameView view) {
    if (view.ownCities.length < 2) return const [];

    final founders = [
      for (final unit in view.ownUnits)
        if (_isReadyFounder(unit)) unit,
    ]..sort((a, b) => a.id.compareTo(b.id));
    if (founders.isEmpty) return const [];

    final commands = <GameCommand>[];
    final knownUnits = view.movementBlockingUnits;
    final pathfinder = UnitMovementPathfinder(
      mapData: view.mapData,
      units: knownUnits,
    );
    for (final founder in founders) {
      final currentDistance = _nearestOwnCityDistance(
        view,
        founder.col,
        founder.row,
      );
      if (currentDistance >= CityFoundingRules.minimumCenterDistance) {
        continue;
      }

      final origin = HexCoordinate(col: founder.col, row: founder.row);
      final visibleResourceTypes = _visibleResourceTypes(view);
      final options = <({HexCoordinate target, double score})>[];
      for (final neighbor in HexNeighbors.existingAround(
        origin,
        view.mapData,
      )) {
        final tile = view.mapData.tileAt(neighbor.col, neighbor.row);
        if (tile == null) continue;
        final targetDistance = _nearestOwnCityDistance(
          view,
          neighbor.col,
          neighbor.row,
        );
        if (targetDistance <= currentDistance) continue;
        final occupied = knownUnits.any(
          (unit) =>
              unit.id != founder.id &&
              unit.col == neighbor.col &&
              unit.row == neighbor.row,
        );
        if (occupied) continue;
        final plan = pathfinder.plan(unit: founder, targetTile: tile);
        if (plan == null || !plan.canMoveNow) continue;
        options.add((
          target: neighbor,
          score:
              targetDistance * 12 +
              _foundingControlledHexScore(tile, visibleResourceTypes),
        ));
      }
      options.sort((left, right) {
        final score = right.score.compareTo(left.score);
        if (score != 0) return score;
        final col = left.target.col.compareTo(right.target.col);
        if (col != 0) return col;
        return left.target.row.compareTo(right.target.row);
      });

      for (final option in options) {
        commands.add(
          MoveUnitCommand(founder.id, option.target.col, option.target.row),
        );
      }
    }
    return commands;
  }

  static bool _isReadyFounder(GameUnit unit) {
    return !unit.isWorking &&
        unit.movementPoints > 0 &&
        unit.queuedPath == null &&
        CityFoundingRules.canFoundCityWith(unit);
  }
}

List<GameCity> _knownCities(GameView view) {
  return [...view.ownCities, ...view.rememberedEnemyCities];
}

int _nearestOwnCityDistance(GameView view, int col, int row) {
  var result = 1 << 30;
  final origin = HexCoordinate(col: col, row: row);
  for (final city in view.ownCities) {
    final distance = HexDistance.between(origin, city.center.toCoordinate());
    if (distance < result) result = distance;
  }
  return result;
}

Set<ResourceType> _visibleResourceTypes(GameView view) {
  return ResourceVisibilityRules.visibleResourceTypes(
    playerId: view.forPlayerId,
    research: ResearchState(players: {view.forPlayerId: view.ownResearch}),
  );
}

double _foundingControlledHexScore(
  TileData tile,
  Set<ResourceType> visibleResourceTypes,
) {
  final yield = CityTileYieldRules.forTile(tile);
  return yield.food * 1.3 +
      yield.production * 1.35 +
      yield.gold * 0.7 +
      yield.defense * 0.35 +
      tile.resources.where(visibleResourceTypes.contains).length * 0.5;
}
