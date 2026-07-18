import 'package:aonw_core/game/domain/turn/economy/turn_economy_context.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_player_catalog.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';

abstract final class TurnFogEconomyAdvancer {
  static TurnEconomyState advance({
    required TurnEconomyState state,
    required TurnEconomyContext context,
  }) {
    final playerIds = TurnEconomyPlayerCatalog.knownPlayerIds(
      state: state,
      basePlayerIds: context.baseKnownPlayerIds,
    );
    final fogOfWar = context.fogOfWarService.recompute(
      current: state.fogOfWar,
      mapData: context.mapData.mapTiles,
      playerIds: playerIds,
      units: state.units,
      cities: state.cities,
    );
    return state.copyWith(fogOfWar: fogOfWar);
  }
}
