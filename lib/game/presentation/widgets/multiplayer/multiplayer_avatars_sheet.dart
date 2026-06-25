part of 'multiplayer_avatars_rail.dart';

Future<void> _showPlayersSheet(
  BuildContext context, {
  required List<MultiplayerAvatarTileData> tiles,
  GameState? gameState,
  required ValueChanged<String> onAvatarTapped,
  Key? sheetRouteKey,
}) async {
  await showGameBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final sheet = Padding(
        padding: EdgeInsets.fromLTRB(
          10,
          0,
          10,
          10 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: GameModalScaffold(
          key: const Key('multiplayerAvatarsRail.sheet'),
          shape: GameModalShape.bottomSheet,
          centerInAvailableSpace: false,
          showCornerDiamonds: false,
          scrollable: true,
          contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          header: GameModalHeader(
            title: l10n.multiplayerPlayersTitle,
            onClose: () => unawaited(Navigator.of(sheetContext).maybePop()),
          ),
          content: MultiplayerStatusSheet(
            tiles: tiles,
            gameState: gameState,
            onAvatarTapped: (playerId) {
              unawaited(Navigator.of(sheetContext).maybePop());
              onAvatarTapped(playerId);
            },
          ),
        ),
      );
      if (sheetRouteKey == null) return sheet;
      return KeyedSubtree(key: sheetRouteKey, child: sheet);
    },
  );
}
