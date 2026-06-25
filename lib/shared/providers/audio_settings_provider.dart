import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameAudioSettings {
  const GameAudioSettings({
    this.soundsEnabled = true,
    this.soundVolume = 0.25,
    this.musicEnabled = true,
    this.musicVolume = 0.2,
    this.natureEnabled = true,
    this.natureVolume = 0.4,
  });

  final bool soundsEnabled;
  final double soundVolume;
  final bool musicEnabled;
  final double musicVolume;
  final bool natureEnabled;
  final double natureVolume;

  bool get gameMusicAudible => musicEnabled && musicVolume > 0;

  GameAudioSettings copyWith({
    bool? soundsEnabled,
    double? soundVolume,
    bool? musicEnabled,
    double? musicVolume,
    bool? natureEnabled,
    double? natureVolume,
  }) {
    return GameAudioSettings(
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      soundVolume: _clampVolume(soundVolume ?? this.soundVolume),
      musicEnabled: musicEnabled ?? this.musicEnabled,
      musicVolume: _clampVolume(musicVolume ?? this.musicVolume),
      natureEnabled: natureEnabled ?? this.natureEnabled,
      natureVolume: _clampVolume(natureVolume ?? this.natureVolume),
    );
  }

  static double _clampVolume(double value) => value.clamp(0.0, 1.0).toDouble();
}

final gameAudioSettingsProvider =
    NotifierProvider<GameAudioSettingsController, GameAudioSettings>(
      GameAudioSettingsController.new,
    );

class GameAudioSettingsController extends Notifier<GameAudioSettings> {
  static const _soundsEnabledKey = 'audio.sounds_enabled';
  static const _soundVolumeKey = 'audio.sound_volume';
  static const _musicEnabledKey = 'audio.music_enabled';
  static const _musicVolumeKey = 'audio.music_volume';
  static const _natureEnabledKey = 'audio.nature_enabled';
  static const _natureVolumeKey = 'audio.nature_volume';

  bool _hasLocalChanges = false;

  @override
  GameAudioSettings build() {
    unawaited(_load());
    return const GameAudioSettings();
  }

  void setSoundsEnabled(bool enabled) {
    _update(state.copyWith(soundsEnabled: enabled));
  }

  void setSoundVolume(double volume) {
    _update(state.copyWith(soundVolume: volume));
  }

  void setMusicEnabled(bool enabled) {
    _update(state.copyWith(musicEnabled: enabled));
  }

  void setMusicVolume(double volume) {
    _update(state.copyWith(musicVolume: volume));
  }

  void setNatureEnabled(bool enabled) {
    _update(state.copyWith(natureEnabled: enabled));
  }

  void setNatureVolume(double volume) {
    _update(state.copyWith(natureVolume: volume));
  }

  void _update(GameAudioSettings settings) {
    _hasLocalChanges = true;
    state = settings;
    unawaited(_save(settings));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_hasLocalChanges) return;
      state = GameAudioSettings(
        soundsEnabled: prefs.getBool(_soundsEnabledKey) ?? state.soundsEnabled,
        soundVolume: prefs.getDouble(_soundVolumeKey) ?? state.soundVolume,
        musicEnabled: prefs.getBool(_musicEnabledKey) ?? state.musicEnabled,
        musicVolume: prefs.getDouble(_musicVolumeKey) ?? state.musicVolume,
        natureEnabled: prefs.getBool(_natureEnabledKey) ?? state.natureEnabled,
        natureVolume: prefs.getDouble(_natureVolumeKey) ?? state.natureVolume,
      );
    } on Object {
      return;
    }
  }

  Future<void> _save(GameAudioSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setBool(_soundsEnabledKey, settings.soundsEnabled),
        prefs.setDouble(_soundVolumeKey, settings.soundVolume),
        prefs.setBool(_musicEnabledKey, settings.musicEnabled),
        prefs.setDouble(_musicVolumeKey, settings.musicVolume),
        prefs.setBool(_natureEnabledKey, settings.natureEnabled),
        prefs.setDouble(_natureVolumeKey, settings.natureVolume),
      ]);
      _hasLocalChanges = false;
    } on Object {
      return;
    }
  }
}
