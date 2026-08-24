import '../../features/map/presentation/map_render_snapshot.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/player_map_view.dart';

/// The presentation-only delta between two validated map snapshots.
///
/// Movement transitions intentionally contain only authoritative start and end
/// coordinates. A route preview is not ordered execution evidence and is never
/// promoted to an animation path here.
final class FlameScenePatch {
  FlameScenePatch._({
    required this.snapshot,
    required List<VisibleUnitView> unitUpserts,
    required List<String> removedUnitIds,
    required List<FlameUnitMovementTransition> movements,
  }) : unitUpserts = List.unmodifiable(unitUpserts),
       removedUnitIds = List.unmodifiable(removedUnitIds),
       movements = List.unmodifiable(movements);

  factory FlameScenePatch.between(
    MapRenderSnapshot? previous,
    MapRenderSnapshot next,
  ) {
    if (previous == null || !_sameMap(previous, next)) {
      return FlameScenePatch._(
        snapshot: next,
        unitUpserts: next.player.units,
        removedUnitIds:
            previous?.player.units.map((unit) => unit.id).toList() ?? const [],
        movements: const [],
      );
    }

    final previousUnits = {
      for (final unit in previous.player.units) unit.id: unit,
    };
    final nextUnits = {for (final unit in next.player.units) unit.id: unit};
    final actorChanged =
        previous.player.actorPlayerId != next.player.actorPlayerId;
    final unitUpserts = <VisibleUnitView>[];
    for (final unit in next.player.units) {
      final before = previousUnits[unit.id];
      if (actorChanged || before == null || !_sameUnit(before, unit)) {
        unitUpserts.add(unit);
      }
    }

    final removedUnitIds = <String>[
      for (final unit in previous.player.units)
        if (!nextUnits.containsKey(unit.id)) unit.id,
    ];

    final movements = <FlameUnitMovementTransition>[];
    final pendingUnitId = previous.interaction.movementPending
        ? previous.interaction.selectedUnitId
        : null;
    final authoritativeAdvance =
        next.player.stamp.revision > previous.player.stamp.revision &&
        next.player.stamp.stateDigest != previous.player.stamp.stateDigest &&
        next.player.stamp.mapHash == previous.player.stamp.mapHash &&
        next.player.stamp.rulesetHash == previous.player.stamp.rulesetHash;
    if (pendingUnitId != null && authoritativeAdvance) {
      final before = previousUnits[pendingUnitId];
      final after = nextUnits[pendingUnitId];
      if (before != null &&
          after != null &&
          before.coordinate != after.coordinate) {
        movements.add(
          FlameUnitMovementTransition(
            unitId: pendingUnitId,
            from: before.coordinate,
            to: after.coordinate,
            fromRevision: previous.player.stamp.revision,
            toRevision: next.player.stamp.revision,
          ),
        );
      }
    }

    return FlameScenePatch._(
      snapshot: next,
      unitUpserts: unitUpserts,
      removedUnitIds: removedUnitIds,
      movements: movements,
    );
  }

  final MapRenderSnapshot snapshot;
  final List<VisibleUnitView> unitUpserts;
  final List<String> removedUnitIds;
  final List<FlameUnitMovementTransition> movements;

  static bool _sameMap(MapRenderSnapshot previous, MapRenderSnapshot next) =>
      previous.map.mapId == next.map.mapId &&
      previous.map.contentHash == next.map.contentHash &&
      previous.map.cols == next.map.cols &&
      previous.map.rows == next.map.rows;

  static bool _sameUnit(VisibleUnitView left, VisibleUnitView right) =>
      left.id == right.id &&
      left.ownerPlayerId == right.ownerPlayerId &&
      left.kind == right.kind &&
      left.name == right.name &&
      left.coordinate == right.coordinate &&
      left.movementUnits == right.movementUnits &&
      left.posture == right.posture;
}

final class FlameUnitMovementTransition {
  const FlameUnitMovementTransition({
    required this.unitId,
    required this.from,
    required this.to,
    required this.fromRevision,
    required this.toRevision,
  });

  final String unitId;
  final MapHexCoordinate from;
  final MapHexCoordinate to;
  final int fromRevision;
  final int toRevision;
}
