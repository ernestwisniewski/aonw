import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/fog.dart';

class FogRecomputePhase extends TurnPhase {
  final FogOfWarService fogOfWarService;

  const FogRecomputePhase({this.fogOfWarService = const FogOfWarService()});

  @override
  TurnContext apply(TurnContext context) {
    final state = context.state;
    final fogOfWar = fogOfWarService.recompute(
      current: state.fogOfWar,
      mapData: context.mapData,
      playerIds: knownPlayerIds(state),
      units: state.units,
      cities: state.cities,
    );

    return context.copyWith(
      state: withDiscoveredDiplomaticContacts(
        state.copyWith(fogOfWar: fogOfWar),
      ),
    );
  }
}
