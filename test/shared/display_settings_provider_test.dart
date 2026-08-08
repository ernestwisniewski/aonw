import 'package:aonw/shared/providers/display_settings_provider.dart';
import 'package:aonw/shared/window/game_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('uses full screen as the default display mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(displaySettingsProvider).windowed, isFalse);
  });

  test('loads the stored windowed preference', () async {
    SharedPreferences.setMockInitialValues({
      DisplaySettingsStore.windowedPreferenceKey: true,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(displaySettingsProvider);

    await Future<void>.delayed(Duration.zero);

    expect(container.read(displaySettingsProvider).windowed, isTrue);
  });

  test('applies and persists a display mode change', () async {
    final window = _RecordingGameWindow();
    final container = ProviderContainer(
      overrides: [gameWindowProvider.overrideWithValue(window)],
    );
    addTearDown(container.dispose);

    await container.read(displaySettingsProvider.notifier).setWindowed(true);

    final preferences = await SharedPreferences.getInstance();
    expect(container.read(displaySettingsProvider).windowed, isTrue);
    expect(window.appliedWindowModes, [true]);
    expect(
      preferences.getBool(DisplaySettingsStore.windowedPreferenceKey),
      isTrue,
    );
  });

  test(
    'restores the previous mode when the platform rejects a change',
    () async {
      final window = _RecordingGameWindow(failForWindowed: true);
      final container = ProviderContainer(
        overrides: [gameWindowProvider.overrideWithValue(window)],
      );
      addTearDown(container.dispose);

      await container.read(displaySettingsProvider.notifier).setWindowed(true);

      final preferences = await SharedPreferences.getInstance();
      expect(container.read(displaySettingsProvider).windowed, isFalse);
      expect(window.appliedWindowModes, [true, false]);
      expect(
        preferences.getBool(DisplaySettingsStore.windowedPreferenceKey),
        isNull,
      );
    },
  );

  test('recognizes only native desktop platforms', () {
    expect(
      supportsDesktopWindowModes(
        isWeb: false,
        platform: TargetPlatform.windows,
      ),
      isTrue,
    );
    expect(
      supportsDesktopWindowModes(isWeb: false, platform: TargetPlatform.macOS),
      isTrue,
    );
    expect(
      supportsDesktopWindowModes(isWeb: false, platform: TargetPlatform.linux),
      isTrue,
    );
    expect(
      supportsDesktopWindowModes(
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      isFalse,
    );
    expect(
      supportsDesktopWindowModes(isWeb: true, platform: TargetPlatform.windows),
      isFalse,
    );
  });
}

final class _RecordingGameWindow implements GameWindow {
  _RecordingGameWindow({this.failForWindowed = false});

  final bool failForWindowed;
  final List<bool> appliedWindowModes = [];

  @override
  bool get supportsWindowModes => true;

  @override
  Future<void> initialize({required bool windowed}) async {}

  @override
  Future<void> setWindowed(bool windowed) async {
    appliedWindowModes.add(windowed);
    if (failForWindowed && windowed) {
      throw StateError('window mode unavailable');
    }
  }
}
