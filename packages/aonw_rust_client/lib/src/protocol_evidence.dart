import 'package:aonw_rust_client/src/protocol_coordinate.dart';
import 'package:aonw_rust_client/src/protocol_json.dart';
import 'package:aonw_rust_client/src/protocol_pending_action.dart';
import 'package:aonw_rust_client/src/protocol_player_view.dart';
import 'package:aonw_rust_client/src/protocol_values.dart';

sealed class AonwClientEvidence {
  const AonwClientEvidence();

  factory AonwClientEvidence.fromJson(Object? source) {
    final value = readObject(source, 'client evidence');
    return switch (readString(value['type'], 'client evidence type')) {
      'combat' => AonwCombatEvidence.fromJson(value),
      'unitMovement' => AonwUnitMovementEvidence.fromJson(value),
      'logistics' => AonwLogisticsEvidence.fromJson(value),
      'workerAutomation' => AonwWorkerAutomationEvidence.fromJson(value),
      'turnKernel' => AonwTurnKernelEvidence.fromJson(value),
      final String type => throw FormatException(
        'Unknown AoNW client evidence $type.',
      ),
    };
  }
}

final class AonwUnitMovementEvidence extends AonwClientEvidence {
  const AonwUnitMovementEvidence({
    required this.unitId,
    required this.from,
    required this.steps,
  });

  factory AonwUnitMovementEvidence.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'from',
      'steps',
    }, 'unit movement evidence');
    return AonwUnitMovementEvidence(
      unitId: readString(value['unitId'], 'evidence unit id'),
      from: AonwCoordinate.fromJson(value['from']),
      steps: _movementSteps(value['steps'], 'movement evidence steps'),
    );
  }

  final String unitId;
  final AonwCoordinate from;
  final List<AonwMovementStep> steps;
}

final class AonwUnitMovementExecution {
  const AonwUnitMovementExecution({
    required this.unitId,
    required this.from,
    required this.steps,
  });

  factory AonwUnitMovementExecution.fromJson(Object? source) {
    final value = readObject(source, 'unit movement execution');
    requireKeys(value, const {
      'unitId',
      'from',
      'steps',
    }, 'unit movement execution');
    return AonwUnitMovementExecution(
      unitId: readString(value['unitId'], 'execution unit id'),
      from: AonwCoordinate.fromJson(value['from']),
      steps: _movementSteps(value['steps'], 'execution movement steps'),
    );
  }

  final String unitId;
  final AonwCoordinate from;
  final List<AonwMovementStep> steps;
}

final class AonwCombatEvidence extends AonwClientEvidence {
  const AonwCombatEvidence({required this.execution});

  factory AonwCombatEvidence.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'execution'}, 'combat evidence');
    return AonwCombatEvidence(
      execution: AonwCombatExecution.fromJson(value['execution']),
    );
  }

  final AonwCombatExecution execution;
}

final class AonwCombatExecution {
  const AonwCombatExecution({
    required this.seed,
    required this.rolls,
    required this.preview,
    required this.outcome,
  });

  factory AonwCombatExecution.fromJson(Object? source) {
    final value = readObject(source, 'combat execution');
    requireKeys(value, const {
      'seed',
      'rolls',
      'preview',
      'outcome',
    }, 'combat execution');
    return AonwCombatExecution(
      seed: readUnsigned(value['seed'], 'combat seed'),
      rolls: readList(
        value['rolls'],
        'combat rolls',
        (item, _) => AonwCombatRoll.fromJson(item),
      ),
      preview: AonwCombatPreview.fromJson(value['preview']),
      outcome: AonwCombatOutcome.fromJson(value['outcome']),
    );
  }

  final int seed;
  final List<AonwCombatRoll> rolls;
  final AonwCombatPreview preview;
  final AonwCombatOutcome outcome;
}

final class AonwCombatRoll {
  const AonwCombatRoll({required this.value});

  factory AonwCombatRoll.fromJson(Object? source) {
    final value = readObject(source, 'combat roll');
    requireKeys(value, const {'value'}, 'combat roll');
    return AonwCombatRoll(value: readInt(value['value'], 'combat roll value'));
  }

  final int value;
}

sealed class AonwCombatTarget {
  const AonwCombatTarget();

  factory AonwCombatTarget.fromJson(Object? source) {
    final value = readObject(source, 'combat target');
    return switch (readString(value['type'], 'combat target type')) {
      'unit' => AonwUnitCombatTarget.fromJson(value),
      'city' => AonwCityCombatTarget.fromJson(value),
      _ => throw const FormatException('Unknown AoNW combat target.'),
    };
  }
}

