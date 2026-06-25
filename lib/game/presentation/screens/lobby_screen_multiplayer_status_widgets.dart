part of 'lobby_screen.dart';

class _MultiplayerLobbyStatusCallout extends StatelessWidget {
  final bool waiting;
  final String text;

  const _MultiplayerLobbyStatusCallout({
    required this.waiting,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.gold.withAlpha(18),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(72)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(
              waiting
                  ? Icons.person_add_alt_1_outlined
                  : Icons.hourglass_top_rounded,
              size: 17,
              color: GameUiTheme.gold,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiplayerErrorText extends StatelessWidget {
  final String error;

  const _MultiplayerErrorText({required this.error});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.danger.withAlpha(24),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.danger.withAlpha(105)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          error,
          key: const Key('multiplayer.queueError'),
          style: GameUiTheme.bodySmall,
        ),
      ),
    );
  }
}
