import 'package:aonw_rust_client/src/protocol_artifact.dart';
import 'package:aonw_rust_client/src/protocol_city_view.dart';
import 'package:aonw_rust_client/src/protocol_coordinate.dart';
import 'package:aonw_rust_client/src/protocol_diplomacy.dart';
import 'package:aonw_rust_client/src/protocol_json.dart';
import 'package:aonw_rust_client/src/protocol_outcome.dart';
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

enum AonwTroopKind {
  warrior,
  archer,
  settler;

  factory AonwTroopKind.fromJson(Object? source) {
    final wire = readString(source, 'troop kind');
    return values.firstWhere(
      (kind) => kind.name == wire,
      orElse: () => throw FormatException('Unknown AoNW troop kind $wire.'),
    );
  }
}

final class AonwArmyTroop {
  const AonwArmyTroop({required this.kind, required this.count});

  factory AonwArmyTroop.fromJson(Object? source) {
    final value = readObject(source, 'army troop');
    requireKeys(value, const {'kind', 'count'}, 'army troop');
    return AonwArmyTroop(
      kind: AonwTroopKind.fromJson(value['kind']),
      count: readUnsigned(value['count'], 'troop count'),
    );
  }

  final AonwTroopKind kind;
  final int count;
}

final class AonwPersistedMovementStep {
  const AonwPersistedMovementStep({
    required this.coordinate,
    required this.enterCostUnits,
    required this.cumulativeCostUnits,
  });

  factory AonwPersistedMovementStep.fromJson(Object? source) {
    final value = readObject(source, 'persisted movement step');
    requireKeys(value, const {
      'col',
      'row',
      'enterCostUnits',
      'cumulativeCostUnits',
    }, 'persisted movement step');
    return AonwPersistedMovementStep(
      coordinate: AonwCoordinate(
        col: readInt(value['col'], 'movement step column'),
        row: readInt(value['row'], 'movement step row'),
      ),
      enterCostUnits: readUnsigned(value['enterCostUnits'], 'step entry cost'),
      cumulativeCostUnits: readUnsigned(
        value['cumulativeCostUnits'],
        'step cumulative cost',
      ),
    );
  }

  final AonwCoordinate coordinate;
  final int enterCostUnits;
  final int cumulativeCostUnits;
}

final class AonwQueuedMovePath {
  const AonwQueuedMovePath({required this.target, required this.steps});

  factory AonwQueuedMovePath.fromJson(Object? source) {
    final value = readObject(source, 'queued movement path');
    requireKeys(value, const {
      'targetCol',
      'targetRow',
      'steps',
    }, 'queued movement path');
    return AonwQueuedMovePath(
      target: AonwCoordinate(
        col: readInt(value['targetCol'], 'queued target column'),
        row: readInt(value['targetRow'], 'queued target row'),
      ),
      steps: readList(
        value['steps'],
        'queued movement steps',
        (item, _) => AonwPersistedMovementStep.fromJson(item),
      ),
    );
  }

  final AonwCoordinate target;
  final List<AonwPersistedMovementStep> steps;
}

final class AonwMerchantTradeRoute {
  const AonwMerchantTradeRoute({
    required this.originCityId,
    required this.destinationCityId,
    required this.steps,
    required this.transportNetworkFingerprint,
  });

  factory AonwMerchantTradeRoute.fromJson(Object? source) {
    final value = readObject(source, 'merchant trade route');
    requireKeys(value, const {
      'originCityId',
      'destinationCityId',
      'steps',
      'transportNetworkFingerprint',
    }, 'merchant trade route');
    return AonwMerchantTradeRoute(
      originCityId: readString(value['originCityId'], 'route origin city'),
      destinationCityId: readString(
        value['destinationCityId'],
        'route destination city',
      ),
      steps: readList(
        value['steps'],
        'merchant route steps',
        (item, _) => AonwPersistedMovementStep.fromJson(item),
      ),
      transportNetworkFingerprint: readString(
        value['transportNetworkFingerprint'],
        'transport network fingerprint',
      ),
    );
  }

  final String originCityId;
  final String destinationCityId;
  final List<AonwPersistedMovementStep> steps;
  final String transportNetworkFingerprint;
}

