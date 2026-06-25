import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';

class PersistentArtifactTurnResult {
  const PersistentArtifactTurnResult({
    required this.state,
    this.changed = false,
  });

  final PersistentGameState state;
  final bool changed;
}

abstract final class PersistentArtifactTurnProcessor {
  static PersistentArtifactTurnResult advanceForPlayers({
    required PersistentGameState state,
    required Iterable<String> playerIds,
  }) {
    final playerSet = {
      for (final playerId in playerIds)
        if (playerId.isNotEmpty) playerId,
    };
    if (playerSet.isEmpty || state.artifacts.isEmpty) {
      return PersistentArtifactTurnResult(state: state);
    }

    var units = state.units;
    var artifacts = state.artifacts;
    var changed = false;

    for (final unit in state.units) {
      if (!playerSet.contains(unit.ownerPlayerId)) continue;
      final artifactId = unit.excavatingArtifactId;
      if (artifactId == null) continue;
      final artifact = _artifactById(artifacts, artifactId);
      if (artifact == null ||
          !artifact.location.isBeingExcavated ||
          artifact.location.unitId != unit.id ||
          !unit.occupies(
            artifact.location.col ?? -1,
            artifact.location.row ?? -1,
          )) {
        units = _replaceUnit(units, unit.copyWithExcavatingArtifact(null));
        if (artifact?.location.isBeingExcavated == true) {
          artifacts = _replaceArtifact(
            artifacts,
            artifact!.copyWith(
              location: WorldArtifactLocation.map(
                col: artifact.location.col ?? unit.col,
                row: artifact.location.row ?? unit.row,
              ),
            ),
          );
        }
        changed = true;
        continue;
      }

      final remaining = artifact.location.remainingTurns - 1;
      if (remaining > 0) {
        artifacts = _replaceArtifact(
          artifacts,
          artifact.copyWith(
            location: WorldArtifactLocation.excavation(
              unitId: unit.id,
              col: unit.col,
              row: unit.row,
              remainingTurns: remaining,
            ),
          ),
        );
        changed = true;
        continue;
      }

      units = _replaceUnit(
        units,
        unit
            .copyWithExcavatingArtifact(null)
            .copyWithCarriedArtifact(artifact.id),
      );
      artifacts = _replaceArtifact(
        artifacts,
        artifact.copyWith(
          location: WorldArtifactLocation.carried(unitId: unit.id),
        ),
      );
      changed = true;
    }

    if (!changed) return PersistentArtifactTurnResult(state: state);
    return PersistentArtifactTurnResult(
      state: state.copyWith(units: units, artifacts: artifacts),
      changed: true,
    );
  }

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
