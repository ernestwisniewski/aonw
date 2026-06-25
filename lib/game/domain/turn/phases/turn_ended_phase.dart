import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/event.dart';

class TurnEndedPhase extends TurnPhase {
  const TurnEndedPhase();

  @override
  TurnContext apply(TurnContext context) {
    return context.copyWith(
      events: [
        ...context.events,
        TurnEndedEvent(playerId: context.playerId),
      ],
    );
  }
}
