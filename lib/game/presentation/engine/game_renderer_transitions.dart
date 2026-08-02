part of 'game_renderer.dart';

/// Serializes state transitions and transient renderer effects.
mixin GameRendererTransitions on HexWorld {
  GameRenderer get _transitionRenderer => this as GameRenderer;

  ValueListenable<Set<String>> get animatingUnitIdsListenable =>
      _transitionRenderer._unitAnimationController.animatingUnitIdsListenable;

  Future<void> applyTransition(
    GameClientState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) {
    final renderer = _transitionRenderer;
    return renderer._enqueueTransition(
      () => renderer._applyTransitionNow(
        state,
        effects,
        currentTurn: currentTurn,
      ),
    );
  }

  Future<void> handleEffects(Iterable<RendererEffect> effects) =>
      _transitionRenderer._enqueueTransition(
        () => _transitionRenderer._handleEffectsNow(effects),
      );

  Future<void> handleEffect(RendererEffect effect) => handleEffects([effect]);
}

extension _GameRendererTransitionInternals on GameRenderer {
  Future<void> _applyTransitionNow(
    GameClientState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) async {
    _ensureRendererActive();
    final pending = effects.toList(growable: false);
    final transitionControlsCamera = _transitionControlsCamera(pending);
    final animatedIds = <String>{
      for (final e in pending)
        if (e is AnimateUnitMoveEffect) e.unitId,
    };
    final combatAnimatedIds = <String>{
      for (final e in pending)
        if (e is PlayCombatAnimationEffect) ...[
          e.attackerUnitId,
          e.defenderUnitId,
        ],
    };
    final animationUnitIds = {...animatedIds, ...combatAnimatedIds};
    final combatAnimatedCityIds = <String>{
      for (final effect in pending.whereType<PlayCombatAnimationEffect>()) ...[
        if (_renderState.cityById(effect.attackerUnitId) != null ||
            state.cityById(effect.attackerUnitId) != null)
          effect.attackerUnitId,
        if (_renderState.cityById(effect.defenderUnitId) != null ||
            state.cityById(effect.defenderUnitId) != null)
          effect.defenderUnitId,
      ],
    };
    _unitMarkerLayer
      ..pinPendingMovePositions(animatedIds)
      ..retainPendingMoveMarkers(animatedIds)
      ..retainPendingAnimationMarkers(combatAnimatedIds);
    _cityMarkerLayer.retainPendingAnimationMarkers(combatAnimatedCityIds);
    var completed = false;
    try {
      _applyState(
        state,
        suppressCameraFocus: transitionControlsCamera,
        currentTurn: currentTurn,
      );
      await _handleEffectsNow(pending, waitForQueuedPlayback: true);
      completed = true;
    } finally {
      _unitAnimationController.finishUnitAnimationTransition(
        animationUnitIds,
        completed: completed,
        synchronizeAfterFailure: () =>
            _syncAfterAction(suppressCameraFocus: true),
      );
      _cityMarkerLayer.releasePendingAnimationMarkers(combatAnimatedCityIds);
      if (!_isDisposed && combatAnimatedCityIds.isNotEmpty) {
        _syncAfterAction(suppressCameraFocus: true);
      }
    }
  }

  Future<void> _handleEffectsNow(
    Iterable<RendererEffect> effects, {
    bool waitForQueuedPlayback = false,
  }) async {
    _ensureRendererActive();
    final pending = effects.toList();
    if (pending.isEmpty) return;
    if (!_isReady) {
      final batch = _queuedRendererEffects.enqueue(pending);
      if (waitForQueuedPlayback) {
        await batch.done;
      } else {
        batch.done.ignore();
      }
      return;
    }
    await _effectDispatcher.handleEffects(
      pending,
      beforeEffect: _ensureRendererActive,
    );
  }

  Future<void> _enqueueTransition(Future<void> Function() operation) {
    final next = _transitionQueue.then((_) {
      _ensureRendererActive();
      return operation();
    });
    _transitionQueue = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  void _ensureRendererActive() {
    if (_isDisposed) throw StateError('GameRenderer disposed');
  }
}
