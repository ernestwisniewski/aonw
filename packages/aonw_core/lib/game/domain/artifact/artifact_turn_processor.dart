import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

final class ArtifactTurnResult {
  const ArtifactTurnResult._({
    required this.units,
    required this.artifacts,
    this.changed = false,
  });

  final List<GameUnit> units;
  final List<WorldArtifact> artifacts;
  final bool changed;
}

/// Advances artifact excavation using persistence-free domain collections.
abstract final class ArtifactTurnProcessor {
  static ArtifactTurnResult advanceForPlayers({
    required List<GameUnit> units,
    required List<WorldArtifact> artifacts,
    required Iterable<String> playerIds,
  }) {
    final playerSet = _playerSet(playerIds);
    if (playerSet.isEmpty || artifacts.isEmpty) {
      return ArtifactTurnResult._(units: units, artifacts: artifacts);
    }

    var result = ArtifactTurnResult._(units: units, artifacts: artifacts);
    for (final unit in units) {
      if (!playerSet.contains(unit.ownerPlayerId) ||
          unit.excavatingArtifactId == null) {
        continue;
      }
      result = _advanceExcavation(result, unit);
    }
    if (!result.changed) return result;
    return ArtifactTurnResult._(
      units: List.unmodifiable(result.units),
      artifacts: List.unmodifiable(result.artifacts),
      changed: true,
    );
  }

  static ArtifactTurnResult _advanceExcavation(
    ArtifactTurnResult current,
    GameUnit unit,
  ) {
    final artifact = _artifactById(
      current.artifacts,
      unit.excavatingArtifactId!,
    );
    if (!_matchesExcavation(unit, artifact)) {
      return _cancelExcavation(current, unit, artifact);
    }
    if (artifact!.location.remainingTurns > 1) {
      return _continueExcavation(current, unit, artifact);
    }
    return _completeExcavation(current, unit, artifact);
  }

  static bool _matchesExcavation(GameUnit unit, WorldArtifact? artifact) {
    if (artifact == null || !artifact.location.isBeingExcavated) return false;
    return artifact.location.unitId == unit.id &&
        unit.occupies(artifact.location.col ?? -1, artifact.location.row ?? -1);
  }

  static ArtifactTurnResult _cancelExcavation(
    ArtifactTurnResult current,
    GameUnit unit,
    WorldArtifact? artifact,
  ) {
    final nextArtifacts = artifact?.location.isBeingExcavated == true
        ? _replaceArtifact(
            current.artifacts,
            artifact!.copyWith(
              location: WorldArtifactLocation.map(
                col: artifact.location.col ?? unit.col,
                row: artifact.location.row ?? unit.row,
              ),
            ),
          )
        : current.artifacts;
    return ArtifactTurnResult._(
      units: _replaceUnit(current.units, unit.copyWithExcavatingArtifact(null)),
      artifacts: nextArtifacts,
      changed: true,
    );
  }

  static ArtifactTurnResult _continueExcavation(
    ArtifactTurnResult current,
    GameUnit unit,
    WorldArtifact artifact,
  ) {
    return ArtifactTurnResult._(
      units: current.units,
      artifacts: _replaceArtifact(
        current.artifacts,
        artifact.copyWith(
          location: WorldArtifactLocation.excavation(
            unitId: unit.id,
            col: unit.col,
            row: unit.row,
            remainingTurns: artifact.location.remainingTurns - 1,
          ),
        ),
      ),
      changed: true,
    );
  }

  static ArtifactTurnResult _completeExcavation(
    ArtifactTurnResult current,
    GameUnit unit,
    WorldArtifact artifact,
  ) {
    return ArtifactTurnResult._(
      units: _replaceUnit(
        current.units,
        unit
            .copyWithExcavatingArtifact(null)
            .copyWithCarriedArtifact(artifact.id),
      ),
      artifacts: _replaceArtifact(
        current.artifacts,
        artifact.copyWith(
          location: WorldArtifactLocation.carried(unitId: unit.id),
        ),
      ),
      changed: true,
    );
  }

  static Set<String> _playerSet(Iterable<String> playerIds) => {
    for (final playerId in playerIds)
      if (playerId.isNotEmpty) playerId,
  };

  static WorldArtifact? _artifactById(
    Iterable<WorldArtifact> artifacts,
    String artifactId,
  ) {
    for (final artifact in artifacts) {
      if (artifact.id == artifactId) return artifact;
    }
    return null;
  }

  static List<GameUnit> _replaceUnit(List<GameUnit> units, GameUnit updated) {
    return [
      for (final unit in units)
        if (unit.id == updated.id) updated else unit,
    ];
  }

  static List<WorldArtifact> _replaceArtifact(
    List<WorldArtifact> artifacts,
    WorldArtifact updated,
  ) {
    return [
      for (final artifact in artifacts)
        if (artifact.id == updated.id) updated else artifact,
    ];
  }
}
