import 'package:aonw_core/game/domain/technology/science_yield.dart';

abstract final class TurnEconomyScience {
  static ScienceYieldBreakdown combine(
    ScienceYieldBreakdown total,
    ScienceYieldBreakdown addition,
  ) {
    if (addition.total <= 0) return total;
    if (total.total <= 0) return addition;

    final byCityId = <String, int>{...total.byCityId};
    for (final entry in addition.byCityId.entries) {
      byCityId[entry.key] = (byCityId[entry.key] ?? 0) + entry.value;
    }
    return ScienceYieldBreakdown(
      total: total.total + addition.total,
      byCityId: Map.unmodifiable(byCityId),
      sources: List.unmodifiable([...total.sources, ...addition.sources]),
    );
  }
}
