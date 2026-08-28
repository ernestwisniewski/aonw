import 'dart:async';

import 'package:flutter/foundation.dart';

import '../application/game_session_state.dart';
import '../application/map_coordinator.dart';
import '../application/map_session_port.dart';
import '../application/movement_session_port.dart';
import '../read_model/map_view.dart';

final class MapPresentationController extends ChangeNotifier {
  MapPresentationController({
    required MapSessionPort session,
    required MovementSessionPort movement,
    MapAssetPaths assets = MapAssetPaths.starter,
    MapDiagnosticReporter diagnosticReporter = _reportMapDiagnostic,
  }) : this.fromCoordinator(
         MapCoordinator(
           session: session,
           movement: movement,
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
