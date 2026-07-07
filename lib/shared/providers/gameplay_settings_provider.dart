import 'dart:async';

import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameplaySettings {
  const GameplaySettings({
    this.followUnitMovementCamera = false,
    this.followEnemyUnitCamera = false,
    this.cinematicCameraEnabled = false,
    this.gamepad = GamepadControlSettings.defaults,
  });

  final bool followUnitMovementCamera;
  final bool followEnemyUnitCamera;
  final bool cinematicCameraEnabled;
  final GamepadControlSettings gamepad;

  GameplaySettings copyWith({
    bool? followUnitMovementCamera,
    bool? followEnemyUnitCamera,
    bool? cinematicCameraEnabled,
    GamepadControlSettings? gamepad,
  }) {
    return GameplaySettings(
      followUnitMovementCamera:
          followUnitMovementCamera ?? this.followUnitMovementCamera,
      followEnemyUnitCamera:
          followEnemyUnitCamera ?? this.followEnemyUnitCamera,
      cinematicCameraEnabled:
          cinematicCameraEnabled ?? this.cinematicCameraEnabled,
      gamepad: gamepad ?? this.gamepad,
    );
  }
}

final gameplaySettingsProvider =
    NotifierProvider<GameplaySettingsController, GameplaySettings>(
      GameplaySettingsController.new,
    );

class GameplaySettingsController extends Notifier<GameplaySettings> {
  static const _followUnitMovementCameraKey =
      'gameplay.follow_unit_movement_camera';
  static const _followEnemyUnitCameraKey = 'gameplay.follow_enemy_unit_camera';
  static const _cinematicCameraEnabledKey = 'gameplay.cinematic_camera_enabled';
  static const _gamepadEnabledKey = 'gameplay.gamepad.enabled';
  static const _gamepadDeadzoneKey = 'gameplay.gamepad.deadzone';
  static const _gamepadCameraSensitivityKey =
      'gameplay.gamepad.camera_sensitivity';
  static const _gamepadInvertCameraYKey = 'gameplay.gamepad.invert_camera_y';
  static const _gamepadButtonBindingsKey = 'gameplay.gamepad.button_bindings';
  static const _gamepadAxisBindingsKey = 'gameplay.gamepad.axis_bindings';

  bool? _pendingFollowUnitMovementCamera;
  bool? _pendingFollowEnemyUnitCamera;
  bool? _pendingCinematicCameraEnabled;
  GamepadControlSettings? _pendingGamepad;
  int _gamepadSaveGeneration = 0;

  @override
  GameplaySettings build() {
    unawaited(_load());
    return const GameplaySettings();
  }

  void setFollowUnitMovementCamera(bool enabled) {
    if (state.followUnitMovementCamera == enabled) return;
    _pendingFollowUnitMovementCamera = enabled;
    state = state.copyWith(followUnitMovementCamera: enabled);
    unawaited(_saveFollowUnitMovementCamera(enabled));
  }

  void setFollowEnemyUnitCamera(bool enabled) {
    if (state.followEnemyUnitCamera == enabled) return;
    _pendingFollowEnemyUnitCamera = enabled;
    state = state.copyWith(followEnemyUnitCamera: enabled);
    unawaited(_saveFollowEnemyUnitCamera(enabled));
  }

  void setCinematicCameraEnabled(bool enabled) {
    if (state.cinematicCameraEnabled == enabled) return;
    _pendingCinematicCameraEnabled = enabled;
    state = state.copyWith(cinematicCameraEnabled: enabled);
    unawaited(_saveCinematicCameraEnabled(enabled));
  }

  void setGamepadEnabled(bool enabled) {
    _setGamepad(state.gamepad.copyWith(enabled: enabled));
  }

  void setGamepadDeadzone(double deadzone) {
    _setGamepad(state.gamepad.copyWith(deadzone: _clampedDeadzone(deadzone)));
  }

  void setGamepadCameraSensitivity(double sensitivity) {
    _setGamepad(
      state.gamepad.copyWith(
        cameraSensitivity: _clampedSensitivity(sensitivity),
      ),
    );
  }

  void setGamepadInvertCameraY(bool enabled) {
    _setGamepad(state.gamepad.copyWith(invertCameraY: enabled));
  }

  void setGamepadButtonBinding(
    GamepadButtonAction action,
    GamepadButton button,
  ) {
    _setGamepad(
      state.gamepad.copyWith(
        buttonBindings: state.gamepad.buttonBindings.bind(action, button),
      ),
    );
  }

  void setGamepadAxisBinding(GamepadAxisAction action, GamepadAxis axis) {
    _setGamepad(
      state.gamepad.copyWith(
        axisBindings: state.gamepad.axisBindings.bind(action, axis),
      ),
    );
  }

