import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/options_value_slider.dart';
import 'package:aonw/menu/widgets/settings_controls.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';

class OptionsGamepadSection extends ConsumerWidget {
  const OptionsGamepadSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(gameplaySettingsProvider);
    final controller = ref.read(gameplaySettingsProvider.notifier);
    return SettingsSection(
      icon: Icons.sports_esports_outlined,
      title: l10n.manualGamepadTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsToggleRow(
            key: const Key('options.gamepadEnabled'),
            icon: Icons.sports_esports_outlined,
            label: l10n.gamepadEnabledLabel,
            value: settings.gamepad.enabled,
            onChanged: ref.withMenuClickValue(controller.setGamepadEnabled),
          ),
          if (settings.gamepad.enabled)
            ..._enabledControls(l10n, settings.gamepad, controller, ref),
        ],
      ),
    );
  }
}

List<Widget> _enabledControls(
  AppLocalizations l10n,
  GamepadControlSettings settings,
  GameplaySettingsController controller,
  WidgetRef ref,
) => [
  OptionsValueSlider(
    key: const Key('options.gamepadDeadzone'),
    label: l10n.gamepadDeadzoneLabel,
    value: settings.deadzone,
    max: 0.6,
    divisions: 12,
    onChanged: ref.withMenuClickValue(controller.setGamepadDeadzone),
  ),
  OptionsValueSlider(
    key: const Key('options.gamepadCameraSensitivity'),
    label: l10n.gamepadCameraSensitivityLabel,
    value: settings.cameraSensitivity,
    min: 0.2,
    max: 2,
    divisions: 18,
    step: 0.1,
    valueLabelBuilder: (value) => '${value.toStringAsFixed(1)}x',
    onChanged: ref.withMenuClickValue(controller.setGamepadCameraSensitivity),
  ),
  SettingsToggleRow(
    key: const Key('options.gamepadInvertCameraY'),
    icon: Icons.swap_vert,
    label: l10n.gamepadInvertCameraYLabel,
    value: settings.invertCameraY,
    onChanged: ref.withMenuClickValue(controller.setGamepadInvertCameraY),
  ),
  const SizedBox(height: 8),
  _buttonBindings(l10n, settings, controller, ref),
  const SizedBox(height: 8),
  _axisBindings(l10n, settings, controller, ref),
  Align(
    alignment: Alignment.centerLeft,
    child: EpicButton.text(
      key: const Key('options.gamepadResetBindings'),
      icon: Icons.restart_alt,
      label: l10n.gamepadResetBindingsLabel,
      onPressed: ref.withMenuClick(controller.resetGamepadBindings),
    ),
  ),
];

Widget _buttonBindings(
  AppLocalizations l10n,
  GamepadControlSettings settings,
  GameplaySettingsController controller,
  WidgetRef ref,
) {
  return _GamepadBindingsGroup(
    title: l10n.gamepadButtonBindingsLabel,
    children: [
      for (final action in GamepadButtonAction.values)
        _GamepadBindingDropdown<GamepadButton>(
          key: ValueKey('options.gamepad.button.${action.name}'),
          label: _gamepadButtonActionLabels[action]!,
          value:
              settings.buttonBindings.primaryButtonFor(action) ??
              GamepadButtonBindings.defaults.primaryButtonFor(action)!,
          values: GamepadButton.values,
          labelFor: (button) => _gamepadButtonLabels[button]!,
          onChanged: (button) {
            if (button == null) return;
            ref.playMenuClick();
            controller.setGamepadButtonBinding(action, button);
          },
        ),
    ],
  );
}

Widget _axisBindings(
  AppLocalizations l10n,
  GamepadControlSettings settings,
  GameplaySettingsController controller,
  WidgetRef ref,
) {
  return _GamepadBindingsGroup(
    title: l10n.gamepadAxisBindingsLabel,
    children: [
      for (final action in GamepadAxisAction.values)
        _GamepadBindingDropdown<GamepadAxis>(
          key: ValueKey('options.gamepad.axis.${action.name}'),
          label: _gamepadAxisActionLabels[action]!,
          value: settings.axisBindings.axisFor(action),
          values: GamepadAxis.values,
          labelFor: (axis) => _gamepadAxisLabels[axis]!,
          onChanged: (axis) {
            if (axis == null) return;
            ref.playMenuClick();
            controller.setGamepadAxisBinding(action, axis);
          },
        ),
    ],
  );
}

