import 'package:aonw_rust_client/src/protocol_coordinate.dart';
import 'package:aonw_rust_client/src/protocol_json.dart';
import 'package:aonw_rust_client/src/protocol_pending_action.dart';

enum AonwClientFeature {
  inspectMap,
  snapshot,
  reachable,
  routePlan,
  moveUnit,
  unitActions,
  saveGame,
  replayVerification;

  factory AonwClientFeature.fromJson(Object? value) {
    final wire = readString(value, 'client feature');
    return values.firstWhere(
      (feature) => feature.name == wire,
      orElse: () => throw FormatException('Unknown AoNW client feature $wire.'),
    );
  }
}

enum AonwUnitKind {
  commander,
  warrior,
  archer,
  settler,
  worker,
  merchant,
  scout,
  spearman,
  cavalry,
  catapult,
  heavyInfantry,
  fieldCannon,
  rifleman,
  tank,
  scoutShip,
  warship,
  reconPlane;

  factory AonwUnitKind.fromJson(Object? value) {
    final wire = readString(value, 'unit kind');
    return values.firstWhere(
      (kind) => kind.name == wire,
      orElse: () => throw FormatException('Unknown AoNW unit kind $wire.'),
    );
  }
}

enum AonwUnitPosture {
  active,
  fortified,
  autoExploring,
  autoWorking;

  factory AonwUnitPosture.fromJson(Object? value) {
    final wire = readString(value, 'unit posture');
    return values.firstWhere(
      (posture) => posture.name == wire,
      orElse: () => throw FormatException('Unknown AoNW unit posture $wire.'),
    );
  }
}

final class AonwSessionStamp {
  const AonwSessionStamp({
    required this.revision,
    required this.stateDigest,
    required this.mapHash,
    required this.rulesetHash,
  });

  factory AonwSessionStamp.fromJson(Object? source) {
    final value = readObject(source, 'session stamp');
    requireKeys(value, const {
      'revision',
      'stateDigest',
      'mapHash',
      'rulesetHash',
    }, 'session stamp');
    return AonwSessionStamp(
      revision: readUnsigned(value['revision'], 'state revision'),
      stateDigest: readString(value['stateDigest'], 'state digest'),
      mapHash: readString(value['mapHash'], 'map hash'),
      rulesetHash: readString(value['rulesetHash'], 'ruleset hash'),
    );
  }

  final int revision;
  final String stateDigest;
  final String mapHash;
  final String rulesetHash;
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
    }, 'player unit view');
    return AonwPlayerUnitView(
      id: readString(value['id'], 'unit id'),
      ownerPlayerId: readString(value['ownerPlayerId'], 'unit owner'),
      kind: AonwUnitKind.fromJson(value['kind']),
      name: readString(value['name'], 'unit name'),
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      movementUnits: readUnsigned(value['movementUnits'], 'unit movement'),
      posture: AonwUnitPosture.fromJson(value['posture']),
    );
  }

  final String id;
  final String ownerPlayerId;
  final AonwUnitKind kind;
  final String name;
  final AonwCoordinate coordinate;
  final int movementUnits;
  final AonwUnitPosture posture;
}

final class AonwPlayerViewSnapshot {
  const AonwPlayerViewSnapshot({
    required this.stamp,
    required this.turn,
    required this.pendingAction,
    required this.units,
  });

  factory AonwPlayerViewSnapshot.fromJson(Object? source) {
    final value = readObject(source, 'player snapshot');
    requireKeys(value, const {
      'stamp',
      'turn',
      'pendingAction',
      'units',
    }, 'player snapshot');
    return AonwPlayerViewSnapshot(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      turn: readUnsigned(value['turn'], 'snapshot turn'),
      pendingAction: value['pendingAction'] == null
          ? null
          : AonwPendingActionView.fromJson(value['pendingAction']),
      units: readList(
        value['units'],
        'snapshot units',
        (item, _) => AonwPlayerUnitView.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final int turn;
  final AonwPendingActionView? pendingAction;
  final List<AonwPlayerUnitView> units;
}

final class AonwPlayerViewPatch {
  const AonwPlayerViewPatch({
    required this.fromRevision,
    required this.toRevision,
    required this.upsertedUnits,
    required this.removedUnitIds,
    required this.pendingAction,
  });

  factory AonwPlayerViewPatch.fromJson(Object? source) {
    final value = readObject(source, 'player view patch');
    requireKeys(value, const {
      'fromRevision',
      'toRevision',
      'upsertedUnits',
      'removedUnitIds',
      'pendingAction',
    }, 'player view patch');
    return AonwPlayerViewPatch(
      fromRevision: readUnsigned(
        value['fromRevision'],
        'patch source revision',
      ),
      toRevision: readUnsigned(value['toRevision'], 'patch target revision'),
      upsertedUnits: readList(
        value['upsertedUnits'],
        'upserted units',
        (item, _) => AonwPlayerUnitView.fromJson(item),
      ),
      removedUnitIds: readList(
        value['removedUnitIds'],
        'removed unit ids',
        (item, _) => readString(item, 'removed unit id'),
      ),
      pendingAction: value['pendingAction'] == null
          ? null
          : AonwPendingActionView.fromJson(value['pendingAction']),
    );
  }

  final int fromRevision;
  final int toRevision;
  final List<AonwPlayerUnitView> upsertedUnits;
  final List<String> removedUnitIds;
  final AonwPendingActionView? pendingAction;
}

final class AonwMovementStep {
  const AonwMovementStep({
    required this.coordinate,
    required this.enterCostUnits,
    required this.cumulativeCostUnits,
  });

  factory AonwMovementStep.fromJson(Object? source) {
    final value = readObject(source, 'movement step');
    requireKeys(value, const {
      'coordinate',
      'enterCostUnits',
      'cumulativeCostUnits',
    }, 'movement step');
    return AonwMovementStep(
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
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

final class AonwReachableTile {
  const AonwReachableTile({
    required this.coordinate,
    required this.costUnits,
    required this.exhaustsMovement,
  });

  factory AonwReachableTile.fromJson(Object? source) {
    final value = readObject(source, 'reachable tile');
    requireKeys(value, const {
      'coordinate',
      'costUnits',
      'exhaustsMovement',
    }, 'reachable tile');
    return AonwReachableTile(
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      costUnits: readUnsigned(value['costUnits'], 'reachable cost'),
      exhaustsMovement: readBool(
        value['exhaustsMovement'],
        'reachable exhaustion',
      ),
    );
  }

  final AonwCoordinate coordinate;
  final int costUnits;
  final bool exhaustsMovement;
}
