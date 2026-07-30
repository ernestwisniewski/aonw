part of 'game_event.dart';

sealed class ArtifactLifecycleEvent extends WorldEntityLifecycleEvent {
  const ArtifactLifecycleEvent({
    required this.artifactId,
    required this.ownerPlayerId,
    required this.unitId,
    required this.col,
    required this.row,
  });

  final String artifactId;
  final String ownerPlayerId;
  final String? unitId;
  final int col;
  final int row;
}

final class ArtifactExcavationStartedEvent extends ArtifactLifecycleEvent {
  const ArtifactExcavationStartedEvent({
    required super.artifactId,
    required super.ownerPlayerId,
    required super.unitId,
    required super.col,
    required super.row,
  });
}

final class ArtifactCarriedEvent extends ArtifactLifecycleEvent {
  const ArtifactCarriedEvent({
    required super.artifactId,
    required super.ownerPlayerId,
    required super.unitId,
    required super.col,
    required super.row,
  });
}

final class ArtifactStoredEvent extends ArtifactLifecycleEvent {
  const ArtifactStoredEvent({
    required super.artifactId,
    required super.ownerPlayerId,
    super.unitId,
    required this.cityId,
    required super.col,
    required super.row,
  });

  final String cityId;
}
