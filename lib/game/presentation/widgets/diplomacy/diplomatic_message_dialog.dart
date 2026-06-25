part of 'diplomatic_message_popup_overlay.dart';

class _DiplomaticMessageDialog extends StatelessWidget {
  final String fromPlayerName;
  final Color fromPlayerColor;
  final String topicLabel;

  const _DiplomaticMessageDialog({
    required this.fromPlayerName,
    required this.fromPlayerColor,
    required this.topicLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GameModalScaffold(
      surfaceKey: const Key('diplomaticMessageDialog.surface'),
      size: GameModalSize.regular,
      contentPadding: EdgeInsets.zero,
      scrollable: false,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DiplomaticMessageHeader(
              fromPlayerName: fromPlayerName,
              fromPlayerColor: fromPlayerColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Text(
                topicLabel,
                key: const Key('diplomaticMessageDialog.topic'),
                style: GameUiTheme.body.copyWith(
                  color: GameUiTheme.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
            const _DiplomaticMessageFooter(),
          ],
        ),
      ),
    );
  }
}

class _DiplomaticMessageHeader extends StatelessWidget {
  final String fromPlayerName;
  final Color fromPlayerColor;

  const _DiplomaticMessageHeader({
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
                  label: l10n.diplomacyIncomingMessageTitle,
                  alignment: Alignment.centerLeft,
                  accent: fromPlayerColor,
                  compact: false,
                  textKey: const Key('diplomaticMessageDialog.title'),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.diplomacyIncomingMessageFrom(fromPlayerName),
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
            key: const Key('diplomaticMessageDialog.minimize'),
            onPressed: () => Navigator.of(
              context,
            ).pop(_DiplomaticMessageDialogResult.minimized),
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

class _DiplomaticMessageThumbnail extends StatelessWidget {
  final Color color;

  const _DiplomaticMessageThumbnail({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 185,
        accent: color,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(8),
        includeShadow: false,
      ),
      child: SizedBox(
        width: 86,
        height: 86,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: ShapeDecoration(
                  color: SurfaceElevation.flat.fill(
                    background: color,
                    alpha: 52,
                  ),
                  shape: const CircleBorder(),
                ),
              ),
              GameIcon(GameIcons.diplomacy, size: 46, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiplomaticMessageFooter extends StatelessWidget {
  const _DiplomaticMessageFooter();

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
              key: const Key('diplomaticMessageDialog.later'),
              onPressed: () => Navigator.of(
                context,
              ).pop(_DiplomaticMessageDialogResult.later),
              child: Text(l10n.diplomacyIncomingMessageLater),
            ),
            for (final response in DiplomaticMessageResponse.values)
              FilledButton(
                key: Key('diplomaticMessageDialog.response.${response.name}'),
                onPressed: () => Navigator.of(
                  context,
                ).pop(_DiplomaticMessageDialogResult.respond(response)),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      response == DiplomaticMessageResponse.aggressive
                      ? GameUiTheme.danger
                      : GameUiTheme.gold,
                  foregroundColor: GameUiTheme.bg,
                  textStyle: GameUiTheme.actionLabel,
                  shape: RoundedRectangleBorder(
                    borderRadius: GameUiTheme.borderRadius,
                  ),
                ),
                child: Text(_responseLabel(l10n, response)),
              ),
          ],
        ),
      ),
    );
  }
}

DiplomaticMessageTopic? _topicFromName(String? name) {
  if (name == null) return null;
  for (final topic in DiplomaticMessageTopic.values) {
    if (topic.name == name) return topic;
  }
  return null;
}

DiplomaticProposalKind? _proposalKindFromName(String? name) {
  if (name == null) return null;
  for (final kind in DiplomaticProposalKind.values) {
    if (kind.name == name) return kind;
  }
  return null;
}

String _proposalKindLabel(AppLocalizations l10n, DiplomaticProposalKind kind) {
  return switch (kind) {
    DiplomaticProposalKind.friendship => l10n.diplomacyProposalFriendship,
    DiplomaticProposalKind.truce => l10n.diplomacyProposalTruce,
  };
}

String _topicLabel(AppLocalizations l10n, DiplomaticMessageTopic topic) {
  return switch (topic) {
    DiplomaticMessageTopic.troopsNearCities =>
      l10n.diplomacyMessageTroopsNearCities,
    DiplomaticMessageTopic.citiesTooClose =>
      l10n.diplomacyMessageCitiesTooClose,
    DiplomaticMessageTopic.blockedRoutes => l10n.diplomacyMessageBlockedRoutes,
    DiplomaticMessageTopic.withdrawScouts =>
      l10n.diplomacyMessageWithdrawScouts,
    DiplomaticMessageTopic.avoidEscalation =>
      l10n.diplomacyMessageAvoidEscalation,
    DiplomaticMessageTopic.commonEnemy => l10n.diplomacyMessageCommonEnemy,
    DiplomaticMessageTopic.expansionProvocation =>
      l10n.diplomacyMessageExpansionProvocation,
    DiplomaticMessageTopic.peacefulPraise =>
      l10n.diplomacyMessagePeacefulPraise,
  };
}

String _responseLabel(
  AppLocalizations l10n,
  DiplomaticMessageResponse response,
) {
  return switch (response) {
    DiplomaticMessageResponse.conciliatory =>
      l10n.diplomacyResponseConciliatory,
    DiplomaticMessageResponse.neutral => l10n.diplomacyResponseNeutral,
    DiplomaticMessageResponse.evasive => l10n.diplomacyResponseEvasive,
    DiplomaticMessageResponse.aggressive => l10n.diplomacyResponseAggressive,
  };
}

String _playerName(AppLocalizations l10n, GameSave? save, String playerId) {
  final player = _playerById(save, playerId);
  return player == null ? playerId : GameDisplayNames.player(l10n, player);
}

Player? _playerById(GameSave? save, String playerId) {
  if (save == null) return null;
  for (final player in save.players) {
    if (player.id == playerId) return player;
  }
  return null;
}