class _GamepadBindingsGroup extends StatelessWidget {
  const _GamepadBindingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(46, 2, 2, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GameUiTheme.toolbarLabel.copyWith(color: GameUiTheme.gold),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _GamepadBindingDropdown<T extends Object> extends StatelessWidget {
  const _GamepadBindingDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
    super.key,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: GameUiTheme.surface,
        iconEnabledColor: GameUiTheme.goldLight,
        style: GameUiTheme.inputText,
        decoration: GameUiTheme.textFieldDecoration(hintText: label),
        selectedItemBuilder: (context) => [
          for (final item in values)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$label: ${labelFor(item)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        items: [
          for (final item in values)
            DropdownMenuItem(value: item, child: Text(labelFor(item))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

const _gamepadButtonActionLabels = <GamepadButtonAction, String>{
  GamepadButtonAction.confirm: 'Confirm',
  GamepadButtonAction.cancel: 'Cancel',
  GamepadButtonAction.moveMode: 'Move mode',
  GamepadButtonAction.inspect: 'Inspect',
  GamepadButtonAction.hudFocusPrevious: 'HUD previous section',
  GamepadButtonAction.hudFocusNext: 'HUD next section',
  GamepadButtonAction.focusPrevious: 'Turn-start focus',
  GamepadButtonAction.focusNext: 'Next pending action',
  GamepadButtonAction.primaryAction: 'Primary turn action',
  GamepadButtonAction.dpadUp: 'Cursor up',
  GamepadButtonAction.dpadDown: 'Cursor down',
  GamepadButtonAction.dpadLeft: 'Cursor left',
  GamepadButtonAction.dpadRight: 'Cursor right',
  GamepadButtonAction.zoomIn: 'Zoom in',
  GamepadButtonAction.zoomOut: 'Zoom out',
};

const _gamepadAxisActionLabels = <GamepadAxisAction, String>{
  GamepadAxisAction.cursorX: 'Cursor horizontal',
  GamepadAxisAction.cursorY: 'Cursor vertical',
  GamepadAxisAction.cameraX: 'Camera horizontal',
  GamepadAxisAction.cameraY: 'Camera vertical',
  GamepadAxisAction.zoomIn: 'Zoom in',
  GamepadAxisAction.zoomOut: 'Zoom out',
};

const _gamepadButtonLabels = <GamepadButton, String>{
  GamepadButton.a: 'A',
  GamepadButton.b: 'B',
  GamepadButton.x: 'X',
  GamepadButton.y: 'Y',
  GamepadButton.leftBumper: 'LB',
  GamepadButton.rightBumper: 'RB',
  GamepadButton.leftTrigger: 'LT',
  GamepadButton.rightTrigger: 'RT',
  GamepadButton.back: 'Back',
  GamepadButton.start: 'Start',
  GamepadButton.home: 'Home',
  GamepadButton.leftStick: 'L3',
  GamepadButton.rightStick: 'R3',
  GamepadButton.dpadUp: 'D-pad up',
  GamepadButton.dpadDown: 'D-pad down',
  GamepadButton.dpadLeft: 'D-pad left',
  GamepadButton.dpadRight: 'D-pad right',
  GamepadButton.touchpad: 'Touchpad',
};

const _gamepadAxisLabels = <GamepadAxis, String>{
  GamepadAxis.leftStickX: 'Left stick X',
  GamepadAxis.leftStickY: 'Left stick Y',
  GamepadAxis.rightStickX: 'Right stick X',
  GamepadAxis.rightStickY: 'Right stick Y',
  GamepadAxis.leftTrigger: 'LT analog',
  GamepadAxis.rightTrigger: 'RT analog',
};