  void resetGamepadBindings() {
    _setGamepad(
      state.gamepad.copyWith(
        buttonBindings: GamepadButtonBindings.defaults,
        axisBindings: GamepadAxisBindings.defaults,
      ),
    );
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        followUnitMovementCamera:
            _pendingFollowUnitMovementCamera ??
            prefs.getBool(_followUnitMovementCameraKey) ??
            state.followUnitMovementCamera,
        followEnemyUnitCamera:
            _pendingFollowEnemyUnitCamera ??
            prefs.getBool(_followEnemyUnitCameraKey) ??
            state.followEnemyUnitCamera,
        cinematicCameraEnabled:
            _pendingCinematicCameraEnabled ??
            prefs.getBool(_cinematicCameraEnabledKey) ??
            state.cinematicCameraEnabled,
        gamepad: _pendingGamepad ?? _gamepadSettingsFrom(prefs, state.gamepad),
      );
    } on Object {
      return;
    }
  }

  Future<void> _saveFollowUnitMovementCamera(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_followUnitMovementCameraKey, enabled);
      if (_pendingFollowUnitMovementCamera == enabled) {
        _pendingFollowUnitMovementCamera = null;
      }
    } on Object {
      return;
    }
  }

  Future<void> _saveFollowEnemyUnitCamera(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_followEnemyUnitCameraKey, enabled);
      if (_pendingFollowEnemyUnitCamera == enabled) {
        _pendingFollowEnemyUnitCamera = null;
      }
    } on Object {
      return;
    }
  }

  Future<void> _saveCinematicCameraEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cinematicCameraEnabledKey, enabled);
      if (_pendingCinematicCameraEnabled == enabled) {
        _pendingCinematicCameraEnabled = null;
      }
    } on Object {
      return;
    }
  }

  void _setGamepad(GamepadControlSettings settings) {
    if (state.gamepad == settings) return;
    _pendingGamepad = settings;
    state = state.copyWith(gamepad: settings);
    _gamepadSaveGeneration += 1;
    unawaited(_saveGamepad(settings, generation: _gamepadSaveGeneration));
  }

  GamepadControlSettings _gamepadSettingsFrom(
    SharedPreferences prefs,
    GamepadControlSettings fallback,
  ) {
    return fallback.copyWith(
      enabled: prefs.getBool(_gamepadEnabledKey) ?? fallback.enabled,
      deadzone: _clampedDeadzone(
        prefs.getDouble(_gamepadDeadzoneKey) ?? fallback.deadzone,
      ),
      cameraSensitivity: _clampedSensitivity(
        prefs.getDouble(_gamepadCameraSensitivityKey) ??
            fallback.cameraSensitivity,
      ),
      invertCameraY:
          prefs.getBool(_gamepadInvertCameraYKey) ?? fallback.invertCameraY,
      buttonBindings: GamepadButtonBindings.fromStorage(
        prefs.getString(_gamepadButtonBindingsKey),
        fallback: fallback.buttonBindings,
      ),
      axisBindings: GamepadAxisBindings.fromStorage(
        prefs.getString(_gamepadAxisBindingsKey),
        fallback: fallback.axisBindings,
      ),
    );
  }

  Future<void> _saveGamepad(
    GamepadControlSettings settings, {
    required int generation,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_isCurrentGamepadSave(settings, generation)) return;
      await prefs.setBool(_gamepadEnabledKey, settings.enabled);
      if (!_isCurrentGamepadSave(settings, generation)) return;
      await prefs.setDouble(_gamepadDeadzoneKey, settings.deadzone);
      if (!_isCurrentGamepadSave(settings, generation)) return;
      await prefs.setDouble(
        _gamepadCameraSensitivityKey,
        settings.cameraSensitivity,
      );
      if (!_isCurrentGamepadSave(settings, generation)) return;
      await prefs.setBool(_gamepadInvertCameraYKey, settings.invertCameraY);
      if (!_isCurrentGamepadSave(settings, generation)) return;
      await prefs.setString(
        _gamepadButtonBindingsKey,
        settings.buttonBindings.toStorage(),
      );
      if (!_isCurrentGamepadSave(settings, generation)) return;
      await prefs.setString(
        _gamepadAxisBindingsKey,
        settings.axisBindings.toStorage(),
      );
      if (_isCurrentGamepadSave(settings, generation)) {
        _pendingGamepad = null;
      }
    } on Object {
      return;
    }
  }

  bool _isCurrentGamepadSave(GamepadControlSettings settings, int generation) {
    return generation == _gamepadSaveGeneration && state.gamepad == settings;
  }

  double _clampedDeadzone(double value) {
    return value.clamp(0, 0.6).toDouble();
  }

  double _clampedSensitivity(double value) {
    return value.clamp(0.2, 1).toDouble();
  }
}
