import 'package:aonw/game/presentation/widgets/hud/hud_layout_metrics.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

class HudAutoTurnHintSlot extends StatelessWidget {
  const HudAutoTurnHintSlot({
    required this.layoutMetrics,
    required this.visible,
    required this.enabled,
    required this.onMinimize,
    super.key,
  });

  final HudLayoutMetrics layoutMetrics;
  final bool visible;
  final bool enabled;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Positioned(
      top: layoutMetrics.panelTopPadding + 8,
      left: layoutMetrics.contextualHintLeftPadding,
      right: layoutMetrics.portraitPhone ? 12 : null,
      child: Align(
        alignment: layoutMetrics.portraitPhone
            ? Alignment.topCenter
            : Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: layoutMetrics.portraitPhone ? 460 : 380,
          ),
          child: HudAutoTurnHint(
            enabled: enabled,
            compact: layoutMetrics.portraitPhone,
            onMinimize: onMinimize,
          ),
        ),
      ),
    );
  }
}

class HudAutoTurnHint extends StatelessWidget {
  const HudAutoTurnHint({
    required this.enabled,
    required this.compact,
    required this.onMinimize,
    super.key,
  });

  final bool enabled;
  final bool compact;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const accent = GameUiTheme.info;
    final hint = DecoratedBox(
      key: const Key('hudAutoTurnHint'),
      decoration: SurfaceElevation.raised.decoration(
        accent: accent,
        background: GameUiTheme.surfaceDeep,
        backgroundAlpha: 232,
        border: BorderEmphasis.strong,
        shape: SurfaceShape.card,
        glowColor: accent,
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
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: GameIcon(
                GameIcons.skipTurn,
                size: GameIconSize.large,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.autoTurnHintTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GameHudTheme.selectionTitle.copyWith(
                            color: GameUiTheme.goldLight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _HeaderIconButton(
                        buttonKey: const Key('hudAutoTurnHint.minimize'),
                        tooltip: l10n.selectionActionMinimize,
                        icon: GameIcons.minus,
                        color: accent,
                        onTap: onMinimize,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.autoTurnHintBody,
                    maxLines: compact ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GameUiTheme.textSecondary,
                      fontSize: 11,
                      height: 1.22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusChip(
                      label: enabled
                          ? l10n.autoTurnHintStatusOn
                          : l10n.autoTurnHintStatusOff,
                      enabled: enabled,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) return hint;

    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, -0.18), end: Offset.zero),
      duration: GameMotion.slide,
      curve: GameMotion.enter,
      child: hint,
      builder: (context, offset, child) {
        return SlideTransition(
          position: AlwaysStoppedAnimation(offset),
          child: child,
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = enabled ? GameUiTheme.success : GameHudTheme.colorNeutral;
    return DecoratedBox(
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: enabled ? GameUiTheme.success : GameUiTheme.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final Key buttonKey;
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
          key: buttonKey,
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
