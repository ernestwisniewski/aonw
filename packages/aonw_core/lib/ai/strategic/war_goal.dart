import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/util/collection_equality.dart';

enum WarGoalKind { captureCity, eliminateUnits, harass, defend }

const int defensiveWarGoalEngagementRadius = 3;

bool warGoalEngagesHex(WarGoal goal, HexCoordinate hex) {
  if (goal.kind != WarGoalKind.defend) return true;
  return HexDistance.between(goal.targetHex, hex) <=
      defensiveWarGoalEngagementRadius;
}

class WarGoal {
  final String targetPlayerId;
  final WarGoalKind kind;
  final CityHex? targetCity;
  final HexCoordinate targetHex;
  final int turnsBudget;
  final List<String> assignedUnitIds;
  final double priority;

  WarGoal({
    required this.targetPlayerId,
    required this.kind,
    required this.targetHex,
    required this.turnsBudget,
    required Iterable<String> assignedUnitIds,
    required this.priority,
    this.targetCity,
  }) : assignedUnitIds = List.unmodifiable(assignedUnitIds);

  WarGoal copyWith({
    String? targetPlayerId,
    WarGoalKind? kind,
    CityHex? targetCity,
    HexCoordinate? targetHex,
    int? turnsBudget,
    Iterable<String>? assignedUnitIds,
    double? priority,
  }) {
    return WarGoal(
      targetPlayerId: targetPlayerId ?? this.targetPlayerId,
      kind: kind ?? this.kind,
      targetCity: targetCity ?? this.targetCity,
      targetHex: targetHex ?? this.targetHex,
      turnsBudget: turnsBudget ?? this.turnsBudget,
      assignedUnitIds: assignedUnitIds ?? this.assignedUnitIds,
      priority: priority ?? this.priority,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WarGoal &&
        other.targetPlayerId == targetPlayerId &&
        other.kind == kind &&
        other.targetCity == targetCity &&
        other.targetHex == targetHex &&
        other.turnsBudget == turnsBudget &&
        listEquals(other.assignedUnitIds, assignedUnitIds) &&
        other.priority == priority;
  }

  @override
  int get hashCode {
    return Object.hash(
      targetPlayerId,
      kind,
      targetCity,
      targetHex,
      turnsBudget,
      Object.hashAll(assignedUnitIds),
      priority,
    );
  }
}
