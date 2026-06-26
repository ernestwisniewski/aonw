import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';

typedef DispatchGameCommand =
    Future<List<UiEffect>> Function(GameCommand command);
