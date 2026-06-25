part of 'diplomatic_message_popup_overlay.dart';

class _DiplomaticProposalDialog extends StatelessWidget {
  final String fromPlayerName;
  final Color fromPlayerColor;
  final String proposalLabel;

  const _DiplomaticProposalDialog({
    required this.fromPlayerName,
    required this.fromPlayerColor,
    required this.proposalLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GameModalScaffold(
      surfaceKey: const Key('diplomaticProposalDialog.surface'),
      size: GameModalSize.regular,
      contentPadding: EdgeInsets.zero,
      scrollable: false,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DiplomaticProposalHeader(
              fromPlayerName: fromPlayerName,
              fromPlayerColor: fromPlayerColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Text(
                proposalLabel,
                key: const Key('diplomaticProposalDialog.proposal'),
                style: GameUiTheme.body.copyWith(
                  color: GameUiTheme.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
            const _DiplomaticProposalFooter(),
          ],
        ),
      ),
    );
  }
}

class _DiplomaticProposalHeader extends StatelessWidget {
  final String fromPlayerName;
  final Color fromPlayerColor;

  const _DiplomaticProposalHeader({
    required this.fromPlayerName,
    required this.fromPlayerColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _DiplomaticMessageThumbnail(color: fromPlayerColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.commonDiplomacy,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: GameUiTheme.gold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
                GameUiEpicHeader(
                  label: l10n.diplomacyIncomingProposalTitle,
                  alignment: Alignment.centerLeft,
                  accent: fromPlayerColor,
                  compact: false,
                  textKey: const Key('diplomaticProposalDialog.title'),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.diplomacyIncomingProposalFrom(fromPlayerName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.cardMeta.copyWith(
                    color: GameUiTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('diplomaticProposalDialog.minimize'),
            onPressed: () => Navigator.of(
              context,
            ).pop(_DiplomaticProposalDialogResult.minimized),
            icon: const GameIcon(
              GameIcons.minus,
              size: 18,
              color: GameUiTheme.goldLight,
            ),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: l10n.selectionActionMinimize,
          ),
        ],
      ),
    );
  }
}

class _DiplomaticProposalFooter extends StatelessWidget {
  const _DiplomaticProposalFooter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: SurfaceElevation.flat.bandDecoration(
        background: GameUiTheme.surface,
        backgroundAlpha: 170,
        borderColor: GameUiTheme.copper,
        border: BorderEmphasis.regular,
        topBorder: true,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.end,
          children: [
            TextButton(
              key: const Key('diplomaticProposalDialog.later'),
              onPressed: () => Navigator.of(
                context,
              ).pop(_DiplomaticProposalDialogResult.later),
              child: Text(l10n.diplomacyIncomingMessageLater),
            ),
            FilledButton(
              key: const Key('diplomaticProposalDialog.decline'),
              onPressed: () => Navigator.of(
                context,
              ).pop(const _DiplomaticProposalDialogResult.respond(false)),
              style: FilledButton.styleFrom(
                backgroundColor: GameUiTheme.danger,
                foregroundColor: GameUiTheme.bg,
                textStyle: GameUiTheme.actionLabel,
                shape: RoundedRectangleBorder(
                  borderRadius: GameUiTheme.borderRadius,
                ),
              ),
              child: Text(l10n.diplomacyDecline),
            ),
            FilledButton(
              key: const Key('diplomaticProposalDialog.accept'),
              onPressed: () => Navigator.of(
                context,
              ).pop(const _DiplomaticProposalDialogResult.respond(true)),
              style: FilledButton.styleFrom(
                backgroundColor: GameUiTheme.gold,
                foregroundColor: GameUiTheme.bg,
                textStyle: GameUiTheme.actionLabel,
                shape: RoundedRectangleBorder(
                  borderRadius: GameUiTheme.borderRadius,
                ),
              ),
              child: Text(l10n.diplomacyAccept),
            ),
          ],
        ),
      ),
    );
  }
}
