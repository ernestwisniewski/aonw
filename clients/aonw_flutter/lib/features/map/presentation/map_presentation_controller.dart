import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../logistics/application/unit_logistics_session_port.dart';
import '../../logistics/read_model/unit_logistics_view.dart';
import '../../turns/application/turn_session_port.dart';
import '../../unit_actions/application/unit_action_session_port.dart';
import '../../unit_actions/read_model/unit_action_view.dart';
import '../application/game_session_state.dart';
import '../application/map_coordinator.dart';
import '../application/map_session_port.dart';
import '../application/movement_session_port.dart';
import '../read_model/map_view.dart';

final class MapPresentationController extends ChangeNotifier {
  MapPresentationController({
    required MapSessionPort session,
    required MovementSessionPort movement,
    required UnitLogisticsSessionPort logistics,
    required UnitActionSessionPort unitActions,
    required TurnSessionPort turns,
    MapAssetPaths assets = MapAssetPaths.starter,
    MapDiagnosticReporter diagnosticReporter = _reportMapDiagnostic,
  }) : this.fromCoordinator(
         MapCoordinator(
           session: session,
           movement: movement,
           logistics: logistics,
           unitActions: unitActions,
           turns: turns,
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

  void hover(MapHexCoordinate? coordinate) => _coordinator.hover(coordinate);

  void select(MapHexCoordinate? coordinate) => _coordinator.select(coordinate);

  void confirmMove() => _coordinator.confirmMove();

  void executeUnitAction(UnitActionKindView action) =>
      _coordinator.executeUnitAction(action);

  void executeUnitLogistics(UnitLogisticsActionView action) =>
      _coordinator.executeUnitLogistics(action);

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
