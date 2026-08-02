import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/unit_animation_controller.dart';

typedef RendererStateApplier =
    void Function(
      GameClientState state, {
      required bool suppressCameraFocus,
      int? currentTurn,
    });

/// Serializes complete renderer transitions and owns their cleanup policy.
final class GameRendererTransitionHandler {
  GameRendererTransitionHandler({
    required void Function() ensureActive,
    required GameClientState Function() renderState,
    required bool Function() isDisposed,
    required bool Function(List<RendererEffect>) transitionControlsCamera,
    required RendererStateApplier applyState,
    required Future<void> Function(
      Iterable<RendererEffect> effects, {
      bool waitForQueuedPlayback,
    })
    handleEffectsNow,
    required UnitMarkerLayer Function() unitMarkers,
    required CityMarkerLayer Function() cityMarkers,
    required UnitAnimationController Function() unitAnimations,
    required void Function({bool suppressCameraFocus}) synchronize,
  }) : _ensureActive = ensureActive,
       _renderState = renderState,
       _isDisposed = isDisposed,
       _transitionControlsCamera = transitionControlsCamera,
       _applyState = applyState,
       _handleEffectsNow = handleEffectsNow,
       _unitMarkers = unitMarkers,
       _cityMarkers = cityMarkers,
       _unitAnimations = unitAnimations,
       _synchronize = synchronize;

  final void Function() _ensureActive;
  final GameClientState Function() _renderState;
  final bool Function() _isDisposed;
  final bool Function(List<RendererEffect>) _transitionControlsCamera;
  final RendererStateApplier _applyState;
  final Future<void> Function(
    Iterable<RendererEffect> effects, {
    bool waitForQueuedPlayback,
  })
  _handleEffectsNow;
  final UnitMarkerLayer Function() _unitMarkers;
  final CityMarkerLayer Function() _cityMarkers;
  final UnitAnimationController Function() _unitAnimations;
  final void Function({bool suppressCameraFocus}) _synchronize;
  Future<void> _queue = Future<void>.value();

  Future<void> enqueue(Future<void> Function() operation) {
    final next = _queue.then((_) {
      _ensureActive();
      return operation();
    });
    _queue = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  Future<void> applyNow(
    GameClientState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) async {
    _ensureActive();
    final pending = effects.toList(growable: false);
    final animatedIds = _animatedUnitIds(pending);
    final combatAnimatedIds = _combatUnitIds(pending);
    final animationUnitIds = {...animatedIds, ...combatAnimatedIds};
    final combatCityIds = _combatCityIds(pending, state);
    _unitMarkers()
      ..pinPendingMovePositions(animatedIds)
      ..retainPendingMoveMarkers(animatedIds)
      ..retainPendingAnimationMarkers(combatAnimatedIds);
    _cityMarkers().retainPendingAnimationMarkers(combatCityIds);
    var completed = false;
    try {
      _applyState(
        state,
        suppressCameraFocus: _transitionControlsCamera(pending),
        currentTurn: currentTurn,
      );
      await _handleEffectsNow(pending, waitForQueuedPlayback: true);
      completed = true;
    } finally {
      _unitAnimations().finishUnitAnimationTransition(
        animationUnitIds,
        completed: completed,
        synchronizeAfterFailure: () => _synchronize(suppressCameraFocus: true),
      );
      _cityMarkers().releasePendingAnimationMarkers(combatCityIds);
      if (!_isDisposed() && combatCityIds.isNotEmpty) {
        _synchronize(suppressCameraFocus: true);
      }
    }
  }

  Set<String> _combatCityIds(
    List<RendererEffect> effects,
    GameClientState state,
  ) {
    return {
      for (final effect in effects.whereType<PlayCombatAnimationEffect>()) ...[
        if (_renderState().cityById(effect.attackerUnitId) != null ||
            state.cityById(effect.attackerUnitId) != null)
          effect.attackerUnitId,
        if (_renderState().cityById(effect.defenderUnitId) != null ||
            state.cityById(effect.defenderUnitId) != null)
          effect.defenderUnitId,
      ],
    };
  }
}

Set<String> _animatedUnitIds(Iterable<RendererEffect> effects) => {
  for (final effect in effects)
    if (effect is AnimateUnitMoveEffect) effect.unitId,
};

Set<String> _combatUnitIds(Iterable<RendererEffect> effects) => {
  for (final effect in effects)
    if (effect is PlayCombatAnimationEffect) ...[
      effect.attackerUnitId,
      effect.defenderUnitId,
    ],
};
