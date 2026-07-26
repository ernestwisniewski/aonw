part of 'game_renderer.dart';

extension GameRendererTransitionQueue on GameRenderer {
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
