import 'package:aonw/game/presentation/providers/game_actions_provider.dart';
import 'package:aonw/game/presentation/providers/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/hud_feedback_provider.dart';
import 'package:aonw/game/presentation/providers/map_inspection_provider.dart';
import 'package:aonw/game/presentation/providers/player_control_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/command/hud_command_dispatcher.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_breakdown_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:aonw/game/presentation/widgets/hud/command/hud_command_dispatcher.dart';

final hudCommandDispatcherProvider = Provider<HudCommandDispatcher>(
  HudCommandDispatcher.new,
  dependencies: [
    gameCommandControllerProvider,
    gamePlayerControlSaveProvider,
    gamePlayerControlControllerProvider,
    gameActivityLogProvider,
    hudFeedbackProvider,
    hudResourceBreakdownControllerProvider,
    hudPanelControllerProvider,
    mapInspectionControllerProvider,
  ],
);
