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

part 'hud_mode_banner_components.dart';

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
