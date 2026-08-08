import 'package:aonw/app/display_bootstrap.dart';
import 'package:aonw/shared/providers/display_settings_provider.dart';
import 'package:aonw/shared/window/game_window.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('desktop startup defaults to full screen', () async {
    final window = _RecordingGameWindow();

    final bootstrap = await DisplayBootstrap.prepare(gameWindow: window);

    expect(bootstrap.settings.windowed, isFalse);
    expect(window.initialWindowModes, [false]);
  });

  test('desktop startup honors the stored windowed preference', () async {
    SharedPreferences.setMockInitialValues({
      DisplaySettingsStore.windowedPreferenceKey: true,
    });
    final window = _RecordingGameWindow();

    final bootstrap = await DisplayBootstrap.prepare(gameWindow: window);

    expect(bootstrap.settings.windowed, isTrue);
    expect(window.initialWindowModes, [true]);
  });

  test('non-desktop startup skips native window initialization', () async {
    SharedPreferences.setMockInitialValues({
      DisplaySettingsStore.windowedPreferenceKey: true,
    });
    final window = _RecordingGameWindow(supportsWindowModes: false);

    final bootstrap = await DisplayBootstrap.prepare(gameWindow: window);

    expect(bootstrap.settings.windowed, isFalse);
    expect(window.initialWindowModes, isEmpty);
  });
}

final class _RecordingGameWindow implements GameWindow {
  _RecordingGameWindow({this.supportsWindowModes = true});

  @override
  final bool supportsWindowModes;

  final List<bool> initialWindowModes = [];

  @override
  Future<void> initialize({required bool windowed}) async {
    initialWindowModes.add(windowed);
  }

  @override
  Future<void> setWindowed(bool windowed) async {}
}
