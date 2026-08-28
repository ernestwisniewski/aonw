import 'package:flutter/services.dart';

import '../../features/artifacts/application/artifact_session_port.dart';
import '../../features/cities/application/city_session_port.dart';
import '../../features/combat/application/combat_session_port.dart';
import '../../features/logistics/application/unit_logistics_session_port.dart';
import '../../features/map/application/map_session_port.dart';
import '../../features/map/application/movement_session_port.dart';
import '../../features/map/infrastructure/gamepad_map_input_source.dart';
import '../../features/map/infrastructure/rust_game_session_gateway.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../features/map/presentation/map_presentation_controller.dart';
import '../../features/production/application/production_session_port.dart';
import '../../features/settings/application/client_settings_store.dart';
import '../../features/settings/infrastructure/shared_preferences_client_settings_store.dart';
import '../../features/settings/presentation/client_settings_controller.dart';
import '../../features/turns/application/turn_session_port.dart';
import '../../features/unit_actions/application/unit_action_session_port.dart';
import '../../features/workers/application/worker_session_port.dart';
import '../../game/aonw_flame_game.dart';
import '../navigation/aonw_app.dart';
import '../telemetry/client_telemetry.dart';

final class AppComposition {
  AppComposition({
    required MapSessionPort mapSession,
    required MovementSessionPort movementSession,
    CombatSessionPort? combatSession,
    CitySessionPort? citySession,
    required UnitLogisticsSessionPort logisticsSession,
    WorkerSessionPort? workerSession,
    ProductionSessionPort? productionSession,
    ArtifactSessionPort? artifactSession,
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
           combat: combatSession ?? _requireCombatSession(movementSession),
           cities: citySession ?? _requireCitySession(movementSession),
           logistics: logisticsSession,
           workers: workerSession ?? _requireWorkerSession(movementSession),
           production:
               productionSession ?? _requireProductionSession(movementSession),
           artifacts:
               artifactSession ?? _requireArtifactSession(movementSession),
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
      combatSession: gateway,
      citySession: gateway.citySession,
      logisticsSession: gateway,
      workerSession: gateway.workerSession,
      productionSession: gateway.productionSession,
      artifactSession: gateway.artifactSession,
      unitActionSession: gateway,
      turnSession: gateway,
      mapInputSource: GamepadMapInputSource(),
      settingsStore: SharedPreferencesClientSettingsStore(),
      telemetry: telemetry,
    );
  }

  final AonwApp root;
}

CombatSessionPort _requireCombatSession(MovementSessionPort movement) {
  if (movement case final CombatSessionPort combat) return combat;
  throw ArgumentError.value(
    movement,
    'movementSession',
    'must also provide the combat session port',
  );
}

CitySessionPort _requireCitySession(MovementSessionPort movement) {
  if (movement case final CitySessionPort cities) return cities;
  throw ArgumentError.value(
    movement,
    'movementSession',
    'must also provide the city session port',
  );
}

WorkerSessionPort _requireWorkerSession(MovementSessionPort movement) {
  if (movement case final WorkerSessionPort workers) return workers;
  throw ArgumentError.value(
    movement,
    'movementSession',
    'must also provide the worker session port',
  );
}

ProductionSessionPort _requireProductionSession(MovementSessionPort movement) {
  if (movement case final ProductionSessionPort production) return production;
  throw ArgumentError.value(
    movement,
    'movementSession',
    'must also provide the production session port',
  );
}

ArtifactSessionPort _requireArtifactSession(MovementSessionPort movement) {
  if (movement case final ArtifactSessionPort artifacts) return artifacts;
  throw ArgumentError.value(
    movement,
    'movementSession',
    'must also provide the artifact session port',
  );
}
