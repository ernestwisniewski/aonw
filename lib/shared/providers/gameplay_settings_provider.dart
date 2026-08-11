import 'dart:async';

import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _legacyFollowUnitMovementCameraKey =
    'gameplay.follow_unit_movement_camera';
const _legacyFollowEnemyUnitCameraKey = 'gameplay.follow_enemy_unit_camera';
const _focusOwnUnitMovementCameraKey =
    'gameplay.focus_own_unit_movement_camera';
const _followEnemyUnitMovementCameraKey =
    'gameplay.follow_enemy_unit_movement_camera';
const _cinematicCameraEnabledKey = 'gameplay.cinematic_camera_enabled';
const _autoActionFlowEnabledKey = 'gameplay.auto_action_flow_enabled';
const _autoTurnFlowEnabledKey = 'gameplay.auto_turn_flow_enabled';
const _preferredMapViewModeKey = 'gameplay.preferred_map_view_mode';
const _gamepadEnabledKey = 'gameplay.gamepad.enabled';
const _gamepadDeadzoneKey = 'gameplay.gamepad.deadzone';
const _gamepadCameraSensitivityKey = 'gameplay.gamepad.camera_sensitivity';
const _gamepadInvertCameraYKey = 'gameplay.gamepad.invert_camera_y';
const _gamepadButtonBindingsKey = 'gameplay.gamepad.button_bindings';
const _gamepadAxisBindingsKey = 'gameplay.gamepad.axis_bindings';

class GameplaySettings {
  const GameplaySettings({
    this.focusOwnUnitMovementCamera = true,
    this.followOwnUnitMovementCamera = false,
    this.focusEnemyUnitMovementCamera = false,
    this.followEnemyUnitMovementCamera = false,
    this.cinematicCameraEnabled = false,
    this.autoActionFlowEnabled = true,
    this.autoTurnFlowEnabled = false,
    this.preferredMapViewMode = MapViewMode.graphic,
    this.gamepad = GamepadControlSettings.defaults,
  });

  final bool focusOwnUnitMovementCamera;
  final bool followOwnUnitMovementCamera;
  final bool focusEnemyUnitMovementCamera;
  final bool followEnemyUnitMovementCamera;
  final bool cinematicCameraEnabled;
  final bool autoActionFlowEnabled;
  final bool autoTurnFlowEnabled;
  final MapViewMode preferredMapViewMode;
  final GamepadControlSettings gamepad;

  /// Compatibility alias for the former ambiguous own-unit setting.
  bool get followUnitMovementCamera => followOwnUnitMovementCamera;

  /// Compatibility alias: this setting used to gate enemy camera focus.
  bool get followEnemyUnitCamera => focusEnemyUnitMovementCamera;

  GameplaySettings copyWith({
    bool? focusOwnUnitMovementCamera,
    bool? followOwnUnitMovementCamera,
    bool? focusEnemyUnitMovementCamera,
    bool? followEnemyUnitMovementCamera,
    bool? cinematicCameraEnabled,
    bool? autoActionFlowEnabled,
    bool? autoTurnFlowEnabled,
    MapViewMode? preferredMapViewMode,
    GamepadControlSettings? gamepad,
  }) {
    return GameplaySettings(
      focusOwnUnitMovementCamera:
          focusOwnUnitMovementCamera ?? this.focusOwnUnitMovementCamera,
      followOwnUnitMovementCamera:
          followOwnUnitMovementCamera ?? this.followOwnUnitMovementCamera,
      focusEnemyUnitMovementCamera:
          focusEnemyUnitMovementCamera ?? this.focusEnemyUnitMovementCamera,
      followEnemyUnitMovementCamera:
          followEnemyUnitMovementCamera ?? this.followEnemyUnitMovementCamera,
      cinematicCameraEnabled:
          cinematicCameraEnabled ?? this.cinematicCameraEnabled,
      autoActionFlowEnabled:
          autoActionFlowEnabled ?? this.autoActionFlowEnabled,
      autoTurnFlowEnabled: autoTurnFlowEnabled ?? this.autoTurnFlowEnabled,
      preferredMapViewMode: preferredMapViewMode ?? this.preferredMapViewMode,
      gamepad: gamepad ?? this.gamepad,
    );
  }
}

