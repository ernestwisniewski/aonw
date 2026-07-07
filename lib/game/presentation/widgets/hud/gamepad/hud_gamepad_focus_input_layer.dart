import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers/hud/hud_command_dispatcher_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_gamepad_focus_controller_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/gamepad/hud_gamepad_focus_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HudGamepadFocusInputLayer extends ConsumerWidget {
  const HudGamepadFocusInputLayer({
    required this.input,
    required this.enabled,
    required this.targets,
    required this.resourceBreakdownOpen,
    required this.child,
    super.key,
  });

  final ValueListenable<GamepadInputSnapshot> input;
  final bool enabled;
  final List<HudGamepadFocusTarget> targets;
  final bool resourceBreakdownOpen;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusState = ref.watch(hudGamepadFocusControllerProvider);
    final popupInputCaptured = ref.watch(hudGamepadPopupInputCaptureProvider);
    final controller = ref.read(hudGamepadFocusControllerProvider.notifier);
    final popupOpen = resourceBreakdownOpen || popupInputCaptured;
    final focusNavigationActive = focusState.active && !popupOpen;
    _syncTargets(context, ref, controller);
    return GamepadPanelInputListener(
      input: input,
      enabled: enabled,
      priority: GamepadInputRoutePriority.hud,
      onHudFocusPrevious: popupOpen
          ? null
          : () => controller.previousSection(_currentTargets(ref)),
      onHudFocusNext: popupOpen
          ? null
          : focusState.active
          ? () => controller.nextSection(_currentTargets(ref))
          : () => controller.focusSection(
              _currentTargets(ref),
              HudGamepadFocusSection.selectionActions,
              fallbackSection: HudGamepadFocusSection.menu,
              optimistic: true,
            ),
      onNavigate: focusNavigationActive
          ? (direction) => controller.move(direction, _currentTargets(ref))
          : null,
      onConfirm: focusNavigationActive
          ? () => controller.activateFocused(_currentTargets(ref))
          : null,
      onCancel: resourceBreakdownOpen || (focusState.active && !popupOpen)
          ? () =>
                _handleCancel(ref, resourceBreakdownOpen: resourceBreakdownOpen)
          : null,
      onFocusPrevious: focusNavigationActive
          ? () => controller.previousSection(targets)
          : null,
      onFocusNext: focusNavigationActive
          ? () => controller.nextSection(targets)
          : null,
      child: child,
    );
  }

  List<HudGamepadFocusTarget> _currentTargets(WidgetRef ref) {
    final currentTargets = HudGamepadFocusTargetRegistry.flatten(
      ref.read(hudGamepadFocusTargetRegistryProvider),
    );
    return currentTargets.isEmpty ? targets : currentTargets;
  }

  void _syncTargets(
    BuildContext context,
    WidgetRef ref,
    HudGamepadFocusController controller,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      controller.syncTargets(_currentTargets(ref), enabled: enabled);
    });
  }

  void _handleCancel(WidgetRef ref, {required bool resourceBreakdownOpen}) {
    if (resourceBreakdownOpen) {
      ref.read(hudCommandDispatcherProvider).closeResourceBreakdown();
      return;
    }
    ref.read(hudGamepadFocusControllerProvider.notifier).deactivate();
  }
}
