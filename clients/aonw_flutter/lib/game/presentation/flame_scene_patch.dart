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
    required List<FlameCombatTransition> combats,
  }) : unitUpserts = List.unmodifiable(unitUpserts),
       removedUnitIds = List.unmodifiable(removedUnitIds),
       movements = List.unmodifiable(movements),
       combats = List.unmodifiable(combats);

  factory FlameScenePatch.between(
    MapRenderSnapshot? previous,
    MapRenderSnapshot next,
  ) {
    if (previous == null || !_sameMap(previous, next)) {
      return _replacement(previous, next);
    }

    final previousUnits = _unitsById(previous);
    final nextUnits = _unitsById(next);

    return FlameScenePatch._(
      snapshot: next,
      unitUpserts: _unitUpserts(previous, next, previousUnits),
      removedUnitIds: _removedUnitIds(previous, nextUnits),
      movements: _movementBetween(previous, next, previousUnits, nextUnits),
      combats: _combatBetween(previous, next),
    );
  }

  final MapRenderSnapshot snapshot;
  final List<VisibleUnitView> unitUpserts;
  final List<String> removedUnitIds;
  final List<FlameUnitMovementTransition> movements;
  final List<FlameCombatTransition> combats;

  static FlameScenePatch _replacement(
    MapRenderSnapshot? previous,
    MapRenderSnapshot next,
  ) => FlameScenePatch._(
    snapshot: next,
    unitUpserts: next.player.units,
    removedUnitIds:
        previous?.player.units.map((unit) => unit.id).toList() ?? const [],
    movements: const [],
    combats: const [],
  );

  static Map<String, VisibleUnitView> _unitsById(MapRenderSnapshot snapshot) =>
      {for (final unit in snapshot.player.units) unit.id: unit};

  static List<VisibleUnitView> _unitUpserts(
    MapRenderSnapshot previous,
    MapRenderSnapshot next,
    Map<String, VisibleUnitView> previousUnits,
  ) {
    final actorChanged =
        previous.player.actorPlayerId != next.player.actorPlayerId;
    return [
      for (final unit in next.player.units)
        if (actorChanged || _unitChanged(previousUnits[unit.id], unit)) unit,
    ];
  }

  static bool _unitChanged(VisibleUnitView? before, VisibleUnitView next) =>
      before == null || !_sameUnit(before, next);

  static List<String> _removedUnitIds(
    MapRenderSnapshot previous,
    Map<String, VisibleUnitView> nextUnits,
  ) => [
    for (final unit in previous.player.units)
      if (!nextUnits.containsKey(unit.id)) unit.id,
  ];

  static List<FlameUnitMovementTransition> _movementBetween(
    MapRenderSnapshot previous,
    MapRenderSnapshot next,
    Map<String, VisibleUnitView> previousUnits,
    Map<String, VisibleUnitView> nextUnits,
  ) {
    final unitId = previous.interaction.movementPending
        ? previous.interaction.selectedUnitId
        : null;
    if (unitId == null || !_isAuthoritativeAdvance(previous, next)) {
      return const [];
    }
    final before = previousUnits[unitId];
    final after = nextUnits[unitId];
    if (before == null ||
        after == null ||
        before.coordinate == after.coordinate) {
      return const [];
    }
    return [
      FlameUnitMovementTransition(
        unitId: unitId,
        from: before.coordinate,
        to: after.coordinate,
        fromRevision: previous.player.stamp.revision,
        toRevision: next.player.stamp.revision,
      ),
    ];
  }

  static bool _isAuthoritativeAdvance(
    MapRenderSnapshot previous,
    MapRenderSnapshot next,
  ) =>
      next.player.stamp.revision > previous.player.stamp.revision &&
      next.player.stamp.stateDigest != previous.player.stamp.stateDigest &&
      next.player.stamp.mapHash == previous.player.stamp.mapHash &&
      next.player.stamp.rulesetHash == previous.player.stamp.rulesetHash;

  static List<FlameCombatTransition> _combatBetween(
    MapRenderSnapshot previous,
    MapRenderSnapshot next,
  ) {
    final execution = next.interaction.combat?.lastExecution;
    if (execution == null ||
        execution.revision ==
            previous.interaction.combat?.lastExecution?.revision ||
        execution.revision != next.player.stamp.revision ||
        !_isAuthoritativeAdvance(previous, next)) {
      return const [];
    }
    return [
      FlameCombatTransition(
        defender: execution.preview.defenderCoordinate,
        revision: execution.revision,
        eventCount: execution.events.length,
      ),
    ];
  }

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

final class FlameCombatTransition {
  const FlameCombatTransition({
    required this.defender,
    required this.revision,
    required this.eventCount,
  });

  final MapHexCoordinate defender;
  final int revision;
  final int eventCount;
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
