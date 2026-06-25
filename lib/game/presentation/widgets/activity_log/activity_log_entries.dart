part of 'activity_log_dialog.dart';

class _ActivityLogEmptyState extends StatelessWidget {
  final ActivityLogFilter filter;
  final bool compact;
  final VoidCallback? onShowAll;

  const _ActivityLogEmptyState({
    required this.filter,
    required this.compact,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HudPanelEmptyState(
      icon: filter.emptyIcon,
      title: filter.emptyLabel(l10n),
      body: filter.emptyBody(l10n),
      actionLabel: onShowAll == null ? null : l10n.activityLogShowAllAction,
      onAction: onShowAll,
      accent: filter.emptyAccent,
      compact: compact,
    );
  }
}

class _ActivityLogEntryTile extends StatelessWidget {
  const _ActivityLogEntryTile({
    required this.message,
    required this.compact,
    this.onTap,
  });

  final GameEventNotificationMessage message;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visibleDetails = compact
        ? message.details.take(2).toList(growable: false)
        : message.details;

    return Material(
      color: Colors.transparent,
      borderRadius: GameUiTheme.borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: GameUiTheme.borderRadius,
        child: Container(
          width: double.infinity,
          padding: compact
              ? const EdgeInsets.fromLTRB(8, 7, 8, 8)
              : const EdgeInsets.fromLTRB(10, 9, 10, 10),
          decoration: SurfaceElevation.flat.decoration(
            background: GameUiTheme.card,
            backgroundAlpha: 220,
            border: BorderEmphasis.subtle,
            borderRadius: GameUiTheme.borderRadius,
            includeShadow: false,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.thumbnail != null) ...[
                GameEventNotificationThumbnailView(
                  thumbnail: message.thumbnail!,
                  frameSize: compact ? 34 : 40,
                  iconSize: compact ? 28 : 32,
                  unitIconSize: compact ? 30 : 34,
                ),
                SizedBox(width: compact ? 8 : 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.sectionHeader.copyWith(
                        color: GameUiTheme.goldLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.body,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.bodySmall.copyWith(
                        color: GameUiTheme.textPrimary,
                      ),
                    ),
                    if (visibleDetails.isNotEmpty) ...[
                      SizedBox(height: compact ? 6 : 8),
                      Wrap(
                        spacing: compact ? 5 : 6,
                        runSpacing: compact ? 4 : 6,
                        children: [
                          for (final detail in visibleDetails)
                            _ActivityDetailPill(detail, compact: compact),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityLogShowMoreButton extends StatelessWidget {
  const _ActivityLogShowMoreButton({
    required this.compact,
    required this.visible,
    required this.total,
    required this.onPressed,
  });

  final bool compact;
  final int visible;
  final int total;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: OutlinedButton.icon(
        key: const Key('activityLog.showMore'),
        onPressed: onPressed,
        icon: const GameIcon(
          GameIcons.chevronDown,
          size: 16,
          color: GameUiTheme.goldLight,
        ),
        label: Text(l10n.activityLogShowMoreAction(visible, total)),
        style: GameUiTheme.outlinedButtonStyle(
          foreground: GameUiTheme.goldLight,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}

class _ActivityLogHistoryLoadingState extends StatelessWidget {
  const _ActivityLogHistoryLoadingState({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 12 : 18),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: GameUiTheme.textSecondary,
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            Text(
              l10n.activityLogLoadingHistory,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityLogHistoryErrorState extends StatelessWidget {
  const _ActivityLogHistoryErrorState({
    required this.error,
    required this.compact,
    required this.onRetry,
  });

  final Object error;
  final bool compact;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HudPanelEmptyState(
      icon: GameIcons.error,
      title: l10n.activityLogHistoryErrorTitle,
      body: l10n.activityLogHistoryErrorBody(error.toString()),
      actionLabel: l10n.retryAction,
      onAction: onRetry,
      accent: GameUiTheme.danger,
      compact: compact,
    );
  }
}

class _ActivityDetailPill extends StatelessWidget {
  const _ActivityDetailPill(this.text, {required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 210,
        border: BorderEmphasis.subtle,
        shape: SurfaceShape.chip,
        includeShadow: false,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 4 : 5,
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.chipLabel.copyWith(
            color: GameUiTheme.textPrimary,
            fontSize: compact ? 10 : null,
          ),
        ),
      ),
    );
  }
}
