import 'package:aonw/game/domain/turn/turn_context.dart';

abstract class TurnPhase {
  const TurnPhase();

  TurnContext apply(TurnContext context);
}
