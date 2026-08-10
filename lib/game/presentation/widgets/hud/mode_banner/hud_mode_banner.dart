import 'package:aonw/game/presentation/widgets/hud/mode_banner/hud_mode_banner_spec.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

export 'package:aonw/game/presentation/widgets/hud/mode_banner/hud_mode_banner_spec.dart';

class HudModeBanner extends StatelessWidget {
  const HudModeBanner({
    required this.spec,
    required this.compact,
    this.onMinimize,
    super.key,
  });

  final HudModeBannerSpec spec;
  final bool compact;
  final VoidCallback? onMinimize;

  @override
  Widget build(BuildContext context) {
    final banner = _banner(context);
    if (MediaQuery.disableAnimationsOf(context)) return banner;
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, -0.18), end: Offset.zero),
      duration: GameMotion.slide,
      curve: GameMotion.enter,
      child: banner,
      builder: (context, offset, child) => SlideTransition(
        position: AlwaysStoppedAnimation(offset),
        child: child,
      ),
    );
  }

  Widget _banner(BuildContext context) {
    return DecoratedBox(
      key: Key('hudModeBanner.${spec.id}'),
      decoration: SurfaceElevation.raised.decoration(
        accent: spec.accent,
        background: GameUiTheme.surfaceDeep,
        backgroundAlpha: 232,
        border: BorderEmphasis.strong,
        shape: SurfaceShape.card,
        glowColor: spec.accent,
        glowAlpha: 28,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 12,
          compact ? 9 : 11,
          compact ? 10 : 12,
          compact ? 9 : 11,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: GameIcon(
                spec.icon,
                size: GameIconSize.large,
                color: spec.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _content(context)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(l10n),
        const SizedBox(height: 4),
        Text(
          spec.instruction,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: GameUiTheme.textSecondary,
            fontSize: 11,
            height: 1.22,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (spec.details.isNotEmpty) ...[
          SizedBox(height: compact ? 7 : 8),
          _ModeBannerDetails(
            details: spec.details,
            accent: spec.accent,
            compact: compact,
          ),
        ],
        if (spec.primaryAction != null) ...[
          SizedBox(height: compact ? 8 : 10),
          _ModeBannerToolbarHint(
            label: l10n.modeBannerActionToolbarHint,
            accent: spec.accent,
          ),
        ],
      ],
    );
  }

  Widget _header(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            spec.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameHudTheme.selectionTitle.copyWith(
              color: GameUiTheme.goldLight,
              fontSize: 13,
            ),
          ),
        ),
        if (spec.progress != null) ...[
          const SizedBox(width: 8),
          _ProgressBadge(label: spec.progress!, accent: spec.accent),
        ],
        if (onMinimize != null && spec.minimizable) ...[
          const SizedBox(width: 4),
          _HeaderIconButton(
            key: const Key('hudModeBanner.minimize'),
            tooltip: l10n.selectionActionMinimize,
            icon: GameIcons.minus,
            color: spec.accent,
            onTap: onMinimize!,
          ),
        ],
      ],
    );
  }
}

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
