part of 'diplomatic_message_popup_overlay.dart';

class _DiplomaticEventDialog extends StatelessWidget {
  final GameEventNotificationMessage message;
  final Color accent;

  const _DiplomaticEventDialog({required this.message, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameModalScaffold(
      surfaceKey: const Key('diplomaticEventDialog.surface'),
      size: GameModalSize.regular,
      contentPadding: EdgeInsets.zero,
      scrollable: false,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _DiplomaticMessageThumbnail(color: accent),
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
                          label: message.title,
                          alignment: Alignment.centerLeft,
                          accent: accent,
                          compact: false,
                          textKey: const Key('diplomaticEventDialog.title'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Text(
                message.body,
                key: const Key('diplomaticEventDialog.body'),
                style: GameUiTheme.body.copyWith(
                  color: GameUiTheme.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
            if (message.details.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final detail in message.details.take(4))
                      DecoratedBox(
                        decoration: SurfaceElevation.flat.decoration(
                          background: GameUiTheme.chipSurface,
                          backgroundAlpha: 210,
                          border: BorderEmphasis.subtle,
                          shape: SurfaceShape.chip,
                          includeShadow: false,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GameUiTheme.chipLabel.copyWith(
                              color: GameUiTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            DecoratedBox(
              decoration: SurfaceElevation.flat.bandDecoration(
                background: GameUiTheme.surface,
                backgroundAlpha: 170,
                borderColor: GameUiTheme.copper,
                border: BorderEmphasis.regular,
                topBorder: true,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const Key('diplomaticEventDialog.ok'),
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: GameUiTheme.gold,
                      foregroundColor: GameUiTheme.bg,
                      textStyle: GameUiTheme.actionLabel,
                      shape: RoundedRectangleBorder(
                        borderRadius: GameUiTheme.borderRadius,
                      ),
                    ),
                    child: Text(l10n.commonOk),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
