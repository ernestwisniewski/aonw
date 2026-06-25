import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';

class MerchantTradeRoute {
  final String originCityId;
  final String destinationCityId;
  final List<UnitMovementStep> steps;

  MerchantTradeRoute({
    required this.originCityId,
    required this.destinationCityId,
    required List<UnitMovementStep> steps,
  }) : steps = List.unmodifiable(steps);

  factory MerchantTradeRoute.fromJson(Map<String, dynamic> json) {
    return MerchantTradeRoute(
      originCityId: json['originCityId'] as String,
      destinationCityId: json['destinationCityId'] as String,
      steps: [
        for (final step in json['steps'] as List<dynamic>)
          _stepFromJson(step as Map<String, dynamic>),
      ],
    );
  }

  int get targetCol => steps.isEmpty ? 0 : steps.last.col;

  int get targetRow => steps.isEmpty ? 0 : steps.last.row;

  Map<String, dynamic> toJson() => {
    'originCityId': originCityId,
    'destinationCityId': destinationCityId,
    'steps': [
      for (final step in steps)
        {
          'col': step.col,
          'row': step.row,
          'enterCost': step.enterCost,
          'cumulativeCost': step.cumulativeCost,
        },
    ],
  };

  static UnitMovementStep _stepFromJson(Map<String, dynamic> json) {
    return UnitMovementStep(
      col: (json['col'] as num).toInt(),
      row: (json['row'] as num).toInt(),
      enterCost: (json['enterCost'] as num).toInt(),
      cumulativeCost: (json['cumulativeCost'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MerchantTradeRoute &&
        other.originCityId == originCityId &&
        other.destinationCityId == destinationCityId &&
        _sameSteps(other.steps, steps);
  }

  @override
  int get hashCode =>
      Object.hash(originCityId, destinationCityId, Object.hashAll(steps));

  @override
  String toString() {
    return 'MerchantTradeRoute(originCityId: $originCityId, '
        'destinationCityId: $destinationCityId, steps: $steps)';
  }

  static bool _sameSteps(
    List<UnitMovementStep> left,
    List<UnitMovementStep> right,
  ) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}
