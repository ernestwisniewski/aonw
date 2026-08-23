import 'package:aonw_rust_client/src/protocol_json.dart';
import 'package:aonw_rust_client/src/protocol_values.dart';

sealed class AonwClientEvent {
  const AonwClientEvent();

  factory AonwClientEvent.fromJson(Object? source) {
    final value = readObject(source, 'client event');
    return switch (value['type']) {
      'unitMoved' => AonwUnitMovedEvent.fromJson(value),
      final Object? type => throw FormatException(
        'Unknown AoNW client event $type.',
      ),
    };
  }
}

final class AonwUnitMovedEvent extends AonwClientEvent {
  const AonwUnitMovedEvent({
    required this.unitId,
    required this.from,
    required this.to,
  });

  factory AonwUnitMovedEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'from',
      'to',
    }, 'unit moved event');
    return AonwUnitMovedEvent(
      unitId: readString(value['unitId'], 'moved unit id'),
      from: AonwCoordinate.fromJson(value['from']),
      to: AonwCoordinate.fromJson(value['to']),
    );
  }

  final String unitId;
  final AonwCoordinate from;
  final AonwCoordinate to;
}

sealed class AonwClientEvidence {
  const AonwClientEvidence();

  factory AonwClientEvidence.fromJson(Object? source) {
    final value = readObject(source, 'client evidence');
    return switch (value['type']) {
      'unitMovement' => AonwUnitMovementEvidence.fromJson(value),
      final Object? type => throw FormatException(
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
      steps: readList(
        value['steps'],
        'movement evidence steps',
        (item, _) => AonwMovementStep.fromJson(item),
      ),
    );
  }

  final String unitId;
  final AonwCoordinate from;
  final List<AonwMovementStep> steps;
}

enum AonwCommandRejectionCode {
  staleRevision('stale_revision'),
  unitNotFound('unit_not_found'),
  unitNotControlled('unit_not_controlled'),
  unitUnavailable('unit_unavailable'),
  unitUsesTradeRoutes('unit_uses_trade_routes'),
  unitOutOfBounds('unit_out_of_bounds'),
  moveTargetOutOfBounds('move_target_out_of_bounds'),
  moveTargetIsCurrentTile('move_target_is_current_tile'),
  moveTargetIsForeignCityCenter('move_target_is_foreign_city_center'),
  moveTargetOccupied('move_target_occupied'),
  unitMovementCapacityInsufficient('unit_movement_capacity_insufficient'),
  movePathNotFound('move_path_not_found'),
  unitBusy('unit_busy'),
  unitDefinitionMissing('unit_definition_missing'),
  stateRevisionOverflow('state_revision_overflow'),
  invalidQueuedMovementPath('invalid_queued_movement_path'),
  invalidUnit('invalid_unit'),
  movementUnitUpdateFailed('movement_unit_update_failed');

  const AonwCommandRejectionCode(this.wireCode);

  final String wireCode;

  static AonwCommandRejectionCode fromWire(String source) {
    for (final value in values) {
      if (value.wireCode == source) return value;
    }
    throw FormatException('Unknown AoNW command rejection code $source.');
  }
}

sealed class AonwCommandOutcome {
  const AonwCommandOutcome();

  factory AonwCommandOutcome.fromJson(Object? source) {
    final value = readObject(source, 'command outcome');
    return switch (value['status']) {
      'accepted' => _accepted(value),
      'rejected' => _rejected(value),
      final Object? status => throw FormatException(
        'Unknown AoNW command outcome $status.',
      ),
    };
  }

  static AonwCommandOutcome _accepted(Map<String, Object?> value) {
    requireKeys(value, const {'status'}, 'accepted command outcome');
    return const AonwCommandAccepted();
  }

  static AonwCommandOutcome _rejected(Map<String, Object?> value) {
    requireKeys(value, const {'status', 'code'}, 'rejected command outcome');
    return AonwCommandRejected(
      AonwCommandRejectionCode.fromWire(
        readString(value['code'], 'command rejection code'),
      ),
    );
  }
}

final class AonwCommandAccepted extends AonwCommandOutcome {
  const AonwCommandAccepted();
}

final class AonwCommandRejected extends AonwCommandOutcome {
  const AonwCommandRejected(this.code);

  final AonwCommandRejectionCode code;
}

final class AonwCommandResult {
  const AonwCommandResult({
    required this.stamp,
    required this.outcome,
    required this.events,
    required this.evidence,
    required this.viewPatch,
  });

  factory AonwCommandResult.fromJson(Object? source) {
    final value = readObject(source, 'command result');
    requireKeys(value, const {
      'stamp',
      'outcome',
      'events',
      'evidence',
      'viewPatch',
    }, 'command result');
    return AonwCommandResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      outcome: AonwCommandOutcome.fromJson(value['outcome']),
      events: readList(
        value['events'],
        'command events',
        (item, _) => AonwClientEvent.fromJson(item),
      ),
      evidence: value['evidence'] == null
          ? null
          : AonwClientEvidence.fromJson(value['evidence']),
      viewPatch: AonwPlayerViewPatch.fromJson(value['viewPatch']),
    );
  }

  final AonwSessionStamp stamp;
  final AonwCommandOutcome outcome;
  final List<AonwClientEvent> events;
  final AonwClientEvidence? evidence;
  final AonwPlayerViewPatch viewPatch;

  bool get accepted => outcome is AonwCommandAccepted;

  AonwCommandRejectionCode? get rejection => switch (outcome) {
    AonwCommandRejected(:final code) => code,
    AonwCommandAccepted() => null,
  };
}
