import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_catalog.dart';

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
    return UnitCatalog.specFor(type).upkeep;
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
    final upkeepCostsByType = <GameUnitType, int>{};
    int cachedUpkeepCost(GameUnitType type) {
      return upkeepCostsByType[type] ??= upkeepCostForType(type);
    }

    final upkeepUnits = <_UpkeepUnit>[];
    for (final unit in units) {
      if (unit.ownerPlayerId != playerId) continue;
      final upkeepCost = cachedUpkeepCost(unit.type);
      if (upkeepCost <= 0) continue;
      upkeepUnits.add(_UpkeepUnit(unit: unit, baseCost: upkeepCost));
    }
    upkeepUnits.sort(_compareUpkeepUnits);

    final paidUnits = upkeepUnits.skip(freeUnits);
    final paidUnitsByType = <GameUnitType, int>{};
    final upkeepByType = <GameUnitType, int>{};
    var grossUpkeep = 0;
    var paidUnitCount = 0;
    var paidWorkerCount = 0;

    for (final upkeepUnit in paidUnits) {
      final unit = upkeepUnit.unit;
      final cost = switch (unit.type) {
        GameUnitType.worker => workerUpkeepCostForPaidIndex(++paidWorkerCount),
        _ => upkeepUnit.baseCost,
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

  static int _compareUpkeepUnits(_UpkeepUnit a, _UpkeepUnit b) {
    final costCompare = b.baseCost.compareTo(a.baseCost);
    if (costCompare != 0) return costCompare;
    final typeCompare = a.unit.type.index.compareTo(b.unit.type.index);
    if (typeCompare != 0) return typeCompare;
    return a.unit.id.compareTo(b.unit.id);
  }
}

class _UpkeepUnit {
  final GameUnit unit;
  final int baseCost;

  const _UpkeepUnit({required this.unit, required this.baseCost});
}
