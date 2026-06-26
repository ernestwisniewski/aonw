import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/event.dart';

class TurnResult {
  final GameState state;
  final GameSave? save;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;

  const TurnResult({
    required this.state,
    this.save,
    this.events = const [],
    this.uiEffects = const [],
  });
}
