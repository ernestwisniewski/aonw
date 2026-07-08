part of 'wonder_details_dialog.dart';

class _WonderDetailsHeader extends StatelessWidget {
  const _WonderDetailsHeader({
    required this.wonderType,
    required this.title,
    required this.l10n,
    required this.onClose,
  });

  final WonderType wonderType;
  final String title;
  final AppLocalizations l10n;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
      decoration: SurfaceElevation.raised.bandDecoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 225,
        border: BorderEmphasis.regular,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: SurfaceElevation.flat.decoration(
              background: GameUiTheme.gold,
              backgroundAlpha: 24,
              border: BorderEmphasis.regular,
              borderRadius: BorderRadius.circular(6),
              includeShadow: false,
            ),
            child: Center(
              child: WonderSpriteIcon(
                type: wonderType,
                size: 50,
                fallback: const GameIcon(
                  GameIcons.victory,
                  size: GameIconSize.large,
                  color: GameUiTheme.goldLight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GameUiEpicHeader(
                  label: title,
                  alignment: Alignment.centerLeft,
                  compact: false,
                  textKey: const Key('wonderDetailsHeader.title'),
                ),
                const SizedBox(height: 2),
                Text(
                  GameText.uppercase(l10n.productionCategoryWonder),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: GameUiTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.closeAction,
            onPressed: onClose,
            icon: const GameIcon(
              GameIcons.close,
              size: GameIconSize.regular,
              color: GameUiTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _WonderDetailChip extends StatelessWidget {
  const _WonderDetailChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 120,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              GameText.uppercase(label),
              style: GameUiTheme.toolbarLabel.copyWith(
                color: GameUiTheme.textMuted,
                fontSize: 8.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WonderDetailsSection extends StatelessWidget {
  const _WonderDetailsSection({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            GameText.uppercase(title),
            style: GameUiTheme.toolbarLabel.copyWith(color: GameUiTheme.gold),
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '- $line',
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textPrimary,
                  height: 1.25,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
