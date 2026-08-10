import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology/science_yield.dart';

abstract final class CityTurnScience {
  static ScienceYieldBreakdown artifactFor(
    GameCity city,
    Iterable<WorldArtifact> artifacts,
  ) {
    final amount = WorldArtifactBonuses.cityScienceFor(
      cityId: city.id,
      artifacts: artifacts,
    );
    if (amount <= 0) return ScienceYieldBreakdown.empty;
    return ScienceYieldBreakdown(
      total: amount,
      byCityId: {city.id: amount},
      sources: [
        ScienceYieldSource(
          cityId: city.id,
          amount: amount,
          label: ScienceYieldSourceLabels.worldArtifact,
        ),
      ],
    );
  }

  static ScienceYieldBreakdown combine(
    ScienceYieldBreakdown left,
    ScienceYieldBreakdown right,
  ) {
    if (left.total <= 0) return right;
    if (right.total <= 0) return left;
    final byCityId = <String, int>{...left.byCityId};
    for (final entry in right.byCityId.entries) {
      byCityId[entry.key] = (byCityId[entry.key] ?? 0) + entry.value;
    }
    return ScienceYieldBreakdown(
      total: left.total + right.total,
      byCityId: Map.unmodifiable(byCityId),
      sources: List.unmodifiable([...left.sources, ...right.sources]),
    );
  }
}