final class AonwCityFoundingJobView {
  const AonwCityFoundingJobView({
    required this.center,
    required this.controlledHexes,
    required this.remainingTurns,
    required this.totalTurns,
  });

  factory AonwCityFoundingJobView.fromJson(Object? source) {
    final value = readObject(source, 'city founding job');
    requireKeys(value, const {
      'center',
      'controlledHexes',
      'remainingTurns',
      'totalTurns',
    }, 'city founding job');
    return AonwCityFoundingJobView(
      center: AonwCoordinate.fromJson(value['center']),
      controlledHexes: readList(
        value['controlledHexes'],
        'city founding controlled hexes',
        (item, _) => AonwCoordinate.fromJson(item),
      ),
      remainingTurns: readUnsigned(value['remainingTurns'], 'remaining turns'),
      totalTurns: readUnsigned(value['totalTurns'], 'total turns'),
    );
  }

  final AonwCoordinate center;
  final List<AonwCoordinate> controlledHexes;
  final int remainingTurns;
  final int totalTurns;
}

final class AonwOwnedUnitDetails {
  const AonwOwnedUnitDetails({
    required this.army,
    required this.queuedPath,
    required this.merchantTradeRoute,
    required this.workerJob,
    required this.cityFoundingJob,
    required this.workerAssignment,
    required this.excavatingArtifactId,
    required this.workerBuildCharges,
    required this.experiencePoints,
  });

  factory AonwOwnedUnitDetails.fromJson(Object? source) {
    final value = readObject(source, 'owned unit details');
    requireKeys(value, const {
      'army',
      'queuedPath',
      'merchantTradeRoute',
      'workerJob',
      'cityFoundingJob',
      'workerAssignment',
      'excavatingArtifactId',
      'workerBuildCharges',
      'experiencePoints',
    }, 'owned unit details');
    return AonwOwnedUnitDetails(
      army: readList(
        value['army'],
        'unit army',
        (item, _) => AonwArmyTroop.fromJson(item),
      ),
      queuedPath: value['queuedPath'] == null
          ? null
          : AonwQueuedMovePath.fromJson(value['queuedPath']),
      merchantTradeRoute: value['merchantTradeRoute'] == null
          ? null
          : AonwMerchantTradeRoute.fromJson(value['merchantTradeRoute']),
      workerJob: value['workerJob'] == null
          ? null
          : AonwWorkerJobView.fromJson(value['workerJob']),
      cityFoundingJob: value['cityFoundingJob'] == null
          ? null
          : AonwCityFoundingJobView.fromJson(value['cityFoundingJob']),
      workerAssignment: value['workerAssignment'] == null
          ? null
          : AonwCoordinate.fromJson(value['workerAssignment']),
      excavatingArtifactId: readNullableString(
        value['excavatingArtifactId'],
        'excavating artifact id',
      ),
      workerBuildCharges: readUnsigned(
        value['workerBuildCharges'],
        'worker build charges',
      ),
      experiencePoints: readUnsigned(
        value['experiencePoints'],
        'unit experience points',
      ),
    );
  }

  final List<AonwArmyTroop> army;
  final AonwQueuedMovePath? queuedPath;
  final AonwMerchantTradeRoute? merchantTradeRoute;
  final AonwWorkerJobView? workerJob;
  final AonwCityFoundingJobView? cityFoundingJob;
  final AonwCoordinate? workerAssignment;
  final String? excavatingArtifactId;
  final int workerBuildCharges;
  final int experiencePoints;
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
    this.hitPoints,
    this.carriedArtifactId,
    this.ownedDetails,
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
      'hitPoints',
      'carriedArtifactId',
      'ownedDetails',
    }, 'player unit view');
    final ownedDetails = value['ownedDetails'] == null
        ? null
        : AonwOwnedUnitDetails.fromJson(value['ownedDetails']);
    return AonwPlayerUnitView(
      id: readString(value['id'], 'unit id'),
      ownerPlayerId: readString(value['ownerPlayerId'], 'unit owner'),
      kind: AonwUnitKind.fromJson(value['kind']),
      name: readString(value['name'], 'unit name'),
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      movementUnits: readUnsigned(value['movementUnits'], 'unit movement'),
      posture: AonwUnitPosture.fromJson(value['posture']),
      workerBuildCharges: ownedDetails?.workerBuildCharges ?? 0,
      workerJob: ownedDetails?.workerJob,
      workerAssignment: ownedDetails?.workerAssignment,
      hitPoints: value['hitPoints'] == null
          ? null
          : readUnsigned(value['hitPoints'], 'unit hit points'),
      carriedArtifactId: readNullableString(
        value['carriedArtifactId'],
        'carried artifact id',
      ),
      ownedDetails: ownedDetails,
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
  final int? hitPoints;
  final String? carriedArtifactId;
  final AonwOwnedUnitDetails? ownedDetails;
}

