import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/formatters/game_event_notification_focus_target.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';

class HudMapFocusTarget {
  final GameCommand selectCommand;
  final int col;
  final int row;

  const HudMapFocusTarget._({
    required this.selectCommand,
    required this.col,
    required this.row,
  });

  factory HudMapFocusTarget.unit(GameUnit unit) {
    return HudMapFocusTarget._(
      selectCommand: SelectUnitCommand(unit.id),
      col: unit.col,
      row: unit.row,
    );
  }

  factory HudMapFocusTarget.city(GameCity city) {
    return HudMapFocusTarget._(
      selectCommand: SelectCityCommand(city.id),
      col: city.center.col,
      row: city.center.row,
    );
  }

  static HudMapFocusTarget? notification({
    required GameEventNotification notification,
    required GameState? currentState,
  }) {
    final target = gameEventNotificationFocusTarget(
      notification.event,
      currentState ?? notification.state,
      viewerPlayerId: notification.playerId,
    );
    if (target == null) return null;
    return HudMapFocusTarget._(
      selectCommand: target.selectCommand,
      col: target.col,
      row: target.row,
    );
  }

  JumpCameraEffect get cameraEffect => JumpCameraEffect(col: col, row: row);
}