final class AonwUnitCombatTarget extends AonwCombatTarget {
  const AonwUnitCombatTarget({required this.unitId});

  factory AonwUnitCombatTarget.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'unitId'}, 'unit combat target');
    return AonwUnitCombatTarget(
      unitId: readString(value['unitId'], 'combat target unit id'),
    );
  }

  final String unitId;
}

final class AonwCityCombatTarget extends AonwCombatTarget {
  const AonwCityCombatTarget({required this.cityId});

  factory AonwCityCombatTarget.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'cityId'}, 'city combat target');
    return AonwCityCombatTarget(
      cityId: readString(value['cityId'], 'combat target city id'),
    );
  }

  final String cityId;
}

enum AonwCombatStatTarget {
  attack,
  defense,
  hitPoints;

  factory AonwCombatStatTarget.fromJson(Object? source) =>
      _enum(source, values, 'combat stat target');
}

enum AonwCombatModifierKind {
  terrain,
  fortification,
  technology,
  counter,
  troopComposition,
  veterancy;

  factory AonwCombatModifierKind.fromJson(Object? source) =>
      _enum(source, values, 'combat modifier kind');
}

final class AonwCombatModifier {
  const AonwCombatModifier({
    required this.kind,
    required this.label,
    required this.target,
    required this.delta,
  });

  factory AonwCombatModifier.fromJson(Object? source) {
    final value = readObject(source, 'combat modifier');
    requireKeys(value, const {
      'kind',
      'label',
      'target',
      'delta',
    }, 'combat modifier');
    return AonwCombatModifier(
      kind: AonwCombatModifierKind.fromJson(value['kind']),
      label: readString(value['label'], 'combat modifier label'),
      target: AonwCombatStatTarget.fromJson(value['target']),
      delta: readInt(value['delta'], 'combat modifier delta'),
    );
  }

  final AonwCombatModifierKind kind;
  final String label;
  final AonwCombatStatTarget target;
  final int delta;
}

final class AonwCombatStats {
  const AonwCombatStats({
    required this.attack,
    required this.defense,
    required this.hitPoints,
    required this.range,
    required this.mobility,
    required this.modifiers,
  });

  factory AonwCombatStats.fromJson(Object? source) {
    final value = readObject(source, 'combat stats');
    requireKeys(value, const {
      'attack',
      'defense',
      'hitPoints',
      'range',
      'mobility',
      'modifiers',
    }, 'combat stats');
    return AonwCombatStats(
      attack: readInt(value['attack'], 'combat attack'),
      defense: readInt(value['defense'], 'combat defense'),
      hitPoints: readUnsigned(value['hitPoints'], 'combat hit points'),
      range: readUnsigned(value['range'], 'combat range'),
      mobility: readUnsigned(value['mobility'], 'combat mobility'),
      modifiers: readList(
        value['modifiers'],
        'combat modifiers',
        (item, _) => AonwCombatModifier.fromJson(item),
      ),
    );
  }

  final int attack;
  final int defense;
  final int hitPoints;
  final int range;
  final int mobility;
  final List<AonwCombatModifier> modifiers;
}

final class AonwCombatPreview {
  const AonwCombatPreview({
    required this.attackerUnitId,
    required this.target,
    required this.distance,
    required this.attacker,
    required this.defender,
    required this.outgoingDamageMin,
    required this.outgoingDamageMax,
    required this.retaliationDamageMin,
    required this.retaliationDamageMax,
  });

  factory AonwCombatPreview.fromJson(Object? source) {
    final value = readObject(source, 'combat preview');
    requireKeys(value, const {
      'attackerUnitId',
      'target',
      'distance',
      'attacker',
      'defender',
      'outgoingDamageMin',
      'outgoingDamageMax',
      'retaliationDamageMin',
      'retaliationDamageMax',
    }, 'combat preview');
    return AonwCombatPreview(
      attackerUnitId: readString(value['attackerUnitId'], 'attacker unit id'),
      target: AonwCombatTarget.fromJson(value['target']),
      distance: readUnsigned(value['distance'], 'combat distance'),
      attacker: AonwCombatStats.fromJson(value['attacker']),
      defender: AonwCombatStats.fromJson(value['defender']),
      outgoingDamageMin: readUnsigned(
        value['outgoingDamageMin'],
        'minimum outgoing damage',
      ),
      outgoingDamageMax: readUnsigned(
        value['outgoingDamageMax'],
        'maximum outgoing damage',
      ),
      retaliationDamageMin: _nullableUnsigned(
        value['retaliationDamageMin'],
        'minimum retaliation damage',
      ),
      retaliationDamageMax: _nullableUnsigned(
        value['retaliationDamageMax'],
        'maximum retaliation damage',
      ),
    );
  }

