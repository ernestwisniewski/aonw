import 'package:aonw_rust_client/src/protocol_city_view.dart';
import 'package:aonw_rust_client/src/protocol_coordinate.dart';
import 'package:aonw_rust_client/src/protocol_json.dart';
import 'package:aonw_rust_client/src/protocol_pending_action.dart';
import 'package:aonw_rust_client/src/protocol_values.dart';

enum AonwPlayerTurnState {
  active,
  finished;

  factory AonwPlayerTurnState.fromJson(Object? source) {
    final name = readString(source, 'player turn state');
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () => throw FormatException('Unknown AoNW turn state $name.'),
    );
  }
}

final class AonwPlayerTurnLifecycle {
  const AonwPlayerTurnLifecycle({
    required this.ownState,
    required this.ownSubmitted,
    required this.requiredSubmissionCount,
    required this.submittedCount,
  });

  factory AonwPlayerTurnLifecycle.fromJson(Object? source) {
    final value = readObject(source, 'player turn lifecycle');
    requireKeys(value, const {
      'ownState',
      'ownSubmitted',
      'requiredSubmissionCount',
      'submittedCount',
    }, 'player turn lifecycle');
    return AonwPlayerTurnLifecycle(
      ownState: value['ownState'] == null
          ? null
          : AonwPlayerTurnState.fromJson(value['ownState']),
      ownSubmitted: readBool(value['ownSubmitted'], 'own submitted state'),
      requiredSubmissionCount: readUnsigned(
        value['requiredSubmissionCount'],
        'required submission count',
      ),
      submittedCount: readUnsigned(value['submittedCount'], 'submitted count'),
    );
  }

  final AonwPlayerTurnState? ownState;
  final bool ownSubmitted;
  final int requiredSubmissionCount;
  final int submittedCount;
}

enum AonwTransportCondition {
  operational,
  pillaged;

  factory AonwTransportCondition.fromJson(Object? source) {
    final name = readString(source, 'transport condition');
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () =>
          throw FormatException('Unknown AoNW transport condition $name.'),
    );
  }
}

final class AonwFieldImprovementView {
  const AonwFieldImprovementView({
    required this.coordinate,
    required this.improvement,
  });

  factory AonwFieldImprovementView.fromJson(Object? source) {
    final value = readObject(source, 'field improvement view');
    requireKeys(value, const {
      'coordinate',
      'improvement',
    }, 'field improvement view');
    return AonwFieldImprovementView(
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      improvement: AonwFieldImprovementKind.fromJson(value['improvement']),
    );
  }

  final AonwCoordinate coordinate;
  final AonwFieldImprovementKind improvement;
}

final class AonwRoadView {
  const AonwRoadView({required this.coordinate, required this.condition});

  factory AonwRoadView.fromJson(Object? source) {
    final value = readObject(source, 'road view');
    requireKeys(value, const {'coordinate', 'condition'}, 'road view');
    return AonwRoadView(
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      condition: AonwTransportCondition.fromJson(value['condition']),
    );
  }

  final AonwCoordinate coordinate;
  final AonwTransportCondition condition;
}

sealed class AonwWorkerJobView {
  const AonwWorkerJobView({
    required this.target,
    required this.remainingTurns,
    required this.totalTurns,
  });

  factory AonwWorkerJobView.fromJson(Object? source) {
    final value = readObject(source, 'worker job view');
    return switch (value['type']) {
      'fieldImprovement' => AonwFieldImprovementJobView.fromJson(value),
      'roadConstruction' => AonwRoadConstructionJobView.fromJson(value),
      final Object? type => throw FormatException('Unknown worker job $type.'),
    };
  }

  final AonwCoordinate target;
  final int remainingTurns;
  final int totalTurns;
}

final class AonwFieldImprovementJobView extends AonwWorkerJobView {
  const AonwFieldImprovementJobView({
    required super.target,
    required this.improvement,
    required super.remainingTurns,
    required super.totalTurns,
  });

  factory AonwFieldImprovementJobView.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'target',
      'improvement',
      'remainingTurns',
      'totalTurns',
    }, 'field improvement worker job');
    return AonwFieldImprovementJobView(
      target: AonwCoordinate.fromJson(value['target']),
      improvement: AonwFieldImprovementKind.fromJson(value['improvement']),
      remainingTurns: readUnsigned(value['remainingTurns'], 'remaining turns'),
      totalTurns: readUnsigned(value['totalTurns'], 'total turns'),
    );
  }

  final AonwFieldImprovementKind improvement;
}

