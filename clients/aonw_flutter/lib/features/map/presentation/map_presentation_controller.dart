import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../artifacts/application/artifact_session_port.dart';
import '../../artifacts/read_model/artifact_view.dart';
import '../../cities/application/city_session_port.dart';
import '../../cities/read_model/city_view.dart';
import '../../combat/application/combat_session_port.dart';
import '../../combat/read_model/combat_view.dart';
import '../../diplomacy/application/diplomacy_session_port.dart';
import '../../diplomacy/read_model/diplomacy_view.dart';
import '../../local_game/application/local_game_catalog.dart';
import '../../local_game/application/local_game_session_port.dart';
import '../../logistics/application/unit_logistics_session_port.dart';
import '../../logistics/read_model/unit_logistics_view.dart';
import '../../production/application/production_session_port.dart';
import '../../production/read_model/production_view.dart';
import '../../replay/application/replay_capture.dart';
import '../../research/application/research_session_port.dart';
import '../../research/read_model/research_view.dart';
import '../../save_game/application/game_save_session_port.dart';
import '../../save_game/application/local_save_state.dart';
import '../../save_game/application/local_save_store.dart';
import '../../turns/application/turn_session_port.dart';
import '../../unit_actions/application/unit_action_session_port.dart';
import '../../unit_actions/read_model/unit_action_view.dart';
import '../../workers/application/worker_session_port.dart';
import '../../workers/read_model/worker_view.dart';
import '../application/game_session_state.dart';
import '../application/map_coordinator.dart';
import '../application/map_session_port.dart';
import '../application/movement_session_port.dart';
import '../read_model/map_view.dart';

final class MapPresentationController extends ChangeNotifier {
  MapPresentationController({
    required MapSessionPort session,
    required MovementSessionPort movement,
    CombatSessionPort? combat,
    CitySessionPort? cities,
    required UnitLogisticsSessionPort logistics,
    WorkerSessionPort? workers,
    ProductionSessionPort? production,
    ArtifactSessionPort? artifacts,
    ResearchSessionPort? research,
    DiplomacySessionPort? diplomacy,
    required UnitActionSessionPort unitActions,
    required TurnSessionPort turns,
    LocalGameSessionPort? localGame,
    GameSaveSessionPort? saveSession,
    LocalSaveStore? saveStore,
    ReplayCapture? replayCapture,
    MapAssetPaths assets = MapAssetPaths.starter,
    MapDiagnosticReporter diagnosticReporter = _reportMapDiagnostic,
  }) : this.fromCoordinator(
         MapCoordinator(
           session: session,
           movement: movement,
           combat: combat,
           cities: cities,
           logistics: logistics,
           workers: workers,
           production: production,
           artifacts: artifacts,
           research: research,
           diplomacy: diplomacy,
           unitActions: unitActions,
           turns: turns,
           localGame: localGame,
           saveSession: saveSession,
           saveStore: saveStore,
           replayCapture: replayCapture,
           assets: assets,
           diagnosticReporter: diagnosticReporter,
         ),
       );

  MapPresentationController.fromCoordinator(this._coordinator) {
    _subscription = _coordinator.changes.listen((_) => notifyListeners());
  }

  final MapCoordinator _coordinator;
  late final StreamSubscription<GameSessionState> _subscription;
  var _disposed = false;

  GameSessionState get state => _coordinator.state;

  Future<void> load() => _coordinator.load();

  Future<bool> startLocalMatch(
    LocalGameCatalogEntryView entry,
    LocalMatchSetupView setup,
  ) => _coordinator.startLocalMatch(entry, setup);

  Future<bool> hasLocalSave() => _coordinator.hasLocalSave();

  Future<LocalResumeResultView> resumeLatestLocalGame() =>
      _coordinator.resumeLatestLocalGame();

  void saveLocalGame() => _coordinator.saveLocalGame();

  void hover(MapHexCoordinate? coordinate) => _coordinator.hover(coordinate);

  void select(MapHexCoordinate? coordinate) => _coordinator.select(coordinate);

  void confirmMove() => _coordinator.confirmMove();

  void executeUnitAction(UnitActionKindView action) =>
      _coordinator.executeUnitAction(action);

  void executeUnitLogistics(UnitLogisticsActionView action) =>
      _coordinator.executeUnitLogistics(action);

  void executeWorkerAction(WorkerActionView action) =>
      _coordinator.executeWorkerAction(action);

  void executeProductionAction(ProductionActionView action) =>
      _coordinator.executeProductionAction(action);

  void executeArtifactAction(ArtifactActionView action) =>
      _coordinator.executeArtifactAction(action);

  void selectTechnology(TechnologyIdView technology) =>
      _coordinator.selectTechnology(technology);

  void refreshResearch() => _coordinator.refreshResearch();

  void executeDiplomacyAction(DiplomacyActionView action) =>
      _coordinator.executeDiplomacyAction(action);

  void confirmCombat() => _coordinator.confirmCombat();

  void setCityConquestAction(CityConquestActionView action) =>
      _coordinator.setCityConquestAction(action);

  void inspectSelectedCity(String cityId) =>
      _coordinator.inspectSelectedCity(cityId);

  void openCityFounding() => _coordinator.openCityFounding();

  void toggleCityFoundingHex(MapHexCoordinate coordinate) =>
      _coordinator.toggleCityFoundingHex(coordinate);

  void confirmCityFounding() => _coordinator.confirmCityFounding();

  void executeCityAction(CityActionView action) =>
      _coordinator.executeCityAction(action);

  void endTurn() => _coordinator.endTurn();

  void toggleReference() => _coordinator.toggleReference();

  void completeTurnPresentation() => _coordinator.completeTurnPresentation();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription.cancel());
    _coordinator.dispose();
    super.dispose();
  }
}

void _reportMapDiagnostic(String code, Object error, StackTrace stackTrace) {
  debugPrintStack(
    label: 'Map diagnostic [$code]: $error',
    stackTrace: stackTrace,
  );
}
