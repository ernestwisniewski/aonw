import 'dart:async';

import 'package:aonw/shared/window/game_window.dart';
import 'package:aonw/shared/window/platform_game_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class DisplaySettings {
  const DisplaySettings({this.windowed = false});

  final bool windowed;

  DisplaySettings copyWith({bool? windowed}) {
    return DisplaySettings(windowed: windowed ?? this.windowed);
  }
}

final class DisplaySettingsStore {
  const DisplaySettingsStore();

  static const windowedPreferenceKey = 'display.windowed';

  Future<DisplaySettings> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return DisplaySettings(
        windowed: preferences.getBool(windowedPreferenceKey) ?? false,
      );
    } on Object {
      return const DisplaySettings();
    }
  }

  Future<void> saveWindowed(bool windowed) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(windowedPreferenceKey, windowed);
  }
}

final gameWindowProvider = Provider<GameWindow>((ref) => PlatformGameWindow());

final displaySettingsStoreProvider = Provider<DisplaySettingsStore>(
  (ref) => const DisplaySettingsStore(),
);

final displaySettingsProvider =
    NotifierProvider<DisplaySettingsController, DisplaySettings>(
      DisplaySettingsController.new,
    );

final class DisplaySettingsController extends Notifier<DisplaySettings> {
  DisplaySettingsController({
    this.initialSettings = const DisplaySettings(),
    this.loadStoredSettings = true,
  });

  final DisplaySettings initialSettings;
  final bool loadStoredSettings;

  bool _hasLocalChanges = false;
  bool _isApplying = false;

  @override
  DisplaySettings build() {
    if (loadStoredSettings) unawaited(_load());
    return initialSettings;
  }

  Future<void> setWindowed(bool windowed) async {
    if (_isApplying || state.windowed == windowed) return;
    final previous = state.windowed;
    _hasLocalChanges = true;
    _isApplying = true;
    state = state.copyWith(windowed: windowed);
    try {
      await ref.read(gameWindowProvider).setWindowed(windowed);
      await ref.read(displaySettingsStoreProvider).saveWindowed(windowed);
    } on Object {
      if (state.windowed == windowed) {
        state = state.copyWith(windowed: previous);
      }
      await _restoreWindowMode(previous);
    } finally {
      _isApplying = false;
    }
  }

  Future<void> _load() async {
    final stored = await ref.read(displaySettingsStoreProvider).load();
    if (_hasLocalChanges) return;
    state = stored;
  }

  Future<void> _restoreWindowMode(bool windowed) async {
    try {
      await ref.read(gameWindowProvider).setWindowed(windowed);
    } on Object {
      return;
    }
  }
}