final class AonwRoadConstructionJobView extends AonwWorkerJobView {
  const AonwRoadConstructionJobView({
    required super.target,
    required super.remainingTurns,
    required super.totalTurns,
  });

  factory AonwRoadConstructionJobView.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'target',
      'remainingTurns',
      'totalTurns',
    }, 'road construction worker job');
    return AonwRoadConstructionJobView(
      target: AonwCoordinate.fromJson(value['target']),
      remainingTurns: readUnsigned(value['remainingTurns'], 'remaining turns'),
      totalTurns: readUnsigned(value['totalTurns'], 'total turns'),
    );
  }
}

final class AonwPlayerUnitView {
  const AonwPlayerUnitView({
    required this.id,
    required this.ownerPlayerId,
    required this.kind,
    required this.name,
    required this.coordinate,
    required this.movementUnits,
    required this.posture,
    required this.workerBuildCharges,
    required this.workerJob,
    required this.workerAssignment,
  });

  factory AonwPlayerUnitView.fromJson(Object? source) {
    final value = readObject(source, 'player unit view');
    requireKeys(value, const {
      'id',
      'ownerPlayerId',
      'kind',
      'name',
      'coordinate',
      'movementUnits',
      'posture',
      'workerBuildCharges',
      'workerJob',
      'workerAssignment',
    }, 'player unit view');
    return AonwPlayerUnitView(
      id: readString(value['id'], 'unit id'),
      ownerPlayerId: readString(value['ownerPlayerId'], 'unit owner'),
      kind: AonwUnitKind.fromJson(value['kind']),
      name: readString(value['name'], 'unit name'),
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      movementUnits: readUnsigned(value['movementUnits'], 'unit movement'),
      posture: AonwUnitPosture.fromJson(value['posture']),
      workerBuildCharges: readUnsigned(
        value['workerBuildCharges'],
        'worker build charges',
      ),
      workerJob: value['workerJob'] == null
          ? null
          : AonwWorkerJobView.fromJson(value['workerJob']),
      workerAssignment: value['workerAssignment'] == null
          ? null
          : AonwCoordinate.fromJson(value['workerAssignment']),
    );
  }

  final String id;
  final String ownerPlayerId;
  final AonwUnitKind kind;
  final String name;
  final AonwCoordinate coordinate;
  final int movementUnits;
  final AonwUnitPosture posture;
  final int workerBuildCharges;
  final AonwWorkerJobView? workerJob;
  final AonwCoordinate? workerAssignment;
}

final class AonwPlayerViewSnapshot {
  const AonwPlayerViewSnapshot({
    required this.stamp,
    required this.turn,
    required this.turnLifecycle,
    required this.pendingAction,
    required this.cityFoundingDraft,
    required this.units,
    required this.cities,
    required this.fieldImprovements,
    required this.roads,
  });

  factory AonwPlayerViewSnapshot.fromJson(Object? source) {
    final value = readObject(source, 'player snapshot');
    requireKeys(value, const {
      'stamp',
      'turn',
      'turnLifecycle',
      'pendingAction',
      'cityFoundingDraft',
      'units',
      'cities',
      'fieldImprovements',
      'roads',
    }, 'player snapshot');
    return AonwPlayerViewSnapshot(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      turn: readUnsigned(value['turn'], 'snapshot turn'),
      turnLifecycle: AonwPlayerTurnLifecycle.fromJson(value['turnLifecycle']),
      pendingAction: value['pendingAction'] == null
          ? null
          : AonwPendingActionView.fromJson(value['pendingAction']),
      cityFoundingDraft: value['cityFoundingDraft'] == null
          ? null
          : AonwCityFoundingDraft.fromJson(value['cityFoundingDraft']),
      units: _views(
        value['units'],
        'snapshot units',
        AonwPlayerUnitView.fromJson,
      ),
      cities: _views(
        value['cities'],
        'snapshot cities',
        AonwPlayerCityView.fromJson,
      ),
      fieldImprovements: _views(
        value['fieldImprovements'],
        'snapshot field improvements',
        AonwFieldImprovementView.fromJson,
      ),
      roads: _views(value['roads'], 'snapshot roads', AonwRoadView.fromJson),
    );
  }

