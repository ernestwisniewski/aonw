import 'package:flutter/services.dart';

import '../../features/logistics/application/unit_logistics_session_port.dart';
import '../../features/map/application/map_session_port.dart';
import '../../features/map/application/movement_session_port.dart';
import '../../features/map/infrastructure/gamepad_map_input_source.dart';
import '../../features/map/infrastructure/rust_game_session_gateway.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../features/map/presentation/map_presentation_controller.dart';
import '../../features/settings/application/client_settings_store.dart';
import '../../features/settings/infrastructure/shared_preferences_client_settings_store.dart';
import '../../features/settings/presentation/client_settings_controller.dart';
import '../../features/turns/application/turn_session_port.dart';
import '../../features/unit_actions/application/unit_action_session_port.dart';
import '../../game/aonw_flame_game.dart';
import '../navigation/aonw_app.dart';
import '../telemetry/client_telemetry.dart';

final class AppComposition {
  AppComposition({
    required MapSessionPort mapSession,
    required MovementSessionPort movementSession,
    required UnitLogisticsSessionPort logisticsSession,
    required UnitActionSessionPort unitActionSession,
    required TurnSessionPort turnSession,
    MapInputSource? mapInputSource,
    ClientSettingsStore? settingsStore,
    AonwFlameGameFactory flameGameFactory = AonwFlameGame.new,
    ClientTelemetry telemetry = const NoOpClientTelemetry(),
  }) : root = AonwApp(
         mapController: MapPresentationController(
           session: mapSession,
           movement: movementSession,
           logistics: logisticsSession,
           unitActions: unitActionSession,
           turns: turnSession,
         ),
         mapInputSource: mapInputSource,
         flameGameFactory: flameGameFactory,
         telemetry: telemetry,
         settingsController: settingsStore == null
             ? ClientSettingsController.ephemeral()
             : ClientSettingsController(store: settingsStore),
       );

  factory AppComposition.production({
    ClientTelemetry telemetry = const DebugClientTelemetry(),
  }) {
    final gateway = RustGameSessionGateway(assets: rootBundle);
    return AppComposition(
      mapSession: gateway,
      movementSession: gateway,
      logisticsSession: gateway,
      unitActionSession: gateway,
      turnSession: gateway,
      mapInputSource: GamepadMapInputSource(),
      settingsStore: SharedPreferencesClientSettingsStore(),
      telemetry: telemetry,
    );
  }

  final AonwApp root;
}
