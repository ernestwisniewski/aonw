import 'package:aonw_rust_client/src/protocol_coordinate.dart';
import 'package:aonw_rust_client/src/protocol_json.dart';
import 'package:aonw_rust_client/src/protocol_values.dart';

sealed class AonwQueryResult {
  const AonwQueryResult();

  factory AonwQueryResult.fromJson(Object? source) {
    final value = readObject(source, 'query result');
    return switch (value['type']) {
      'reachable' => AonwReachableResult.fromJson(value),
      'routePlan' => AonwRoutePlanResult.fromJson(value),
      final Object? type => throw FormatException(
        'Unknown AoNW query result $type.',
      ),
    };
  }
}

final class AonwReachableResult extends AonwQueryResult {
  const AonwReachableResult({
    required this.stamp,
    required this.unitId,
    required this.availableMovementUnits,
    required this.tiles,
  });

  factory AonwReachableResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'unitId',
      'availableMovementUnits',
      'tiles',
    }, 'reachable result');
    return AonwReachableResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      unitId: readString(value['unitId'], 'reachable unit id'),
      availableMovementUnits: readUnsigned(
        value['availableMovementUnits'],
        'available movement',
      ),
      tiles: readList(
        value['tiles'],
        'reachable tiles',
        (item, _) => AonwReachableTile.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String unitId;
  final int availableMovementUnits;
  final List<AonwReachableTile> tiles;
}

final class AonwRoutePlanResult extends AonwQueryResult {
  const AonwRoutePlanResult({
    required this.stamp,
    required this.unitId,
    required this.target,
    required this.destination,
    required this.totalCostUnits,
    required this.availableMovementUnits,
    required this.remainingMovementUnits,
    required this.steps,
  });

  factory AonwRoutePlanResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'unitId',
      'target',
      'destination',
      'totalCostUnits',
      'availableMovementUnits',
      'remainingMovementUnits',
      'steps',
    }, 'route plan result');
    return AonwRoutePlanResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      unitId: readString(value['unitId'], 'route unit id'),
      target: AonwCoordinate.fromJson(value['target']),
      destination: AonwCoordinate.fromJson(value['destination']),
      totalCostUnits: readUnsigned(value['totalCostUnits'], 'route total cost'),
      availableMovementUnits: readUnsigned(
        value['availableMovementUnits'],
        'available movement',
      ),
      remainingMovementUnits: readUnsigned(
        value['remainingMovementUnits'],
        'remaining movement',
      ),
      steps: readList(
        value['steps'],
        'route steps',
        (item, _) => AonwMovementStep.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String unitId;
  final AonwCoordinate target;
  final AonwCoordinate destination;
  final int totalCostUnits;
  final int availableMovementUnits;
  final int remainingMovementUnits;
  final List<AonwMovementStep> steps;
}
