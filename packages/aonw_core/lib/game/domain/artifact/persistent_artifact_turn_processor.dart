import 'package:aonw_core/game/domain/artifact/artifact_turn_processor.dart';
import 'package:aonw_core/game/domain/state.dart';

final class PersistentArtifactTurnResult {
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
    final result = ArtifactTurnProcessor.advanceForPlayers(
      units: state.units,
      artifacts: state.artifacts,
      playerIds: playerIds,
    );
    if (!result.changed) return PersistentArtifactTurnResult(state: state);
    return PersistentArtifactTurnResult(
      state: state.copyWith(units: result.units, artifacts: result.artifacts),
      changed: true,
    );
  }
}
