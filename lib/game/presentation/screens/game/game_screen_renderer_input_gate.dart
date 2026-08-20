import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers/hud/hud_gamepad_focus_controller_provider.dart';
import 'package:aonw/game/presentation/providers/player/player_control_provider.dart';
import 'package:aonw/game/presentation/screens/game/gamepad_renderer_input_binding.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps renderer input disabled while turn handoff or HUD input owns focus.
class GameScreenRendererInputGate extends ConsumerWidget {
  const GameScreenRendererInputGate({
    required this.renderer,
    required this.gamepadSettings,
    required this.builder,
    super.key,
  });

  final GameRenderer renderer;
  final GamepadControlSettings gamepadSettings;
  final GamepadRendererInputBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnPresentationBlocksInput = ref.watch(
      gamePlayerControlControllerProvider.select(
        (control) => control.phase.blocksHumanInput,
      ),
    );
    final hudPanelModes = ref.watch(hudPanelControllerProvider);
    final hudGamepadFocusActive = ref.watch(
      hudGamepadFocusControllerProvider.select((state) => state.active),
    );
    final hudGamepadPopupInputCaptured = ref.watch(
      hudGamepadPopupInputCaptureProvider,
    );
    final rendererInputEnabled =
        !turnPresentationBlocksInput &&
        !hudGamepadFocusActive &&
        !hudGamepadPopupInputCaptured &&
        !hudPanelModes.blocksRendererInput;
    return GamepadRendererInputBinding(
      renderer: renderer,
      gamepadSettings: gamepadSettings,
      rendererInputEnabled: rendererInputEnabled,
      builder: builder,
    );
  }
}
