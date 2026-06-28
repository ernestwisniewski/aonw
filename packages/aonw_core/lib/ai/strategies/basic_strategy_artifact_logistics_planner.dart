import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class BasicStrategyArtifactLogisticsPlanner {
  const BasicStrategyArtifactLogisticsPlanner();

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
    if (view.artifacts.isEmpty || view.ownUnits.isEmpty) return const [];

    final commands = <GameCommand>[];
    final occupied = <String>{
      for (final unit in view.ownUnits) _key(unit.col, unit.row),
      for (final unit in view.visibleEnemyUnits) _key(unit.col, unit.row),
      for (final hex in reservedHexes) _key(hex.col, hex.row),
    };
    final pathfinder = UnitMovementPathfinder(
      mapData: context.mapData,
      units: view.movementBlockingUnits,
      canEnterTile: (tile) =>
          view.visibility.canSeeDynamicAt(tile.col, tile.row) &&
          !occupied.contains(_key(tile.col, tile.row)),
    );

    final carriers = [
      for (final unit in view.ownUnits)
        if (unit.isCarryingArtifact && !usedUnitIds.contains(unit.id)) unit,
    ]..sort((a, b) => a.id.compareTo(b.id));
    for (final unit in carriers) {
      final city = _emptyArtifactStorageCityAt(unit, view);
      if (city == null) continue;
      commands.add(StoreArtifactInCityCommand(unit.id, cityId: city.id));
      usedUnitIds.add(unit.id);
    }

    for (final unit in carriers) {
      if (usedUnitIds.contains(unit.id)) continue;
      final move = _artifactCarrierMoveFor(
        unit: unit,
        view: view,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      if (move == null) {
        usedUnitIds.add(unit.id);
        continue;
      }
      commands.add(move.command);
      usedUnitIds.add(unit.id);
      occupied
        ..remove(_key(unit.col, unit.row))
        ..addAll(move.reservedHexes.map((hex) => _key(hex.col, hex.row)));
      reservedHexes.addAll(move.reservedHexes);
    }

    final freeStorageCount = _emptyArtifactStorageCities(view).length;
    final activeCarrierCount = view.ownUnits
        .where(
          (unit) =>
              unit.isCarryingArtifact || unit.excavatingArtifactId != null,
        )
        .length;
    var collectionBudget = freeStorageCount - activeCarrierCount;
    if (collectionBudget <= 0 && activeCarrierCount == 0) {
      collectionBudget = 1;
    }
    if (collectionBudget <= 0) return List.unmodifiable(commands);

    final collectors = [
      for (final unit in view.ownUnits)
        if (_canCollectArtifact(unit, usedUnitIds)) unit,
    ]..sort(_compareArtifactCollectors);
    for (final unit in collectors) {
      if (collectionBudget <= 0) break;
      final artifact = _mapArtifactAt(unit.col, unit.row, view);
      if (artifact == null) continue;
      commands.add(StartArtifactExcavationCommand(unit.id));
      usedUnitIds.add(unit.id);
      collectionBudget -= 1;
    }

    if (collectionBudget <= 0) return List.unmodifiable(commands);

    for (final unit in collectors) {
      if (collectionBudget <= 0) break;
      if (usedUnitIds.contains(unit.id)) continue;
      final move = _artifactCollectionMoveFor(
        unit: unit,
        view: view,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      if (move == null) continue;
      commands.add(move.command);
      usedUnitIds.add(unit.id);
      collectionBudget -= 1;
      occupied
        ..remove(_key(unit.col, unit.row))
        ..addAll(move.reservedHexes.map((hex) => _key(hex.col, hex.row)));
      reservedHexes.addAll(move.reservedHexes);
    }

    return List.unmodifiable(commands);
  }

  _PlannedArtifactMove? _artifactCarrierMoveFor({
    required GameUnit unit,
    required GameView view,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    if (unit.movementPoints <= 0 || unit.isWorking) return null;
    final emptyCities = _emptyArtifactStorageCities(view);
    final targets =
        [
          ...emptyCities,
          for (final city in view.ownCities)
            if (!emptyCities.contains(city)) city,
        ]..sort((a, b) {
          final distance =
              HexDistance.between(
                HexCoordinate(col: unit.col, row: unit.row),
                a.center.toCoordinate(),
              ).compareTo(
                HexDistance.between(
                  HexCoordinate(col: unit.col, row: unit.row),
                  b.center.toCoordinate(),
                ),
              );
          if (distance != 0) return distance;
          return a.id.compareTo(b.id);
        });

    for (final city in targets) {
      if (unit.occupies(city.center.col, city.center.row)) return null;
      if (occupied.contains(_key(city.center.col, city.center.row))) continue;
      final tile = view.mapData.tileAt(city.center.col, city.center.row);
      if (tile == null ||
          !view.visibility.canSeeDynamicAt(tile.col, tile.row)) {
        continue;
      }
      final plan = pathfinder.plan(unit: unit, targetTile: tile);
      if (plan == null) continue;
      if (!UnitMovementFeasibility.canEventuallyTraverse(
        unit: unit,
        plan: plan,
        canEnterStepBeyondCapacity: (step) =>
            _canCarryArtifactIntoCity(unit: unit, city: city, step: step),
      )) {
        continue;
      }
      return _PlannedArtifactMove(
        command: MoveUnitCommand(unit.id, city.center.col, city.center.row),
        reservedHexes: _reservedHexesFor(plan),
      );
    }
    return null;
  }

  _PlannedArtifactMove? _artifactCollectionMoveFor({
    required GameUnit unit,
    required GameView view,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    final artifacts = [
      for (final artifact in view.artifacts)
        if (artifact.location.isOnMap) artifact,
    ];
    if (artifacts.isEmpty) return null;

    final candidates = <_ArtifactMoveCandidate>[];
    for (final artifact in artifacts) {
      final col = artifact.location.col;
      final row = artifact.location.row;
      if (col == null || row == null) continue;
      if (unit.occupies(col, row)) continue;
      if (occupied.contains(_key(col, row))) continue;
      final tile = view.mapData.tileAt(col, row);
      if (tile == null || !view.visibility.canSeeDynamicAt(col, row)) {
        continue;
      }
      final plan = pathfinder.plan(unit: unit, targetTile: tile);
      if (plan == null) continue;
      if (!UnitMovementFeasibility.canEventuallyTraverse(
        unit: unit,
        plan: plan,
      )) {
        continue;
      }
      candidates.add(
        _ArtifactMoveCandidate(
          artifact: artifact,
          plan: plan,
          distance: HexDistance.between(
            HexCoordinate(col: unit.col, row: unit.row),
            HexCoordinate(col: col, row: row),
          ),
        ),
      );
    }
    candidates.sort((a, b) {
      final distance = a.distance.compareTo(b.distance);
      if (distance != 0) return distance;
      final value = b.artifact.type.diplomacyValue.compareTo(
        a.artifact.type.diplomacyValue,
      );
      if (value != 0) return value;
      return a.artifact.id.compareTo(b.artifact.id);
    });
    if (candidates.isEmpty) return null;
    final candidate = candidates.first;
    final location = candidate.artifact.location;
    return _PlannedArtifactMove(
      command: MoveUnitCommand(unit.id, location.col!, location.row!),
      reservedHexes: _reservedHexesFor(candidate.plan),
    );
  }

  bool _canCollectArtifact(GameUnit unit, Set<String> usedUnitIds) {
    if (usedUnitIds.contains(unit.id)) return false;
    if (!unit.isReadyToAct || unit.isFortified || unit.isCarryingArtifact) {
      return false;
    }
    if (unit.isWorker || CityFoundingRules.canFoundCityWith(unit)) {
      return false;
    }
    return AiUnitRoles.isMilitaryUnit(unit);
  }

  int _compareArtifactCollectors(GameUnit a, GameUnit b) {
    final recon = (AiUnitRoles.isReconUnit(b) ? 1 : 0).compareTo(
      AiUnitRoles.isReconUnit(a) ? 1 : 0,
    );
    if (recon != 0) return recon;
    return a.id.compareTo(b.id);
  }

  WorldArtifact? _mapArtifactAt(int col, int row, GameView view) {
    for (final artifact in view.artifacts) {
      if (artifact.location.isOnMap &&
          artifact.location.occupiesMapTile(col, row)) {
        return artifact;
      }
    }
    return null;
  }

  GameCity? _emptyArtifactStorageCityAt(GameUnit unit, GameView view) {
    for (final city in _emptyArtifactStorageCities(view)) {
      if (city.occupiesCenter(unit.col, unit.row)) return city;
    }
    return null;
  }

  List<GameCity> _emptyArtifactStorageCities(GameView view) {
    final occupiedCityIds = {
      for (final artifact in view.artifacts)
        if (artifact.location.isStored && artifact.location.cityId != null)
          artifact.location.cityId!,
    };
    return [
      for (final city in view.ownCities)
        if (!occupiedCityIds.contains(city.id)) city,
    ]..sort((a, b) => a.id.compareTo(b.id));
  }

  Set<HexCoordinate> _reservedHexesFor(UnitMovementPlan plan) {
    return {
      for (final step in plan.reachableSteps.skip(1))
        HexCoordinate(col: step.col, row: step.row),
    };
  }

  String _key(int col, int row) => '$col:$row';

  bool _canCarryArtifactIntoCity({
    required GameUnit unit,
    required GameCity city,
    required UnitMovementStep step,
  }) {
    return unit.carriedArtifactId != null &&
        city.ownerPlayerId == unit.ownerPlayerId &&
        city.occupiesCenter(step.col, step.row);
  }
}

final class _PlannedArtifactMove {
  const _PlannedArtifactMove({
    required this.command,
    required this.reservedHexes,
  });

  final MoveUnitCommand command;
  final Set<HexCoordinate> reservedHexes;
}

final class _ArtifactMoveCandidate {
  const _ArtifactMoveCandidate({
    required this.artifact,
    required this.plan,
    required this.distance,
  });

  final WorldArtifact artifact;
  final UnitMovementPlan plan;
  final int distance;
}
