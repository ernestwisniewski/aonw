part of 'game_screen.dart';

class _GameStartupLoadingOverlay extends ConsumerStatefulWidget {
  final String saveId;
  final bool multiplayer;
  final Future<void> preloadFuture;
  final ValueListenable<bool> rendererReady;
  final ValueListenable<bool> initialCameraFocusReady;
  final ValueListenable<GameLoadingProgress> loadingProgress;

  const _GameStartupLoadingOverlay({
    required this.saveId,
    required this.multiplayer,
    required this.preloadFuture,
    required this.rendererReady,
    required this.initialCameraFocusReady,
    required this.loadingProgress,
  });

  @override
  ConsumerState<_GameStartupLoadingOverlay> createState() =>
      _GameStartupLoadingOverlayState();
}

class _GameStartupLoadingOverlayState
    extends ConsumerState<_GameStartupLoadingOverlay> {
  String? _mapLoadedSentFor;

  @override
  void didUpdateWidget(_GameStartupLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.saveId != widget.saveId) {
      _mapLoadedSentFor = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameLoadingProgress>(
      valueListenable: widget.loadingProgress,
      builder: (context, progress, _) {
        return FutureBuilder<void>(
          future: widget.preloadFuture,
          builder: (context, snapshot) {
            final assetsReady =
                snapshot.connectionState == ConnectionState.done;
            return ValueListenableBuilder<bool>(
              valueListenable: widget.rendererReady,
              builder: (context, rendererReady, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: widget.initialCameraFocusReady,
                  builder: (context, cameraReady, _) {
                    final localReady =
                        assetsReady && rendererReady && cameraReady;
                    if (localReady) {
                      _notifyServerMapLoadedIfNeeded();
                    }
                    final waitingForNetwork = _waitingForNetworkStart();
                    if (localReady && !waitingForNetwork) {
                      return const SizedBox.shrink();
                    }
                    return GameLoadingPanel(
                      key: const Key('gameScreen.startupLoadingOverlay'),
                      progress: localReady ? progress.bumpedTo(0.98) : progress,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  bool _waitingForNetworkStart() {
    if (!widget.multiplayer || widget.saveId.isEmpty) return false;
    final session = ref.watch(networkSessionProvider);
    if (session == null ||
        !session.isConnected ||
        session.matchId != widget.saveId) {
      return false;
    }
    final match = ref.watch(
      multiplayerMatchProvider.select((matches) => matches[widget.saveId]),
    );
    return match == null || LobbyMatchStatusRules.isLoading(match);
  }

  void _notifyServerMapLoadedIfNeeded() {
    final session = ref.read(networkSessionProvider);
    final shouldNotify = ServerMapLoadedNotificationPolicy.shouldNotify(
      multiplayer: widget.multiplayer,
      saveId: widget.saveId,
      sentFor: _mapLoadedSentFor,
      sessionConnected: session?.isConnected ?? false,
      sessionMatchId: session?.matchId,
    );
    if (!shouldNotify || session == null) return;
    _mapLoadedSentFor = widget.saveId;
    unawaited(
      ref
          .read(networkSessionClientProvider)
          .markMapLoaded(token: session.token, matchId: widget.saveId)
          .then((match) {
            if (!mounted) return;
            ref.read(multiplayerMatchProvider.notifier).upsert(match);
          })
          .catchError((Object error, StackTrace stackTrace) {
            if (!mounted) return;
            if (_mapLoadedSentFor == widget.saveId) _mapLoadedSentFor = null;
            ref
                .read(networkSessionStateProvider.notifier)
                .reportTransportStatus(
                  saveId: widget.saveId,
                  status: NetworkConnectionStatus.reconnecting,
                  message: error.toString(),
                  changedAt: ref.read(gameClockProvider).nowUtc(),
                );
          }),
    );
  }
}
