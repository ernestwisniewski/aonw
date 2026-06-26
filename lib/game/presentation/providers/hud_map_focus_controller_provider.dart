import 'package:aonw/game/presentation/providers/hud_command_dispatcher_provider.dart';
import 'package:aonw/game/presentation/providers/renderer_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/map/hud_map_focus_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hudMapFocusControllerProvider = Provider<HudMapFocusController>(
  HudMapFocusController.new,
  dependencies: [
    activeRendererViewModelProvider,
    hudCommandDispatcherProvider,
    hudPanelControllerProvider,
  ],
);