  final String attackerUnitId;
  final AonwCombatTarget target;
  final int distance;
  final AonwCombatStats attacker;
  final AonwCombatStats defender;
  final int outgoingDamageMin;
  final int outgoingDamageMax;
  final int? retaliationDamageMin;
  final int? retaliationDamageMax;
}

final class AonwCombatOutcome {
  const AonwCombatOutcome({
    required this.attackerHitPoints,
    required this.defenderHitPoints,
    required this.attackerKilled,
    required this.defenderKilled,
    required this.defenderRetreat,
    required this.outgoingDamage,
    required this.retaliationDamage,
  });

  factory AonwCombatOutcome.fromJson(Object? source) {
    final value = readObject(source, 'combat outcome');
    requireKeys(value, const {
      'attackerHitPoints',
      'defenderHitPoints',
      'attackerKilled',
      'defenderKilled',
      'defenderRetreat',
      'outgoingDamage',
      'retaliationDamage',
    }, 'combat outcome');
    return AonwCombatOutcome(
      attackerHitPoints: readInt(
        value['attackerHitPoints'],
        'attacker hit points',
      ),
      defenderHitPoints: readInt(
        value['defenderHitPoints'],
        'defender hit points',
      ),
      attackerKilled: readBool(value['attackerKilled'], 'attacker killed'),
      defenderKilled: readBool(value['defenderKilled'], 'defender killed'),
      defenderRetreat: value['defenderRetreat'] == null
          ? null
          : AonwCoordinate.fromJson(value['defenderRetreat']),
      outgoingDamage: readUnsigned(value['outgoingDamage'], 'outgoing damage'),
      retaliationDamage: readUnsigned(
        value['retaliationDamage'],
        'retaliation damage',
      ),
    );
  }

  final int attackerHitPoints;
  final int defenderHitPoints;
  final bool attackerKilled;
  final bool defenderKilled;
  final AonwCoordinate? defenderRetreat;
  final int outgoingDamage;
  final int retaliationDamage;
}

sealed class AonwLogisticsExecution {
  const AonwLogisticsExecution();

  factory AonwLogisticsExecution.fromJson(Object? source) {
    final value = readObject(source, 'logistics execution');
    return switch (readString(value['type'], 'logistics execution type')) {
      'autoExplore' => AonwAutoExploreExecution.fromJson(value),
      'merchantRouteAssigned' => AonwMerchantRouteExecution.fromJson(value),
      'merchantTravelQueued' => AonwMerchantTravelExecution.fromJson(value),
      'troopDetached' => AonwTroopDetachmentExecution.fromJson(value),
      _ => throw const FormatException('Unknown AoNW logistics execution.'),
    };
  }
}

final class AonwLogisticsEvidence extends AonwClientEvidence {
  const AonwLogisticsEvidence({required this.execution});

  factory AonwLogisticsEvidence.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'execution'}, 'logistics evidence');
    return AonwLogisticsEvidence(
      execution: AonwLogisticsExecution.fromJson(value['execution']),
    );
  }

  final AonwLogisticsExecution execution;
}

final class AonwAutoExploreExecution extends AonwLogisticsExecution {
  const AonwAutoExploreExecution({
    required this.unitId,
    required this.target,
    required this.movement,
  });

  factory AonwAutoExploreExecution.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'target',
      'movement',
    }, 'auto explore execution');
    return AonwAutoExploreExecution(
      unitId: readString(value['unitId'], 'auto explore unit id'),
      target: AonwCoordinate.fromJson(value['target']),
      movement: value['movement'] == null
          ? null
          : AonwUnitMovementExecution.fromJson(value['movement']),
    );
  }

  final String unitId;
  final AonwCoordinate target;
  final AonwUnitMovementExecution? movement;
}

final class AonwMerchantRouteExecution extends AonwLogisticsExecution {
  const AonwMerchantRouteExecution({
    required this.unitId,
    required this.originCityId,
    required this.destinationCityId,
    required this.steps,
    required this.transportNetworkFingerprint,
  });

