part of 'hud_mode_banner.dart';

class _ModeBannerDetails extends StatelessWidget {
  const _ModeBannerDetails({
    required this.details,
    required this.accent,
    required this.compact,
  });

  final List<String> details;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth
            .clamp(0.0, compact ? 230.0 : 300.0)
            .toDouble();
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var index = 0; index < details.length; index++)
              _ModeBannerDetailChip(
                key: Key('hudModeBanner.detail.$index'),
                label: details[index],
                accent: accent,
                maxWidth: maxWidth,
              ),
          ],
        );
      },
    );
  }
}

class _ModeBannerDetailChip extends StatelessWidget {
  const _ModeBannerDetailChip({
    required this.label,
    required this.accent,
    required this.maxWidth,
    super.key,
  });

  final String label;
  final Color accent;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: SurfaceElevation.flat.decoration(
          accent: accent,
          background: GameUiTheme.chipSurface,
          backgroundAlpha: 160,
          border: BorderEmphasis.regular,
          shape: SurfaceShape.pill,
          includeShadow: false,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GameUiTheme.textPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeBannerToolbarHint extends StatelessWidget {
  const _ModeBannerToolbarHint({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('hudModeBanner.toolbarHint'),
      decoration: SurfaceElevation.flat.decoration(
        accent: accent,
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 145,
        border: BorderEmphasis.subtle,
        shape: SurfaceShape.chip,
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            GameIcon(
              GameIcons.arrowRight,
              size: GameIconSize.small,
              color: accent,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GameUiTheme.textPrimary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String tooltip;
  final GameIconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: GameUiTheme.borderRadius,
          onTap: onTap,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: GameIcon(
                icon,
                size: 16,
                color: SurfaceElevation.flat.fill(
                  background: color,
                  alpha: 230,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.floating.decoration(
        accent: accent,
        background: accent,
        backgroundAlpha: 30,
        border: BorderEmphasis.regular,
        shape: SurfaceShape.pill,
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