final gameplaySettingsProvider =
    NotifierProvider<GameplaySettingsController, GameplaySettings>(
      GameplaySettingsController.new,
    );

class GameplaySettingsController extends Notifier<GameplaySettings> {
  bool? _pendingFocusOwnUnitMovementCamera;
  bool? _pendingFollowOwnUnitMovementCamera;
  bool? _pendingFocusEnemyUnitMovementCamera;
  bool? _pendingFollowEnemyUnitMovementCamera;
  bool? _pendingCinematicCameraEnabled;
  bool? _pendingAutoActionFlowEnabled;
  bool? _pendingAutoTurnFlowEnabled;
  MapViewMode? _pendingPreferredMapViewMode;
  GamepadControlSettings? _pendingGamepad;
  int _gamepadSaveGeneration = 0;
  Future<void>? _loadFuture;

  @override
  GameplaySettings build() {
    unawaited(ensureLoaded());
    return const GameplaySettings();
  }

  Future<void> ensureLoaded() => _loadFuture ??= _load();

  void setFocusOwnUnitMovementCamera(bool enabled) {
    if (state.focusOwnUnitMovementCamera == enabled) return;
    _pendingFocusOwnUnitMovementCamera = enabled;
    state = state.copyWith(focusOwnUnitMovementCamera: enabled);
    unawaited(
      _saveBool(
        _focusOwnUnitMovementCameraKey,
        enabled,
        onSaved: () {
          if (_pendingFocusOwnUnitMovementCamera == enabled) {
            _pendingFocusOwnUnitMovementCamera = null;
          }
        },
      ),
    );
  }

  void setFollowOwnUnitMovementCamera(bool enabled) {
    if (state.followOwnUnitMovementCamera == enabled) return;
    _pendingFollowOwnUnitMovementCamera = enabled;
    state = state.copyWith(followOwnUnitMovementCamera: enabled);
    unawaited(
      _saveBool(
        _legacyFollowUnitMovementCameraKey,
        enabled,
        onSaved: () {
          if (_pendingFollowOwnUnitMovementCamera == enabled) {
            _pendingFollowOwnUnitMovementCamera = null;
          }
        },
      ),
    );
  }

  void setFocusEnemyUnitMovementCamera(bool enabled) {
    if (state.focusEnemyUnitMovementCamera == enabled) return;
    _pendingFocusEnemyUnitMovementCamera = enabled;
    state = state.copyWith(focusEnemyUnitMovementCamera: enabled);
    unawaited(
      _saveBool(
        _legacyFollowEnemyUnitCameraKey,
        enabled,
        onSaved: () {
          if (_pendingFocusEnemyUnitMovementCamera == enabled) {
            _pendingFocusEnemyUnitMovementCamera = null;
          }
        },
      ),
    );
  }

  void setFollowEnemyUnitMovementCamera(bool enabled) {
    if (state.followEnemyUnitMovementCamera == enabled) return;
    _pendingFollowEnemyUnitMovementCamera = enabled;
    state = state.copyWith(followEnemyUnitMovementCamera: enabled);
    unawaited(
      _saveBool(
        _followEnemyUnitMovementCameraKey,
        enabled,
        onSaved: () {
          if (_pendingFollowEnemyUnitMovementCamera == enabled) {
            _pendingFollowEnemyUnitMovementCamera = null;
          }
        },
      ),
    );
  }

  void setFollowUnitMovementCamera(bool enabled) =>
      setFollowOwnUnitMovementCamera(enabled);

  void setFollowEnemyUnitCamera(bool enabled) =>
      setFocusEnemyUnitMovementCamera(enabled);

  void setCinematicCameraEnabled(bool enabled) {
    if (state.cinematicCameraEnabled == enabled) return;
    _pendingCinematicCameraEnabled = enabled;
    state = state.copyWith(cinematicCameraEnabled: enabled);
    unawaited(_saveCinematicCameraEnabled(enabled));
  }

