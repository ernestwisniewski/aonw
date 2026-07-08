part of 'technology_tree_dialog.dart';

class _TechnologyTreeModeBar extends StatelessWidget {
  const _TechnologyTreeModeBar({
    required this.mode,
    required this.compact,
    required this.technologyCount,
    required this.onShowTree,
    required this.onShowRecommendations,
  });

  final TechnologyTreeViewMode mode;
  final bool compact;
  final int technologyCount;
  final VoidCallback onShowTree;
  final VoidCallback onShowRecommendations;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showTree = mode == TechnologyTreeViewMode.tree;
    final title = showTree
        ? l10n.technologyFullTreeTitle
        : l10n.technologyRecommendationsTitle;
    final actionLabel = showTree
        ? l10n.technologyRecommendationsBackAction
        : technologyCount > 0
        ? l10n.technologyShowTreeCountAction(technologyCount)
        : l10n.technologyShowTreeAction;
    final actionIcon = showTree ? GameIcons.back : GameIcons.layers;
    final action = showTree ? onShowRecommendations : onShowTree;
    return Container(
      width: double.infinity,
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 8, 12, 8)
          : const EdgeInsets.fromLTRB(16, 9, 16, 9),
      decoration: SurfaceElevation.flat.bandDecoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 126,
        border: BorderEmphasis.subtle,
      ),
      child: Row(
        children: [
          GameIcon(
            showTree ? GameIcons.layers : GameIcons.science,
            size: GameIconSize.small,
            color: GameUiTheme.scienceAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              key: showTree
                  ? const Key('technologyTreeModeBar.title')
                  : const Key('technologyRecommendations.title'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: action,
            style: TextButton.styleFrom(
              foregroundColor: GameUiTheme.scienceAccent,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: GameIcon(
              actionIcon,
              size: GameIconSize.tiny,
              color: GameUiTheme.scienceAccent,
            ),
            label: Text(
              actionLabel,
              style: GameUiTheme.actionLabel.copyWith(
                color: GameUiTheme.scienceAccent,
                fontSize: compact ? 10 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