  final AonwSessionStamp stamp;
  final int turn;
  final AonwPlayerTurnLifecycle turnLifecycle;
  final AonwPendingActionView? pendingAction;
  final AonwCityFoundingDraft? cityFoundingDraft;
  final List<AonwPlayerUnitView> units;
  final List<AonwPlayerCityView> cities;
  final List<AonwFieldImprovementView> fieldImprovements;
  final List<AonwRoadView> roads;
}

final class AonwPlayerViewPatch {
  const AonwPlayerViewPatch({
    required this.fromRevision,
    required this.toRevision,
    required this.turnLifecycle,
    required this.upsertedUnits,
    required this.removedUnitIds,
    required this.upsertedCities,
    required this.removedCityIds,
    required this.upsertedFieldImprovements,
    required this.removedFieldImprovementCoordinates,
    required this.upsertedRoads,
    required this.removedRoadCoordinates,
    required this.pendingAction,
    required this.cityFoundingDraft,
  });

  factory AonwPlayerViewPatch.fromJson(Object? source) {
    final value = readObject(source, 'player view patch');
    _requirePlayerViewPatchKeys(value);
    return AonwPlayerViewPatch(
      fromRevision: readUnsigned(value['fromRevision'], 'source revision'),
      toRevision: readUnsigned(value['toRevision'], 'patch target revision'),
      turnLifecycle: _optional(
        value['turnLifecycle'],
        AonwPlayerTurnLifecycle.fromJson,
      ),
      upsertedUnits: _views(
        value['upsertedUnits'],
        'upserted units',
        AonwPlayerUnitView.fromJson,
      ),
      removedUnitIds: _ids(value['removedUnitIds'], 'removed unit ids'),
      upsertedCities: _views(
        value['upsertedCities'],
        'upserted cities',
        AonwPlayerCityView.fromJson,
      ),
      removedCityIds: _ids(value['removedCityIds'], 'removed city ids'),
      upsertedFieldImprovements: _views(
        value['upsertedFieldImprovements'],
        'upserted field improvements',
        AonwFieldImprovementView.fromJson,
      ),
      removedFieldImprovementCoordinates: _coordinates(
        value['removedFieldImprovementCoordinates'],
        'removed field improvement coordinates',
      ),
      upsertedRoads: _views(
        value['upsertedRoads'],
        'upserted roads',
        AonwRoadView.fromJson,
      ),
      removedRoadCoordinates: _coordinates(
        value['removedRoadCoordinates'],
        'removed road coordinates',
      ),
      pendingAction: _optional(
        value['pendingAction'],
        AonwPendingActionView.fromJson,
      ),
      cityFoundingDraft: _optional(
        value['cityFoundingDraft'],
        AonwCityFoundingDraft.fromJson,
      ),
    );
  }

  final int fromRevision;
  final int toRevision;
  final AonwPlayerTurnLifecycle? turnLifecycle;
  final List<AonwPlayerUnitView> upsertedUnits;
  final List<String> removedUnitIds;
  final List<AonwPlayerCityView> upsertedCities;
  final List<String> removedCityIds;
  final List<AonwFieldImprovementView> upsertedFieldImprovements;
  final List<AonwCoordinate> removedFieldImprovementCoordinates;
  final List<AonwRoadView> upsertedRoads;
  final List<AonwCoordinate> removedRoadCoordinates;
  final AonwPendingActionView? pendingAction;
  final AonwCityFoundingDraft? cityFoundingDraft;
}

void _requirePlayerViewPatchKeys(Map<String, Object?> value) {
  requireKeys(value, const {
    'fromRevision',
    'toRevision',
    'turnLifecycle',
    'upsertedUnits',
    'removedUnitIds',
    'upsertedCities',
    'removedCityIds',
    'upsertedFieldImprovements',
    'removedFieldImprovementCoordinates',
    'upsertedRoads',
    'removedRoadCoordinates',
    'pendingAction',
    'cityFoundingDraft',
  }, 'player view patch');
}

List<AonwCoordinate> _coordinates(Object? value, String label) =>
    _views(value, label, AonwCoordinate.fromJson);

List<String> _ids(Object? value, String label) =>
    readList(value, label, (item, _) => readString(item, 'identifier'));

T? _optional<T>(Object? value, T Function(Object? value) parse) =>
    value == null ? null : parse(value);

List<T> _views<T>(
  Object? value,
  String label,
  T Function(Object? value) parse,
) => readList(value, label, (item, _) => parse(item));
