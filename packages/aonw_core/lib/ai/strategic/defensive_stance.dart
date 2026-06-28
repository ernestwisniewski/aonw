import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/util/collection_equality.dart';

export 'garrison_policy.dart';

class DefensiveStancePlan {
  final Map<String, StrategicDefenseAssignment> defenses;

  DefensiveStancePlan({
    required Map<String, StrategicDefenseAssignment> defenses,
  }) : defenses = Map.unmodifiable(defenses);

  static final empty = DefensiveStancePlan(defenses: const {});
}

class StrategicDefenseAssignment {
  final String cityId;
  final CityHex cityCenter;
  final int threatLevel;
  final String? primaryThreatPlayerId;
  final List<String> assignedUnitIds;

  StrategicDefenseAssignment({
    required this.cityId,
    required this.cityCenter,
    required this.threatLevel,
    required Iterable<String> assignedUnitIds,
    this.primaryThreatPlayerId,
  }) : assignedUnitIds = List.unmodifiable(assignedUnitIds);

  bool get hasAssignedGarrison => assignedUnitIds.isNotEmpty;

  @override
  bool operator ==(Object other) {
    return other is StrategicDefenseAssignment &&
        other.cityId == cityId &&
        other.cityCenter == cityCenter &&
        other.threatLevel == threatLevel &&
        other.primaryThreatPlayerId == primaryThreatPlayerId &&
        listEquals(other.assignedUnitIds, assignedUnitIds);
  }

  @override
  int get hashCode {
    return Object.hash(
      cityId,
      cityCenter,
      threatLevel,
      primaryThreatPlayerId,
      Object.hashAll(assignedUnitIds),
    );
  }
}
