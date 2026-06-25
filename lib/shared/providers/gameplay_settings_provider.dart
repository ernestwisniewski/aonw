import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameplaySettings {
  const GameplaySettings({
    this.followUnitMovementCamera = false,
    this.followEnemyUnitCamera = false,
    this.cinematicCameraEnabled = false,
  });

  final bool followUnitMovementCamera;
  final bool followEnemyUnitCamera;
  final bool cinematicCameraEnabled;

  GameplaySettings copyWith({
    bool? followUnitMovementCamera,
    bool? followEnemyUnitCamera,
    bool? cinematicCameraEnabled,
  }) {
    return GameplaySettings(
      followUnitMovementCamera:
          followUnitMovementCamera ?? this.followUnitMovementCamera,
      followEnemyUnitCamera:
          followEnemyUnitCamera ?? this.followEnemyUnitCamera,
      cinematicCameraEnabled:
          cinematicCameraEnabled ?? this.cinematicCameraEnabled,
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

  bool? _pendingFollowUnitMovementCamera;
  bool? _pendingFollowEnemyUnitCamera;
  bool? _pendingCinematicCameraEnabled;

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
}