final class AonwPlayerViewSnapshot {
  const AonwPlayerViewSnapshot({
    required this.stamp,
    required this.turn,
    required this.outcome,
    required this.turnLifecycle,
    required this.pendingAction,
    required this.cityFoundingDraft,
    required this.diplomacy,
    required this.units,
    required this.cities,
    required this.artifacts,
    required this.fieldImprovements,
    required this.roads,
  });

  factory AonwPlayerViewSnapshot.fromJson(Object? source) {
    final value = readObject(source, 'player snapshot');
    requireKeys(value, const {
      'stamp',
      'turn',
      'outcome',
      'turnLifecycle',
      'pendingAction',
      'cityFoundingDraft',
      'diplomacy',
      'units',
      'cities',
      'artifacts',
      'fieldImprovements',
      'roads',
    }, 'player snapshot');
    return AonwPlayerViewSnapshot(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      turn: readUnsigned(value['turn'], 'snapshot turn'),
      outcome: AonwGameOutcome.fromJson(value['outcome']),
      turnLifecycle: AonwPlayerTurnLifecycle.fromJson(value['turnLifecycle']),
      pendingAction: value['pendingAction'] == null
          ? null
          : AonwPendingActionView.fromJson(value['pendingAction']),
      cityFoundingDraft: value['cityFoundingDraft'] == null
          ? null
          : AonwCityFoundingDraft.fromJson(value['cityFoundingDraft']),
      diplomacy: AonwPlayerDiplomacyView.fromJson(value['diplomacy']),
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
      artifacts: _views(
        value['artifacts'],
        'snapshot artifacts',
        AonwPlayerArtifactView.fromJson,
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
  final AonwGameOutcome outcome;
  final AonwPlayerTurnLifecycle turnLifecycle;
  final AonwPendingActionView? pendingAction;
  final AonwCityFoundingDraft? cityFoundingDraft;
  final AonwPlayerDiplomacyView diplomacy;
  final List<AonwPlayerUnitView> units;
  final List<AonwPlayerCityView> cities;
  final List<AonwPlayerArtifactView> artifacts;
  final List<AonwFieldImprovementView> fieldImprovements;
  final List<AonwRoadView> roads;
}

final class AonwPlayerViewPatch {
  const AonwPlayerViewPatch({
    required this.fromRevision,
    required this.toRevision,
    required this.turn,
    required this.turnLifecycle,
    required this.outcome,
    required this.upsertedUnits,
    required this.removedUnitIds,
    required this.upsertedCities,
    required this.removedCityIds,
    required this.upsertedArtifacts,
    required this.removedArtifactIds,
    required this.upsertedFieldImprovements,
    required this.removedFieldImprovementCoordinates,
    required this.upsertedRoads,
    required this.removedRoadCoordinates,
    required this.pendingAction,
    required this.cityFoundingDraft,
    required this.diplomacy,
  });

  factory AonwPlayerViewPatch.fromJson(Object? source) {
    final value = readObject(source, 'player view patch');
    _requirePlayerViewPatchKeys(value);
    final entities = _playerEntityPatch(value);
    final mapFeatures = _playerMapFeaturePatch(value);
    return AonwPlayerViewPatch(
      fromRevision: readUnsigned(value['fromRevision'], 'source revision'),
      toRevision: readUnsigned(value['toRevision'], 'patch target revision'),
      turn: readUnsigned(value['turn'], 'patch turn'),
      turnLifecycle: _optional(
        value['turnLifecycle'],
        AonwPlayerTurnLifecycle.fromJson,
      ),
      outcome: _optional(value['outcome'], AonwGameOutcome.fromJson),
      upsertedUnits: entities.units,
      removedUnitIds: entities.removedUnitIds,
      upsertedCities: entities.cities,
      removedCityIds: entities.removedCityIds,
      upsertedArtifacts: mapFeatures.artifacts,
      removedArtifactIds: mapFeatures.removedArtifactIds,
      upsertedFieldImprovements: mapFeatures.fieldImprovements,
      removedFieldImprovementCoordinates:
          mapFeatures.removedFieldImprovementCoordinates,
      upsertedRoads: mapFeatures.roads,
      removedRoadCoordinates: mapFeatures.removedRoadCoordinates,
      pendingAction: _optional(
        value['pendingAction'],
        AonwPendingActionView.fromJson,
      ),
      cityFoundingDraft: _optional(
        value['cityFoundingDraft'],
        AonwCityFoundingDraft.fromJson,
      ),
      diplomacy: _optional(
        value['diplomacy'],
        AonwPlayerDiplomacyView.fromJson,
      ),
    );
  }

  final int fromRevision;
  final int toRevision;
  final int turn;
  final AonwPlayerTurnLifecycle? turnLifecycle;
  final AonwGameOutcome? outcome;
  final List<AonwPlayerUnitView> upsertedUnits;
  final List<String> removedUnitIds;
  final List<AonwPlayerCityView> upsertedCities;
  final List<String> removedCityIds;
  final List<AonwPlayerArtifactView> upsertedArtifacts;
  final List<String> removedArtifactIds;
  final List<AonwFieldImprovementView> upsertedFieldImprovements;
  final List<AonwCoordinate> removedFieldImprovementCoordinates;
  final List<AonwRoadView> upsertedRoads;
  final List<AonwCoordinate> removedRoadCoordinates;
  final AonwPendingActionView? pendingAction;
  final AonwCityFoundingDraft? cityFoundingDraft;
  final AonwPlayerDiplomacyView? diplomacy;
}

({
  List<AonwPlayerUnitView> units,
  List<String> removedUnitIds,
  List<AonwPlayerCityView> cities,
  List<String> removedCityIds,
})
_playerEntityPatch(Map<String, Object?> value) => (
  units: _views(
    value['upsertedUnits'],
    'upserted units',
    AonwPlayerUnitView.fromJson,
  ),
  removedUnitIds: _ids(value['removedUnitIds'], 'removed unit ids'),
  cities: _views(
    value['upsertedCities'],
    'upserted cities',
    AonwPlayerCityView.fromJson,
  ),
  removedCityIds: _ids(value['removedCityIds'], 'removed city ids'),
);

({
  List<AonwPlayerArtifactView> artifacts,
  List<String> removedArtifactIds,
  List<AonwFieldImprovementView> fieldImprovements,
  List<AonwCoordinate> removedFieldImprovementCoordinates,
  List<AonwRoadView> roads,
  List<AonwCoordinate> removedRoadCoordinates,
})
_playerMapFeaturePatch(Map<String, Object?> value) => (
  artifacts: _views(
    value['upsertedArtifacts'],
    'upserted artifacts',
    AonwPlayerArtifactView.fromJson,
  ),
  removedArtifactIds: _ids(value['removedArtifactIds'], 'removed artifact ids'),
  fieldImprovements: _views(
    value['upsertedFieldImprovements'],
    'upserted field improvements',
    AonwFieldImprovementView.fromJson,
  ),
  removedFieldImprovementCoordinates: _coordinates(
    value['removedFieldImprovementCoordinates'],
    'removed field improvement coordinates',
  ),
  roads: _views(
    value['upsertedRoads'],
    'upserted roads',
    AonwRoadView.fromJson,
  ),
  removedRoadCoordinates: _coordinates(
    value['removedRoadCoordinates'],
    'removed road coordinates',
  ),
);

void _requirePlayerViewPatchKeys(Map<String, Object?> value) {
  requireKeys(value, const {
    'fromRevision',
    'toRevision',
    'turn',
    'turnLifecycle',
    'outcome',
    'upsertedUnits',
    'removedUnitIds',
    'upsertedCities',
    'removedCityIds',
    'upsertedArtifacts',
    'removedArtifactIds',
    'upsertedFieldImprovements',
    'removedFieldImprovementCoordinates',
    'upsertedRoads',
    'removedRoadCoordinates',
    'pendingAction',
    'cityFoundingDraft',
    'diplomacy',
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
