import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'war_goal.freezed.dart';

enum WarGoalKind { captureCity, eliminateUnits, harass, defend }

const int defensiveWarGoalEngagementRadius = 3;

bool warGoalEngagesHex(WarGoal goal, HexCoordinate hex) {
  if (goal.kind != WarGoalKind.defend) return true;
  return HexDistance.between(goal.targetHex, hex) <=
      defensiveWarGoalEngagementRadius;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class WarGoal with _$WarGoal {
  const WarGoal._();

  factory WarGoal({
    required String targetPlayerId,
    required WarGoalKind kind,
    CityHex? targetCity,
    required HexCoordinate targetHex,
    required int turnsBudget,
    required Iterable<String> assignedUnitIds,
    required double priority,
  }) {
    return WarGoal._internal(
      targetPlayerId: targetPlayerId,
      kind: kind,
      targetCity: targetCity,
      targetHex: targetHex,
      turnsBudget: turnsBudget,
      assignedUnitIds: List.unmodifiable(assignedUnitIds),
      priority: priority,
    );
  }

  const factory WarGoal._internal({
    required String targetPlayerId,
    required WarGoalKind kind,
    CityHex? targetCity,
    required HexCoordinate targetHex,
    required int turnsBudget,
    required List<String> assignedUnitIds,
    required double priority,
  }) = _WarGoal;
}
