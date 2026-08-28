import 'package:flutter/services.dart';

import '../../features/artifacts/application/artifact_session_port.dart';
import '../../features/cities/application/city_session_port.dart';
import '../../features/combat/application/combat_session_port.dart';
import '../../features/diplomacy/application/diplomacy_session_port.dart';
import '../../features/local_game/application/local_game_session_port.dart';
import '../../features/logistics/application/unit_logistics_session_port.dart';
import '../../features/map/application/map_session_port.dart';
import '../../features/map/application/movement_session_port.dart';
import '../../features/map/infrastructure/gamepad_map_input_source.dart';
import '../../features/map/infrastructure/rust_game_session_gateway.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../features/map/presentation/map_presentation_controller.dart';
import '../../features/production/application/production_session_port.dart';
import '../../features/replay/infrastructure/atomic_local_replay_store.dart';
import '../../features/replay/presentation/replay_presentation_controller.dart';
import '../../features/research/application/research_session_port.dart';
import '../../features/save_game/application/game_save_session_port.dart';
import '../../features/save_game/application/local_save_store.dart';
import '../../features/save_game/infrastructure/atomic_local_save_store.dart';
import '../../features/settings/application/client_settings_store.dart';
import '../../features/settings/infrastructure/shared_preferences_client_settings_store.dart';
import '../../features/settings/presentation/client_settings_controller.dart';
import '../../features/turns/application/turn_session_port.dart';
import '../../features/unit_actions/application/unit_action_session_port.dart';
import '../../features/workers/application/worker_session_port.dart';
import '../../game/aonw_flame_game.dart';
import '../navigation/aonw_app.dart';
import '../navigation/aonw_router.dart';
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
    ResearchSessionPort? researchSession,
    DiplomacySessionPort? diplomacySession,
    required UnitActionSessionPort unitActionSession,
    required TurnSessionPort turnSession,
    LocalGameSessionPort? localGameSession,
    GameSaveSessionPort? saveSession,
    LocalSaveStore? saveStore,
    ReplayPresentationController? replayController,
    MapInputSource? mapInputSource,
    ClientSettingsStore? settingsStore,
    AonwFlameGameFactory flameGameFactory = AonwFlameGame.new,
    ClientTelemetry telemetry = const NoOpClientTelemetry(),
    AonwRoute initialRoute = AonwRoute.menu,
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
           research:
               researchSession ?? _requireResearchSession(movementSession),
           diplomacy:
               diplomacySession ?? _requireDiplomacySession(movementSession),
           unitActions: unitActionSession,
           turns: turnSession,
           localGame: localGameSession,
           saveSession: saveSession,
           saveStore: saveStore,
           replayCapture: replayController,
         ),
         mapInputSource: mapInputSource,
         flameGameFactory: flameGameFactory,
         telemetry: telemetry,
         replayController: replayController,
         initialRoute: initialRoute,
         settingsController: settingsStore == null
             ? ClientSettingsController.ephemeral()
             : ClientSettingsController(store: settingsStore),
       );

  factory AppComposition.production({
    ClientTelemetry telemetry = const DebugClientTelemetry(),
  }) {
    final gateway = RustGameSessionGateway(assets: rootBundle);
    final replayController = ReplayPresentationController(
      session: gateway.replaySession,
      store: AtomicLocalReplayStore.production(),
    );
    return AppComposition(
      mapSession: gateway,
      movementSession: gateway,
      combatSession: gateway,
      citySession: gateway.citySession,
      logisticsSession: gateway,
      workerSession: gateway.workerSession,
      productionSession: gateway.productionSession,
      artifactSession: gateway.artifactSession,
      researchSession: gateway,
      diplomacySession: gateway,
      unitActionSession: gateway,
      turnSession: gateway,
      localGameSession: gateway,
      saveSession: gateway,
      saveStore: AtomicLocalSaveStore.production(),
      replayController: replayController,
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

ResearchSessionPort _requireResearchSession(MovementSessionPort movement) {
  if (movement case final ResearchSessionPort research) return research;
  throw ArgumentError.value(
    movement,
    'movementSession',
    'must also provide the research session port',
  );
}

DiplomacySessionPort _requireDiplomacySession(MovementSessionPort movement) {
  if (movement case final DiplomacySessionPort diplomacy) return diplomacy;
  throw ArgumentError.value(
    movement,
    'movementSession',
    'must also provide the diplomacy session port',
  );
}