  factory AonwMerchantRouteExecution.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'originCityId',
      'destinationCityId',
      'steps',
      'transportNetworkFingerprint',
    }, 'merchant route execution');
    return AonwMerchantRouteExecution(
      unitId: readString(value['unitId'], 'merchant unit id'),
      originCityId: readString(value['originCityId'], 'route origin city id'),
      destinationCityId: readString(
        value['destinationCityId'],
        'route destination city id',
      ),
      steps: _movementSteps(value['steps'], 'merchant route steps'),
      transportNetworkFingerprint: readString(
        value['transportNetworkFingerprint'],
        'transport network fingerprint',
      ),
    );
  }

  final String unitId;
  final String originCityId;
  final String destinationCityId;
  final List<AonwMovementStep> steps;
  final String transportNetworkFingerprint;
}

final class AonwMerchantTravelExecution extends AonwLogisticsExecution {
  const AonwMerchantTravelExecution({
    required this.unitId,
    required this.destinationCityId,
    required this.steps,
  });

  factory AonwMerchantTravelExecution.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'destinationCityId',
      'steps',
    }, 'merchant travel execution');
    return AonwMerchantTravelExecution(
      unitId: readString(value['unitId'], 'merchant unit id'),
      destinationCityId: readString(
        value['destinationCityId'],
        'merchant destination city id',
      ),
      steps: _movementSteps(value['steps'], 'merchant travel steps'),
    );
  }

  final String unitId;
  final String destinationCityId;
  final List<AonwMovementStep> steps;
}

final class AonwTroopDetachmentExecution extends AonwLogisticsExecution {
  const AonwTroopDetachmentExecution({
    required this.sourceUnitId,
    required this.detachedUnitId,
    required this.troopKind,
    required this.destination,
  });

  factory AonwTroopDetachmentExecution.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'sourceUnitId',
      'detachedUnitId',
      'troopKind',
      'destination',
    }, 'troop detachment execution');
    return AonwTroopDetachmentExecution(
      sourceUnitId: readString(value['sourceUnitId'], 'source unit id'),
      detachedUnitId: readString(value['detachedUnitId'], 'detached unit id'),
      troopKind: AonwTroopKind.fromJson(value['troopKind']),
      destination: AonwCoordinate.fromJson(value['destination']),
    );
  }

  final String sourceUnitId;
  final String detachedUnitId;
  final AonwTroopKind troopKind;
  final AonwCoordinate destination;
}

sealed class AonwWorkerAutomationAction {
  const AonwWorkerAutomationAction();

  factory AonwWorkerAutomationAction.fromJson(Object? source) {
    final value = readObject(source, 'worker automation action');
    return switch (readString(value['type'], 'worker automation action type')) {
      'improve' => AonwWorkerImproveAction.fromJson(value),
      'assign' => AonwWorkerAssignAction.fromJson(value),
      _ => throw const FormatException(
        'Unknown AoNW worker automation action.',
      ),
    };
  }
}

final class AonwWorkerImproveAction extends AonwWorkerAutomationAction {
  const AonwWorkerImproveAction({required this.improvement});

  factory AonwWorkerImproveAction.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'improvement'}, 'worker improve action');
    return AonwWorkerImproveAction(
      improvement: AonwFieldImprovementKind.fromJson(value['improvement']),
    );
  }

  final AonwFieldImprovementKind improvement;
}

final class AonwWorkerAssignAction extends AonwWorkerAutomationAction {
  const AonwWorkerAssignAction();

  factory AonwWorkerAssignAction.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type'}, 'worker assign action');
    return const AonwWorkerAssignAction();
  }
}

final class AonwWorkerAutomationMetrics {
  const AonwWorkerAutomationMetrics({
    required this.tilesExamined,
    required this.legalityEvaluations,
    required this.routesPlanned,
  });

  factory AonwWorkerAutomationMetrics.fromJson(Object? source) {
    final value = readObject(source, 'worker automation metrics');
    requireKeys(value, const {
      'tilesExamined',
      'legalityEvaluations',
      'routesPlanned',
    }, 'worker automation metrics');
    return AonwWorkerAutomationMetrics(
      tilesExamined: readUnsigned(value['tilesExamined'], 'tiles examined'),
      legalityEvaluations: readUnsigned(
        value['legalityEvaluations'],
        'legality evaluations',
      ),
      routesPlanned: readUnsigned(value['routesPlanned'], 'routes planned'),
    );
  }

  final int tilesExamined;
  final int legalityEvaluations;
  final int routesPlanned;
}

final class AonwWorkerAutomationOption {
  const AonwWorkerAutomationOption({
    required this.target,
    required this.action,
    required this.movementCostUnits,
    required this.metrics,
  });

