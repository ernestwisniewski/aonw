import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';

enum GamepadButtonAction {
  confirm,
  cancel,
  moveMode,
  inspect,
  hudFocusPrevious,
  hudFocusNext,
  focusPrevious,
  focusNext,
  primaryAction,
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
  zoomIn,
  zoomOut,
}

enum GamepadAxisAction { cursorX, cursorY, cameraX, cameraY, zoomIn, zoomOut }

final class GamepadControlSettings {
  const GamepadControlSettings({
    this.enabled = true,
    this.deadzone = 0.24,
    this.cameraSensitivity = 1,
    this.invertCameraY = false,
    this.buttonBindings = GamepadButtonBindings.defaults,
    this.axisBindings = GamepadAxisBindings.defaults,
  });

  static const defaults = GamepadControlSettings();

  final bool enabled;
  final double deadzone;
  final double cameraSensitivity;
  final bool invertCameraY;
  final GamepadButtonBindings buttonBindings;
  final GamepadAxisBindings axisBindings;

  GamepadControlSettings copyWith({
    bool? enabled,
    double? deadzone,
    double? cameraSensitivity,
    bool? invertCameraY,
    GamepadButtonBindings? buttonBindings,
    GamepadAxisBindings? axisBindings,
  }) {
    return GamepadControlSettings(
      enabled: enabled ?? this.enabled,
      deadzone: deadzone ?? this.deadzone,
      cameraSensitivity: cameraSensitivity ?? this.cameraSensitivity,
      invertCameraY: invertCameraY ?? this.invertCameraY,
      buttonBindings: buttonBindings ?? this.buttonBindings,
      axisBindings: axisBindings ?? this.axisBindings,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GamepadControlSettings &&
        other.enabled == enabled &&
        other.deadzone == deadzone &&
        other.cameraSensitivity == cameraSensitivity &&
        other.invertCameraY == invertCameraY &&
        other.buttonBindings == buttonBindings &&
        other.axisBindings == axisBindings;
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    deadzone,
    cameraSensitivity,
    invertCameraY,
    buttonBindings,
    axisBindings,
  );
}

final class GamepadButtonBindings {
  const GamepadButtonBindings(this.byAction);

  static const defaults = GamepadButtonBindings({
    GamepadButtonAction.confirm: {GamepadButton.a},
    GamepadButtonAction.cancel: {GamepadButton.b, GamepadButton.back},
    GamepadButtonAction.moveMode: {GamepadButton.x},
    GamepadButtonAction.inspect: {GamepadButton.y},
    GamepadButtonAction.hudFocusPrevious: {GamepadButton.leftStick},
    GamepadButtonAction.hudFocusNext: {GamepadButton.rightStick},
    GamepadButtonAction.focusPrevious: {GamepadButton.leftBumper},
    GamepadButtonAction.focusNext: {GamepadButton.rightBumper},
    GamepadButtonAction.primaryAction: {GamepadButton.start},
    GamepadButtonAction.dpadUp: {GamepadButton.dpadUp},
    GamepadButtonAction.dpadDown: {GamepadButton.dpadDown},
    GamepadButtonAction.dpadLeft: {GamepadButton.dpadLeft},
    GamepadButtonAction.dpadRight: {GamepadButton.dpadRight},
    GamepadButtonAction.zoomIn: {GamepadButton.rightTrigger},
    GamepadButtonAction.zoomOut: {GamepadButton.leftTrigger},
  });

  final Map<GamepadButtonAction, Set<GamepadButton>> byAction;

  Set<GamepadButtonAction> actionsFor(GamepadButton button) {
    return {
      for (final entry in byAction.entries)
        if (entry.value.contains(button)) entry.key,
    };
  }

  GamepadButton? primaryButtonFor(GamepadButtonAction action) {
    final buttons = byAction[action];
    return buttons == null || buttons.isEmpty ? null : buttons.first;
  }

  GamepadButtonBindings bind(GamepadButtonAction action, GamepadButton button) {
    return GamepadButtonBindings({
      for (final entry in byAction.entries)
        entry.key: {
          for (final existing in entry.value)
            if (existing != button || entry.key == action) existing,
        },
      action: {button},
    });
  }

