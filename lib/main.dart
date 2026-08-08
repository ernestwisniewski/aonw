import 'package:aonw/app/app.dart';
import 'package:aonw/app/display_bootstrap.dart';
import 'package:aonw/shared/providers/display_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final display = await DisplayBootstrap.prepare();
  runApp(
    ProviderScope(
      overrides: [
        gameWindowProvider.overrideWithValue(display.gameWindow),
        displaySettingsStoreProvider.overrideWithValue(display.settingsStore),
        displaySettingsProvider.overrideWith(
          () => DisplaySettingsController(
            initialSettings: display.settings,
            loadStoredSettings: false,
          ),
        ),
      ],
      child: const HexApp(),
    ),
  );
}
