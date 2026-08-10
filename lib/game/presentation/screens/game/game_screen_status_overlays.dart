part of 'game_screen.dart';

class _MultiplayerConnectionBanner extends ConsumerWidget {
  final String saveId;

  const _MultiplayerConnectionBanner({required this.saveId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(multiplayerConnectionStatusProvider);
    if (state == null || state.saveId != saveId) {
      return const SizedBox.shrink();
    }
    if (state.status == NetworkConnectionStatus.connected) {
      return const SizedBox.shrink();
    }

    final message = switch (state.status) {
      NetworkConnectionStatus.connecting =>
        'Connecting to multiplayer match...',
      NetworkConnectionStatus.reconnecting =>
        'Reconnecting to multiplayer match...',
      NetworkConnectionStatus.offline =>
        state.message == null || state.message!.isEmpty
            ? 'Multiplayer connection is offline.'
            : 'Multiplayer connection is offline. ${state.message}',
      NetworkConnectionStatus.connected => '',
    };

    return SafeArea(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GameUiTheme.bg.withAlpha(228),
              border: Border.all(color: GameUiTheme.gold.withAlpha(150)),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                message,
                key: const Key('gameScreen.multiplayerConnectionBanner'),
                textAlign: TextAlign.center,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameStateReadyGate extends ConsumerWidget {
  final MapSelection selection;
  final GameSession session;
  final Widget child;

  const _GameStateReadyGate({
    required this.selection,
    required this.session,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session.saveId.isEmpty) return child;

    return ref
        .watch(gameStateProvider(session.saveId))
        .when(
          loading: () => GameLoadingView(
            progress: GameLoadingProgress.initial.bumpedTo(0.46),
          ),
          error: (error, _) => GameLoadErrorView(
            mapName: selection.displayName,
            error: error,
            onBack: () => context.go('/new-game'),
          ),
          data: (_) => child,
        );
  }
}
