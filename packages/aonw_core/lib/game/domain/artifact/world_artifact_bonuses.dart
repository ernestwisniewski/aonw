import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';

abstract final class WorldArtifactBonuses {
  static Iterable<WorldArtifact> storedInCity({
    required String cityId,
    required Iterable<WorldArtifact> artifacts,
  }) sync* {
    for (final artifact in artifacts) {
      final location = artifact.location;
      if (location.isStored && location.cityId == cityId) {
        yield artifact;
      }
    }
  }

  static TileYield cityYieldFor({
    required String cityId,
    required Iterable<WorldArtifact> artifacts,
  }) {
    var total = TileYield.zero;
    for (final artifact in storedInCity(cityId: cityId, artifacts: artifacts)) {
      total = total + artifact.type.cityYield;
    }
    return total;
  }

  static int cityScienceFor({
    required String cityId,
    required Iterable<WorldArtifact> artifacts,
  }) {
    var total = 0;
    for (final artifact in storedInCity(cityId: cityId, artifacts: artifacts)) {
      total += artifact.type.sciencePerTurn;
    }
    return total;
  }

  static int producedUnitExperienceFor({
    required String cityId,
    required Iterable<WorldArtifact> artifacts,
  }) {
    var total = 0;
    for (final artifact in storedInCity(cityId: cityId, artifacts: artifacts)) {
      total += artifact.type.producedUnitExperience;
    }
    return total;
  }

  static CombatStats cityCombatStatsFor({
    required String cityId,
    required Iterable<WorldArtifact> artifacts,
  }) {
    final defense = cityYieldFor(cityId: cityId, artifacts: artifacts).defense;
    if (defense <= 0) return const CombatStats();
    return CombatStats(defense: defense, hp: defense);
  }
}
