import 'package:aonw/shared/providers/display_settings_provider.dart';
import 'package:aonw/shared/window/game_window.dart';
import 'package:aonw/shared/window/platform_game_window.dart';

final class DisplayBootstrap {
  const DisplayBootstrap({
    required this.gameWindow,
    required this.settingsStore,
    required this.settings,
  });

  final GameWindow gameWindow;
  final DisplaySettingsStore settingsStore;
  final DisplaySettings settings;

  static Future<DisplayBootstrap> prepare({
    GameWindow? gameWindow,
    DisplaySettingsStore? settingsStore,
  }) async {
    final resolvedWindow = gameWindow ?? PlatformGameWindow();
    final resolvedStore = settingsStore ?? const DisplaySettingsStore();
    final settings = resolvedWindow.supportsWindowModes
        ? await resolvedStore.load()
        : const DisplaySettings();
    if (resolvedWindow.supportsWindowModes) {
      await resolvedWindow.initialize(windowed: settings.windowed);
    }
    return DisplayBootstrap(
      gameWindow: resolvedWindow,
      settingsStore: resolvedStore,
      settings: settings,
    );
  }
}
