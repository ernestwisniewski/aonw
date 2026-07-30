part of 'game_state_provider.dart';

Duration? _doNotRetry(int retryCount, Object error) => null;

const _liveSnapshotRetryDelays = [
  Duration(milliseconds: 150),
  Duration(milliseconds: 350),
  Duration(milliseconds: 750),
];

LiveServerEvent? _presentedLiveEvent(
  LiveSnapshotPresentationDecision presentation,
  LiveServerEvent? event,
) => presentation.canPresentLiveTransition ? event : null;

String _multiplayerCacheKey(String userId, String saveId) {
  return multiplayerSnapshotCacheKey(userId: userId, matchId: saveId);
}

void _warnGameState(
  Ref ref,
  String message,
  Object? error,
  StackTrace? stackTrace,
) {
  ref
      .read(gameLoggerProvider)
      .warn('GameStateNotifier', message, error, stackTrace);
}

extension GameStateNotifierTurnLifecycle on GameStateNotifier {
  Future<T> _enqueueDispatch<T>(Future<T> Function() operation) {
    final next = _dispatchQueue.then((_) => operation());
    _dispatchQueue = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  Future<List<UiEffect>> dispatch(
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    final result = await dispatchTransition(command, context: context);
    return result.uiEffects;
  }

  /// Use when the caller must coordinate the new state with renderer effects.
  Future<DispatchCommandResult> dispatchTransition(
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return _enqueueDispatch(
      () => _dispatchTransitionNow(command, context: context),
    );
  }

  FutureOr<LiveEventSubscriptionHandle?> _liveCommandHandle() {
    return _liveEvents ?? _liveEventsStarting;
  }

  void _queueNetworkSnapshotApply({
    required String saveId,
    required SaveSnapshot snapshot,
    LiveServerEvent? liveEvent,
  }) {
    _networkSnapshotQueue = _networkSnapshotQueue.then(
      (_) => _applyNetworkSnapshot(
        saveId: saveId,
        snapshot: snapshot,
        liveEvent: liveEvent,
      ),
      onError: (Object error, StackTrace stackTrace) {
        _warn('Previous network snapshot apply failed', error, stackTrace);
        return _applyNetworkSnapshot(
          saveId: saveId,
          snapshot: snapshot,
          liveEvent: liveEvent,
        );
      },
    );
  }

  Future<void> _closeLiveEvents() async {
    final liveEvents = _liveEvents;
    _liveEvents = null;
    _liveEventsStarting = null;
    await liveEvents?.close();
  }
}
