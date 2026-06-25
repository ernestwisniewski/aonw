part of 'technology_tree_node.dart';

class _TechnologyHelpButton extends StatelessWidget {
  const _TechnologyHelpButton({required this.l10n, required this.onPressed});

  final AppLocalizations l10n;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: l10n.technologyDetailsTooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 16,
        child: Container(
          width: 22,
          height: 22,
          decoration: SurfaceElevation.flat.decoration(
            background: Colors.white,
            backgroundAlpha: 14,
            border: BorderEmphasis.regular,
            borderRadius: BorderRadius.circular(11),
            includeShadow: false,
          ),
          child: const Center(
            child: GameIcon(
              GameIcons.info,
              size: GameIconSize.small,
              color: GameUiTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TechnologyNodeColors {
  const _TechnologyNodeColors({
    required this.background,
    required this.border,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.action,
  });

  final Color background;
  final Color border;
  final Color title;
  final Color subtitle;
  final Color progress;
  final Color action;

  static _TechnologyNodeColors forState(TechnologyCardState state) {
    return switch (state) {
      TechnologyCardState.researched => const _TechnologyNodeColors(
        background: GameUiTheme.successSubtle,
        border: GameUiTheme.success,
        title: GameUiTheme.success,
        subtitle: GameUiTheme.success,
        progress: GameUiTheme.success,
        action: GameUiTheme.successDim,
      ),
      TechnologyCardState.active => const _TechnologyNodeColors(
        background: Color(0xFF142B31),
        border: GameUiTheme.scienceAccent,
        title: Color(0xFFAEE6DF),
        subtitle: GameUiTheme.scienceAccent,
        progress: GameUiTheme.scienceAccent,
        action: GameUiTheme.info,
      ),
      TechnologyCardState.available => const _TechnologyNodeColors(
        background: Color(0xFF1D2630),
        border: Color(0xFF788EA7),
        title: Color(0xFFEEF5FF),
        subtitle: Color(0xFFAAB9CA),
        progress: GameUiTheme.info,
        action: GameUiTheme.info,
      ),
      TechnologyCardState.locked => const _TechnologyNodeColors(
        background: Color(0xFF1A1D22),
        border: Color(0xFF3B424C),
        title: Color(0xFF87909B),
        subtitle: Color(0xFF7B838D),
        progress: Color(0xFF4D5662),
        action: Color(0xFF3B424C),
      ),
    };
  }
}
