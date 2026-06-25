part of 'empire_overview_entity_groups.dart';

class _GroupShell extends StatelessWidget {
  const _GroupShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.focusTooltip,
    required this.onTap,
    required this.children,
  });

  final GameIconData icon;
  final String title;
  final String subtitle;
  final String focusTooltip;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 132,
        border: BorderEmphasis.subtle,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EmpireGroupHeader(
              icon: icon,
              title: title,
              subtitle: subtitle,
              focusTooltip: focusTooltip,
              onTap: onTap,
            ),
            if (children.isNotEmpty)
              DecoratedBox(
                decoration: SurfaceElevation.flat.bandDecoration(
                  background: GameUiTheme.surface,
                  backgroundAlpha: 188,
                  border: BorderEmphasis.subtle,
                  topBorder: true,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: SurfaceElevation.flat.strokeColor(alpha: 62),
                        ),
                      children[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmpireGroupHeader extends StatelessWidget {
  const _EmpireGroupHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.focusTooltip,
    required this.onTap,
  });

  final GameIconData icon;
  final String title;
  final String subtitle;
  final String focusTooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SurfaceElevation.flat.fill(
        background: GameUiTheme.gold,
        alpha: 18,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: SurfaceElevation.flat.decoration(
                  background: GameUiTheme.gold,
                  backgroundAlpha: 28,
                  border: BorderEmphasis.subtle,
                  borderRadius: BorderRadius.circular(5),
                  includeShadow: false,
                ),
                child: Center(
                  child: GameIcon(
                    icon,
                    size: GameIconSize.regular,
                    color: GameUiTheme.gold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GameUiTheme.goldLight,
                        fontFamily: GameUiTheme.headingFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GameUiTheme.textSecondary,
                        fontFamily: GameUiTheme.bodyFont,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: focusTooltip,
                child: const GameIcon(
                  GameIcons.focus,
                  color: GameUiTheme.gold,
                  size: GameIconSize.small,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmpireEntityRow extends StatelessWidget {
  const _EmpireEntityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.focusTooltip,
    required this.onTap,
    this.badgeIcon,
    this.badgeTooltip,
    super.key,
  });

  final GameIconData icon;
  final String title;
  final String subtitle;
  final String focusTooltip;
  final VoidCallback onTap;
  final GameIconData? badgeIcon;
  final String? badgeTooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: SurfaceElevation.flat.decoration(
                  accent: GameUiTheme.textSecondary,
                  background: GameUiTheme.textSecondary,
                  backgroundAlpha: 18,
                  borderAlpha: 42,
                  borderRadius: BorderRadius.circular(5),
                  includeShadow: false,
                ),
                child: Center(
                  child: GameIcon(
                    icon,
                    size: GameIconSize.small,
                    color: GameUiTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GameUiTheme.textBright,
                        fontFamily: GameUiTheme.bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: badgeIcon == null ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GameUiTheme.textSecondary,
                        fontFamily: GameUiTheme.bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (badgeIcon != null) ...[
                Tooltip(
                  message: badgeTooltip ?? '',
                  child: GameIcon(
                    badgeIcon!,
                    color: GameUiTheme.gold,
                    size: GameIconSize.small,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Tooltip(
                message: focusTooltip,
                child: const GameIcon(
                  GameIcons.focus,
                  color: GameUiTheme.gold,
                  size: GameIconSize.small,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
