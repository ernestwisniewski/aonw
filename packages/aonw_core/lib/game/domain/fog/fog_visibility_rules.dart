import 'package:aonw_core/game/domain/fog/fog_balance.dart';
import 'package:aonw_core/game/domain/terrain.dart';

class FogSightCost {
  final bool blocksPropagation;
  final int value;

  const FogSightCost.passable(this.value) : blocksPropagation = false;

  const FogSightCost.blocking(this.value) : blocksPropagation = true;
}

abstract final class FogVisibilityRules {
  static FogSightCost sightCost(TileTerrainProfile profile) {
    var cost = FogBalance.baseSightCost;
    if (profile.hasForest) cost += FogBalance.forestSightCost;
    if (profile.hasJungle) cost += FogBalance.jungleSightCost;
    if (profile.hasHills) cost += FogBalance.hillsSightCost;

    if (profile.hasMountain) {
      return FogSightCost.blocking(cost);
    }

    return FogSightCost.passable(cost);
  }
}