  void setAutoActionFlowEnabled(bool enabled) {
    if (state.autoActionFlowEnabled == enabled) return;
    _pendingAutoActionFlowEnabled = enabled;
    state = state.copyWith(autoActionFlowEnabled: enabled);
    unawaited(
      _saveBool(
        _autoActionFlowEnabledKey,
        enabled,
        onSaved: () {
          if (_pendingAutoActionFlowEnabled == enabled) {
            _pendingAutoActionFlowEnabled = null;
          }
        },
      ),
    );
  }

  void setAutoTurnFlowEnabled(bool enabled) {
    if (state.autoTurnFlowEnabled == enabled) return;
    _pendingAutoTurnFlowEnabled = enabled;
    state = state.copyWith(autoTurnFlowEnabled: enabled);
    unawaited(
      _saveBool(
        _autoTurnFlowEnabledKey,
        enabled,
        onSaved: () {
          if (_pendingAutoTurnFlowEnabled == enabled) {
            _pendingAutoTurnFlowEnabled = null;
          }
        },
      ),
    );
  }

  void setPreferredMapViewMode(MapViewMode mode) {
    if (state.preferredMapViewMode == mode) return;
    _pendingPreferredMapViewMode = mode;
    state = state.copyWith(preferredMapViewMode: mode);
    unawaited(_savePreferredMapViewMode(mode));
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
      final storedFollowOwn =
          prefs.getBool(_legacyFollowUnitMovementCameraKey) ??
          state.followOwnUnitMovementCamera;
      final storedFocusEnemy =
          prefs.getBool(_legacyFollowEnemyUnitCameraKey) ??
          state.focusEnemyUnitMovementCamera;
      state = state.copyWith(
        focusOwnUnitMovementCamera:
            _pendingFocusOwnUnitMovementCamera ??
            prefs.getBool(_focusOwnUnitMovementCameraKey) ??
            state.focusOwnUnitMovementCamera,
        followOwnUnitMovementCamera:
            _pendingFollowOwnUnitMovementCamera ?? storedFollowOwn,
        focusEnemyUnitMovementCamera:
            _pendingFocusEnemyUnitMovementCamera ?? storedFocusEnemy,
        followEnemyUnitMovementCamera:
            _pendingFollowEnemyUnitMovementCamera ??
            prefs.getBool(_followEnemyUnitMovementCameraKey) ??
            (storedFollowOwn && storedFocusEnemy),
        cinematicCameraEnabled:
            _pendingCinematicCameraEnabled ??
            prefs.getBool(_cinematicCameraEnabledKey) ??
            state.cinematicCameraEnabled,
        autoActionFlowEnabled:
            _pendingAutoActionFlowEnabled ??
            prefs.getBool(_autoActionFlowEnabledKey) ??
            state.autoActionFlowEnabled,
        autoTurnFlowEnabled:
            _pendingAutoTurnFlowEnabled ??
            prefs.getBool(_autoTurnFlowEnabledKey) ??
            state.autoTurnFlowEnabled,
        preferredMapViewMode:
            _pendingPreferredMapViewMode ??
            _storedMapViewMode(prefs.getString(_preferredMapViewModeKey)) ??
            state.preferredMapViewMode,
        gamepad: _pendingGamepad ?? _gamepadSettingsFrom(prefs, state.gamepad),
      );
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

  Future<void> _saveBool(
    String key,
    bool enabled, {
    required void Function() onSaved,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, enabled);
      onSaved();
    } on Object {
      return;
    }
  }

  Future<void> _savePreferredMapViewMode(MapViewMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_preferredMapViewModeKey, mode.name);
      if (_pendingPreferredMapViewMode == mode) {
        _pendingPreferredMapViewMode = null;
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
}

MapViewMode? _storedMapViewMode(String? name) {
  for (final mode in MapViewMode.values) {
    if (mode.name == name) return mode;
  }
  return null;
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

double _clampedDeadzone(double value) => value.clamp(0, 0.6).toDouble();

double _clampedSensitivity(double value) => value.clamp(0.2, 2).toDouble();
