import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_context.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';

abstract final class TurnStrategicResourceProductionAdvancer {
  static TurnEconomyState advance({
    required TurnEconomyState state,
    required String playerId,
    required TurnEconomyContext context,
  }) {
    if (playerId.isEmpty) return state;
    final production = StrategicResourceProductionRules.forPlayer(
      playerId: playerId,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      mapTiles: context.mapData,
      research: state.research,
      ruleset: context.ruleset.resources,
    );
    if (production.output.isEmpty) return state;
    return state.copyWith(
      strategicResources: state.strategicResources.credit(
        playerId,
        production.output,
      ),
    );
  }
}
