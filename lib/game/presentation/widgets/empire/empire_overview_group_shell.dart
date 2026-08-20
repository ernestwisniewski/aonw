part of 'empire_overview_entity_groups.dart';

class _GroupShell extends StatelessWidget {
  const _GroupShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.focusTooltip,
    required this.onTap,
    required this.children,
    this.leading,
    this.useTileLayout = false,
  });

  final GameIconData icon;
  final String title;
  final String subtitle;
  final String focusTooltip;
  final VoidCallback onTap;
  final List<Widget> children;
  final Widget? leading;
  final bool useTileLayout;

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
              leading: leading,
              title: title,
              subtitle: subtitle,
              focusTooltip: focusTooltip,
              onTap: onTap,
            ),
            if (children.isNotEmpty)
              _EmpireGroupChildren(
                useTileLayout: useTileLayout,
                children: children,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmpireGroupChildren extends StatelessWidget {
  const _EmpireGroupChildren({
    required this.children,
    required this.useTileLayout,
  });

  final List<Widget> children;
  final bool useTileLayout;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.bandDecoration(
        background: GameUiTheme.surface,
        backgroundAlpha: 188,
        border: BorderEmphasis.subtle,
        topBorder: true,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: useTileLayout
            ? _EmpireTileGrid(children: children)
            : _EmpireRowList(children: children),
      ),
    );
  }
}

class _EmpireTileGrid extends StatelessWidget {
  const _EmpireTileGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columns = availableWidth == double.infinity
            ? 1
            : (availableWidth / 220).floor().clamp(1, 5);
        final columnsOrDefault = columns <= 0 ? 1 : columns;
        final itemWidth =
            (availableWidth - (columnsOrDefault - 1) * 8) / columnsOrDefault;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _EmpireRowList extends StatelessWidget {
  const _EmpireRowList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _EmpireGroupHeader extends StatelessWidget {
  const _EmpireGroupHeader({
    required this.icon,
    this.leading,
    required this.title,
    required this.subtitle,
    required this.focusTooltip,
    required this.onTap,
  });

  final GameIconData icon;
  final Widget? leading;
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
              _EmpireGroupIcon(icon: icon, leading: leading),
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

class _EmpireUnitBlock extends StatelessWidget {
  const _EmpireUnitBlock({
    required this.icon,
    required this.title,
    required this.movement,
    required this.state,
    required this.hp,
    required this.focusTooltip,
    required this.onTap,
    super.key,
  });

  final GameIconData icon;
  final String title;
  final String movement;
  final String state;
  final String hp;
  final String focusTooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EmpireUnitIcon(icon: icon),
              const SizedBox(width: 10),
              Expanded(
                child: _EmpireUnitSummary(
                  title: title,
                  movement: movement,
                  state: state,
                  hp: hp,
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

class _EmpireUnitIcon extends StatelessWidget {
  const _EmpireUnitIcon({required this.icon});

  final GameIconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _EmpireUnitSummary extends StatelessWidget {
  const _EmpireUnitSummary({
    required this.title,
    required this.movement,
    required this.state,
    required this.hp,
  });

  final String title;
  final String movement;
  final String state;
  final String hp;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        _EmpireUnitMetadataLine(label: 'PR', value: movement),
        _EmpireUnitMetadataLine(label: 'Stan', value: state),
        _EmpireUnitMetadataLine(label: 'HP', value: hp),
      ],
    );
  }
}

class _EmpireUnitMetadataLine extends StatelessWidget {
  const _EmpireUnitMetadataLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: GameUiTheme.textSecondary,
          fontFamily: GameUiTheme.bodyFont,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