  factory AonwWorkerAutomationOption.fromJson(Object? source) {
    final value = readObject(source, 'worker automation option');
    requireKeys(value, const {
      'target',
      'action',
      'movementCostUnits',
      'metrics',
    }, 'worker automation option');
    return AonwWorkerAutomationOption(
      target: AonwCoordinate.fromJson(value['target']),
      action: AonwWorkerAutomationAction.fromJson(value['action']),
      movementCostUnits: readUnsigned(
        value['movementCostUnits'],
        'worker movement cost',
      ),
      metrics: AonwWorkerAutomationMetrics.fromJson(value['metrics']),
    );
  }

  final AonwCoordinate target;
  final AonwWorkerAutomationAction action;
  final int movementCostUnits;
  final AonwWorkerAutomationMetrics metrics;
}

final class AonwWorkerAutomationEvidence extends AonwClientEvidence {
  const AonwWorkerAutomationEvidence({
    required this.unitId,
    required this.option,
    required this.movement,
  });

  factory AonwWorkerAutomationEvidence.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'option',
      'movement',
    }, 'worker automation evidence');
    return AonwWorkerAutomationEvidence(
      unitId: readString(value['unitId'], 'worker unit id'),
      option: AonwWorkerAutomationOption.fromJson(value['option']),
      movement: value['movement'] == null
          ? null
          : AonwUnitMovementExecution.fromJson(value['movement']),
    );
  }

  final String unitId;
  final AonwWorkerAutomationOption option;
  final AonwUnitMovementExecution? movement;
}

final class AonwTurnKernelEvidence extends AonwClientEvidence {
  AonwTurnKernelEvidence({
    required List<String> processors,
    required List<String> foundedCityIds,
    required List<AonwCombatExecution> combatExecutions,
    required List<String> resetUnitIds,
    required List<AonwUnitMovementExecution> movementExecutions,
    required List<String> invalidatedOrderUnitIds,
    required List<String> finishedAutoExploreUnitIds,
  }) : processors = List.unmodifiable(processors),
       foundedCityIds = List.unmodifiable(foundedCityIds),
       combatExecutions = List.unmodifiable(combatExecutions),
       resetUnitIds = List.unmodifiable(resetUnitIds),
       movementExecutions = List.unmodifiable(movementExecutions),
       invalidatedOrderUnitIds = List.unmodifiable(invalidatedOrderUnitIds),
       finishedAutoExploreUnitIds = List.unmodifiable(
         finishedAutoExploreUnitIds,
       );

  factory AonwTurnKernelEvidence.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'processors',
      'foundedCityIds',
      'combatExecutions',
      'resetUnitIds',
      'movementExecutions',
      'invalidatedOrderUnitIds',
      'finishedAutoExploreUnitIds',
    }, 'turn kernel evidence');
    return AonwTurnKernelEvidence(
      processors: _strings(value['processors'], 'turn processors'),
      foundedCityIds: _strings(value['foundedCityIds'], 'founded city ids'),
      combatExecutions: readList(
        value['combatExecutions'],
        'turn combat executions',
        (item, _) => AonwCombatExecution.fromJson(item),
      ),
      resetUnitIds: _strings(value['resetUnitIds'], 'reset unit ids'),
      movementExecutions: readList(
        value['movementExecutions'],
        'turn movement executions',
        (item, _) => AonwUnitMovementExecution.fromJson(item),
      ),
      invalidatedOrderUnitIds: _strings(
        value['invalidatedOrderUnitIds'],
        'invalidated order unit ids',
      ),
      finishedAutoExploreUnitIds: _strings(
        value['finishedAutoExploreUnitIds'],
        'finished auto explore unit ids',
      ),
    );
  }

  final List<String> processors;
  final List<String> foundedCityIds;
  final List<AonwCombatExecution> combatExecutions;
  final List<String> resetUnitIds;
  final List<AonwUnitMovementExecution> movementExecutions;
  final List<String> invalidatedOrderUnitIds;
  final List<String> finishedAutoExploreUnitIds;
}

List<AonwMovementStep> _movementSteps(Object? source, String label) =>
    readList(source, label, (item, _) => AonwMovementStep.fromJson(item));

List<String> _strings(Object? source, String label) =>
    readList(source, label, (item, _) => readString(item, label));

int? _nullableUnsigned(Object? source, String label) =>
    source == null ? null : readUnsigned(source, label);

T _enum<T extends Enum>(Object? source, List<T> values, String label) {
  final wire = readString(source, label);
  for (final value in values) {
    if (value.name == wire) return value;
  }
  throw FormatException('Unknown AoNW $label $wire.');
}
