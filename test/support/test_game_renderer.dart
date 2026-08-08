import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';

class TestGameRenderer extends GameRenderer {
  TestGameRenderer({
    required super.mapData,
    this.applyStateOnTransition = false,
  }) : super(initialViewMode: MapViewMode.tile, onCommand: (_) async {});

  final bool applyStateOnTransition;
  final handledEffects = <RendererEffect>[];
  final appliedStates = <GameClientState>[];

  @override
  Future<void> applyTransition(
    GameClientState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) async {
    appliedStates.add(state);
    if (applyStateOnTransition) applyState(state, currentTurn: currentTurn);
    handledEffects.addAll(effects);
  }

  @override
  Future<void> handleEffects(Iterable<RendererEffect> effects) async {
    handledEffects.addAll(effects);
  }

  void recordStateWithoutCameraFocus(
    GameClientState state, {
    int? currentTurn,
  }) {
    appliedStates.add(state);
    if (applyStateOnTransition) {
      applyStateWithoutCameraFocus(state, currentTurn: currentTurn);
    }
  }
}

final class TestRendererViewModel implements RendererViewModel {
  const TestRendererViewModel(this.renderer);

  final TestGameRenderer renderer;

  @override
  AppLocalizations? get l10n => renderer.l10n;

  @override
  CameraState get cameraState => CameraState.zero;

  @override
  Future<void> handleEffect(RendererEffect effect) =>
      renderer.handleEffects([effect]);

  @override
  Future<void> applyTransition(
    GameClientState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) => renderer.applyTransition(state, effects, currentTurn: currentTurn);

  @override
  void applyStateWithoutCameraFocus(GameClientState state, {int? currentTurn}) {
    renderer.recordStateWithoutCameraFocus(state, currentTurn: currentTurn);
  }
}