  String toStorage() {
    return jsonEncode({
      for (final entry in byAction.entries)
        entry.key.name: [for (final button in entry.value) button.name],
    });
  }

  static GamepadButtonBindings fromStorage(
    String? value, {
    GamepadButtonBindings fallback = defaults,
  }) {
    if (value == null || value.isEmpty) return fallback;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, Object?>) return fallback;
      final bindings = <GamepadButtonAction, Set<GamepadButton>>{};
      for (final entry in decoded.entries) {
        final action = _enumByName(GamepadButtonAction.values, entry.key);
        final buttons = entry.value;
        if (action == null || buttons is! List<Object?>) continue;
        final mapped = <GamepadButton>{};
        for (final buttonName in buttons) {
          if (buttonName is! String) continue;
          final button = _enumByName(GamepadButton.values, buttonName);
          if (button != null) mapped.add(button);
        }
        if (mapped.isNotEmpty) {
          bindings[action] = mapped.cast<GamepadButton>();
        }
      }
      if (bindings.isEmpty) return fallback;
      return GamepadButtonBindings({...fallback.byAction, ...bindings});
    } on Object {
      return fallback;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is! GamepadButtonBindings) return false;
    if (other.byAction.length != byAction.length) return false;
    for (final entry in byAction.entries) {
      if (!setEquals(other.byAction[entry.key], entry.value)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
    GamepadButtonAction.values.map((action) {
      final buttons = byAction[action] ?? {};
      return Object.hash(
        action,
        Object.hashAll(GamepadButton.values.where(buttons.contains)),
      );
    }),
  );
}

final class GamepadAxisBindings {
  const GamepadAxisBindings(this.byAction);

  static const defaults = GamepadAxisBindings({
    GamepadAxisAction.cursorX: GamepadAxis.leftStickX,
    GamepadAxisAction.cursorY: GamepadAxis.leftStickY,
    GamepadAxisAction.cameraX: GamepadAxis.rightStickX,
    GamepadAxisAction.cameraY: GamepadAxis.rightStickY,
    GamepadAxisAction.zoomIn: GamepadAxis.rightTrigger,
    GamepadAxisAction.zoomOut: GamepadAxis.leftTrigger,
  });

  final Map<GamepadAxisAction, GamepadAxis> byAction;

  GamepadAxisAction? actionFor(GamepadAxis axis) {
    for (final entry in byAction.entries) {
      if (entry.value == axis) return entry.key;
    }
    return null;
  }

  GamepadAxis axisFor(GamepadAxisAction action) {
    return byAction[action] ?? defaults.byAction[action]!;
  }

  GamepadAxisBindings bind(GamepadAxisAction action, GamepadAxis axis) {
    return GamepadAxisBindings({
      for (final entry in byAction.entries)
        if (entry.value != axis || entry.key == action) entry.key: entry.value,
      action: axis,
    });
  }

  String toStorage() {
    return jsonEncode({
      for (final entry in byAction.entries) entry.key.name: entry.value.name,
    });
  }

  static GamepadAxisBindings fromStorage(
    String? value, {
    GamepadAxisBindings fallback = defaults,
  }) {
    if (value == null || value.isEmpty) return fallback;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, Object?>) return fallback;
      final bindings = <GamepadAxisAction, GamepadAxis>{};
      for (final entry in decoded.entries) {
        final action = _enumByName(GamepadAxisAction.values, entry.key);
        final axisName = entry.value;
        if (action == null || axisName is! String) continue;
        final axis = _enumByName(GamepadAxis.values, axisName);
        if (axis != null) bindings[action] = axis;
      }
      if (bindings.isEmpty) return fallback;
      return GamepadAxisBindings({...fallback.byAction, ...bindings});
    } on Object {
      return fallback;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is GamepadAxisBindings && mapEquals(other.byAction, byAction);
  }

  @override
  int get hashCode => Object.hashAll(
    GamepadAxisAction.values.map(
      (action) => Object.hash(action, byAction[action]),
    ),
  );
}

T? _enumByName<T extends Enum>(List<T> values, String name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
