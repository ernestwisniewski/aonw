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

final class AonwCommandResult {
  const AonwCommandResult({
    required this.stamp,
    required this.accepted,
    required this.rejection,
    required this.events,
    required this.evidence,
    required this.viewPatch,
  });

  factory AonwCommandResult.fromJson(Object? source) {
    final value = readObject(source, 'command result');
    requireKeys(value, const {
      'stamp',
      'accepted',
      'rejection',
      'events',
      'evidence',
      'viewPatch',
    }, 'command result');
    final accepted = readBool(value['accepted'], 'command acceptance');
    final rejection = readNullableString(
      value['rejection'],
      'command rejection',
    );
    if (accepted == (rejection != null)) {
      throw const FormatException('Incoherent AoNW command result.');
    }
    return AonwCommandResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      accepted: accepted,
      rejection: rejection,
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
  final bool accepted;
  final String? rejection;
  final List<AonwClientEvent> events;
  final AonwClientEvidence? evidence;
  final AonwPlayerViewPatch viewPatch;
}
