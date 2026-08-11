import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/transport/road_construction_rules.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/worker_job.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainTransportCommandResult {
  const DomainTransportCommandResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final String? reason;
}
/// Canonical-state adapter for transport infrastructure commands.
final class DomainTransportCommandResolver {
  const DomainTransportCommandResolver();

  DomainTransportCommandResult buildRoad({
    required DomainState state,
    required BuildRoadCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final unitIndex = _unitIndex(state.units, command.unitId);
    if (unitIndex == null) {
      return _rejected(state, 'worker_not_found');
    }
    final worker = state.units[unitIndex];
    if (worker.ownerPlayerId != actorPlayerId) {
      return _rejected(state, 'worker_not_controlled');
    }
    final legality = RoadConstructionRules.evaluate(
      unit: worker,
      cities: state.cities,
      network: state.transportNetwork,
      mapTiles: mapTiles,
    );
    if (!legality.allowed) {
      return _rejected(
        state,
        'road_construction_${legality.blocker!.name}',
      );
    }
    final totalTurns = RoadConstructionRules.buildTurns(paceBalance);
    final updated = worker
        .copyWith(movementPoints: 0)
        .copyWithQueuedPath(null)
        .copyWithWorkerAssignment(null)
        .copyWithPosture(UnitPosture.active)
        .copyWithWorkerJob(
          WorkerJob.roadConstruction(
            targetHex: CityHex(col: worker.col, row: worker.row),
            remainingTurns: totalTurns,
            totalTurns: totalTurns,
          ),
        );
    return DomainTransportCommandResult(
      accepted: true,
      state: state.copyWith(
        units: [
          for (var index = 0; index < state.units.length; index++)
            if (index == unitIndex) updated else state.units[index],
        ],
      ),
    );
  }

  static int? _unitIndex(List<GameUnit> units, String unitId) {
    for (var index = 0; index < units.length; index++) {
      if (units[index].id == unitId) return index;
    }
    return null;
  }

  static DomainTransportCommandResult _rejected(
    DomainState state,
    String reason,
  ) => DomainTransportCommandResult(
    accepted: false,
    state: state,
    reason: reason,
  );
}
