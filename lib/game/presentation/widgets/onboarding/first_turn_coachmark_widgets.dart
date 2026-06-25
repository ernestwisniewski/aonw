import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_metrics.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_step.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

class CoachmarkTargetHalo extends StatelessWidget {
  const CoachmarkTargetHalo({required this.anchor, super.key});

  final CoachmarkAnchor anchor;

  @override
  Widget build(BuildContext context) {
    final metrics = CoachmarkAnchorMetrics.resolve(context, anchor);
    return Positioned(
      left: metrics.halo.left,
      top: metrics.halo.top,
      width: metrics.halo.width,
      height: metrics.halo.height,
      child: IgnorePointer(
        child: DecoratedBox(
          key: const Key('firstTurnCoachmarks.halo'),
          decoration: SurfaceElevation.modal.decoration(
            accent: metrics.accent,
            background: metrics.accent,
            backgroundAlpha: 18,
            borderColor: metrics.accent,
            border: BorderEmphasis.active,
            borderWidth: 1.5,
            borderRadius: BorderRadius.circular(metrics.haloRadius),
            glowColor: metrics.accent,
            glowAlpha: 70,
          ),
        ),
      ),
    );
  }
}

class CoachmarkBubble extends StatelessWidget {
  const CoachmarkBubble({
    required this.step,
    required this.current,
    required this.total,
    required this.onSkip,
    required this.onNext,
    required this.onMinimize,
    super.key,
  });

  final CoachmarkStep step;
  final int current;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metrics = CoachmarkAnchorMetrics.resolve(context, step.anchor);
    final isLast = current == total;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom + 12;
    final maxBubbleHeight =
        (mediaQuery.size.height - metrics.bubble.top - bottomInset)
            .clamp(188.0, 320.0)
            .toDouble();

    return Positioned(
      left: metrics.bubble.left,
      top: metrics.bubble.top,
      width: metrics.bubble.width,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxBubbleHeight),
        child: DecoratedBox(
          decoration: SurfaceElevation.modal.decoration(
            accent: metrics.accent,
            background: GameUiTheme.bg,
            backgroundAlpha: 238,
            border: BorderEmphasis.strong,
            shape: SurfaceShape.card,
            glowColor: metrics.accent,
            glowAlpha: 34,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: SurfaceElevation.floating.decoration(
                        accent: metrics.accent,
                        background: metrics.accent,
                        backgroundAlpha: 34,
                        border: BorderEmphasis.regular,
                        shape: SurfaceShape.button,
                        includeShadow: false,
                      ),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: GameIcon(
                            step.icon,
                            size: GameIconSize.regular,
                            color: metrics.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.firstTurnCoachmarkProgressLabel(
                              current,
                              total,
                            ),
                            style: GameHudTheme.selectionTag.copyWith(
                              color: GameUiTheme.textSecondary,
                              fontSize: 10,
                              fontFeatures: GameUiTheme.tabularFigures,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.title,
                            style: GameUiTheme.cardTitle.copyWith(
                              color: GameUiTheme.goldLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    CoachmarkHeaderIconButton(
                      key: const Key('firstTurnCoachmarks.minimize'),
                      tooltip: l10n.firstTurnCoachmarkMinimizeTooltip,
                      icon: GameIcons.minus,
                      color: metrics.accent,
                      onTap: onMinimize,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    primary: false,
                    child: Text(
                      step.body,
                      style: GameUiTheme.body.copyWith(
                        color: GameUiTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: onSkip,
                      style: GameUiTheme.textButtonStyle(
                        foreground: GameUiTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      child: Text(l10n.firstTurnCoachmarkSkipAction),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onNext,
                      style: GameUiTheme.textButtonStyle(
                        foreground: GameUiTheme.goldLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        isLast
                            ? l10n.firstTurnCoachmarkDoneAction
                            : l10n.firstTurnCoachmarkNextAction,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CoachmarkHeaderIconButton extends StatelessWidget {
  const CoachmarkHeaderIconButton({
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
