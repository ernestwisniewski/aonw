import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';

class UnitUpkeepBreakdown {
  final String playerId;
  final int unitCount;
  final int freeUnitCount;
  final int paidUnitCount;
  final int grossUpkeep;
  final Map<GameUnitType, int> paidUnitsByType;
  final Map<GameUnitType, int> upkeepByType;

  const UnitUpkeepBreakdown({
    required this.playerId,
    required this.unitCount,
    required this.freeUnitCount,
    required this.paidUnitCount,
    required this.grossUpkeep,
    this.paidUnitsByType = const {},
    this.upkeepByType = const {},
  });

  int get total => grossUpkeep;

  bool get hasUpkeep => grossUpkeep > 0;

  int get freeUnitSlots {
    final slots = freeUnitCount - unitCount;
    return slots > 0 ? slots : 0;
  }

  int get paidWorkerCount => paidUnitsByType[GameUnitType.worker] ?? 0;

  int get nextWorkerUpkeep {
    if (freeUnitSlots > 0) return 0;
    return UnitUpkeepRules.workerUpkeepCostForPaidIndex(paidWorkerCount + 1);
  }
}

abstract final class UnitUpkeepRules {
  static const int baseFreeUnits = 2;
  static const int freeUnitsPerCity = 2;

  static int freeUnitCount({required int cityCount}) {
    return baseFreeUnits + cityCount * freeUnitsPerCity;
  }

  static int upkeepCostForType(GameUnitType type) {
    return switch (type) {
      GameUnitType.commander => 0,
      GameUnitType.warrior ||
      GameUnitType.archer ||
      GameUnitType.worker ||
      GameUnitType.merchant ||
      GameUnitType.scout ||
      GameUnitType.spearman ||
      GameUnitType.scoutShip => 1,
      GameUnitType.settler => 2,
      GameUnitType.cavalry ||
      GameUnitType.catapult ||
      GameUnitType.heavyInfantry ||
      GameUnitType.fieldCannon ||
      GameUnitType.rifleman ||
      GameUnitType.warship ||
      GameUnitType.reconPlane => 2,
      GameUnitType.tank => 3,
    };
  }

  static int workerUpkeepCostForPaidIndex(int paidWorkerIndex) {
    if (paidWorkerIndex <= 0) return 0;
    return paidWorkerIndex;
  }

  static UnitUpkeepBreakdown forPlayer({
    required String playerId,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
  }) {
    final cityCount = cities
        .where((city) => city.ownerPlayerId == playerId)
        .length;
    final freeUnits = freeUnitCount(cityCount: cityCount);
    final upkeepUnits =
        [
          for (final unit in units)
            if (unit.ownerPlayerId == playerId &&
                upkeepCostForType(unit.type) > 0)
              unit,
        ]..sort((a, b) {
          final costCompare = upkeepCostForType(
            b.type,
          ).compareTo(upkeepCostForType(a.type));
          if (costCompare != 0) return costCompare;
          final typeCompare = a.type.index.compareTo(b.type.index);
          if (typeCompare != 0) return typeCompare;
          return a.id.compareTo(b.id);
        });

    final paidUnits = upkeepUnits.skip(freeUnits);
    final paidUnitsByType = <GameUnitType, int>{};
    final upkeepByType = <GameUnitType, int>{};
    var grossUpkeep = 0;
    var paidUnitCount = 0;
    var paidWorkerCount = 0;

    for (final unit in paidUnits) {
      final cost = switch (unit.type) {
        GameUnitType.worker => workerUpkeepCostForPaidIndex(++paidWorkerCount),
        _ => upkeepCostForType(unit.type),
      };
      paidUnitCount++;
      grossUpkeep += cost;
      paidUnitsByType[unit.type] = (paidUnitsByType[unit.type] ?? 0) + 1;
      upkeepByType[unit.type] = (upkeepByType[unit.type] ?? 0) + cost;
    }

    return UnitUpkeepBreakdown(
      playerId: playerId,
      unitCount: upkeepUnits.length,
      freeUnitCount: freeUnits,
      paidUnitCount: paidUnitCount,
      grossUpkeep: grossUpkeep,
      paidUnitsByType: Map.unmodifiable(paidUnitsByType),
      upkeepByType: Map.unmodifiable(upkeepByType),
    );
  }
}
