part of 'technology_discovery_popup_overlay.dart';

class _TechnologyDiscoveryDialog extends StatefulWidget {
  final TechnologyId technologyId;
  final String playerName;

  const _TechnologyDiscoveryDialog({
    required this.technologyId,
    required this.playerName,
  });

  @override
  State<_TechnologyDiscoveryDialog> createState() =>
      _TechnologyDiscoveryDialogState();
}

class _TechnologyDiscoveryDialogState
    extends State<_TechnologyDiscoveryDialog> {
  bool _doNotShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final technologyName = GameDisplayNames.technology(
      l10n,
      widget.technologyId,
    );
    final description = GameDisplayNames.technologyDescription(
      l10n,
      widget.technologyId,
    );
    return GameModalScaffold(
      surfaceKey: const Key('technologyDiscoveryDialog.surface'),
      size: GameModalSize.regular,
      contentPadding: EdgeInsets.zero,
      scrollable: false,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TechnologyDiscoveryHeader(
              technologyId: widget.technologyId,
              technologyName: technologyName,
              playerName: widget.playerName,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Text(
                  description,
                  style: GameUiTheme.body.copyWith(
                    color: GameUiTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            _TechnologyDiscoveryFooter(
              doNotShowAgain: _doNotShowAgain,
              onToggleDoNotShowAgain: (value) =>
                  setState(() => _doNotShowAgain = value),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnologyDiscoveryHeader extends StatelessWidget {
  final TechnologyId technologyId;
  final String technologyName;
  final String playerName;

  const _TechnologyDiscoveryHeader({
    required this.technologyId,
    required this.technologyName,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TechnologyDiscoveryThumbnail(technologyId: technologyId),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.technologyDiscoveryEyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: GameUiTheme.gold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
                GameUiEpicHeader(
                  label: technologyName,
                  alignment: Alignment.centerLeft,
                  accent: GameUiTheme.scienceAccent,
                  compact: false,
                  textKey: const Key('technologyDiscoveryDialog.title'),
                ),
                const SizedBox(height: 4),
                Text(
                  playerName,
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
            key: const Key('technologyDiscoveryDialog.minimize'),
            onPressed: () => Navigator.of(
              context,
            ).pop(_TechnologyDiscoveryDialogResult.minimize),
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

class _TechnologyDiscoveryFooter extends StatelessWidget {
  final bool doNotShowAgain;
  final ValueChanged<bool> onToggleDoNotShowAgain;

  const _TechnologyDiscoveryFooter({
    required this.doNotShowAgain,
    required this.onToggleDoNotShowAgain,
  });

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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            InkWell(
              borderRadius: GameUiTheme.borderRadius,
              onTap: () => onToggleDoNotShowAgain(!doNotShowAgain),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      key: const Key(
                        'technologyDiscoveryDialog.doNotShowAgain.checkbox',
                      ),
                      value: doNotShowAgain,
                      onChanged: (value) =>
                          onToggleDoNotShowAgain(value ?? false),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      l10n.commonDoNotShowAgain,
                      style: GameUiTheme.bodySmall.copyWith(
                        color: GameUiTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                doNotShowAgain
                    ? _TechnologyDiscoveryDialogResult.disablePopup
                    : _TechnologyDiscoveryDialogResult.dismissed,
              ),
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
          ],
        ),
      ),
    );
  }
}

class _TechnologyDiscoveryThumbnail extends StatelessWidget {
  final TechnologyId technologyId;

  const _TechnologyDiscoveryThumbnail({required this.technologyId});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 185,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(8),
        includeShadow: false,
      ),
      child: SizedBox(
        width: 86,
        height: 86,
        child: Center(child: TechnologySpriteIcon(id: technologyId, size: 72)),
      ),
    );
  }
}
