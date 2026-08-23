import 'package:flutter/services.dart';

import '../../features/map/application/map_controller.dart';
import '../../features/map/application/map_repository.dart';
import '../../features/map/infrastructure/gamepad_map_input_source.dart';
import '../../features/map/infrastructure/rust_map_repository.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../features/settings/application/client_settings_controller.dart';
import '../../features/settings/application/client_settings_store.dart';
import '../../features/settings/infrastructure/shared_preferences_client_settings_store.dart';
import '../navigation/aonw_app.dart';

final class AppComposition {
  AppComposition({
    required MapRepository mapRepository,
    MapInputSource? mapInputSource,
    ClientSettingsStore? settingsStore,
  }) : root = AonwApp(
         mapController: MapController(repository: mapRepository),
         mapInputSource: mapInputSource,
         settingsController: settingsStore == null
             ? ClientSettingsController.ephemeral()
             : ClientSettingsController(store: settingsStore),
       );

  factory AppComposition.production() => AppComposition(
    mapRepository: RustMapRepository(assets: rootBundle),
    mapInputSource: GamepadMapInputSource(),
    settingsStore: SharedPreferencesClientSettingsStore(),
  );

  final AonwApp root;
}
