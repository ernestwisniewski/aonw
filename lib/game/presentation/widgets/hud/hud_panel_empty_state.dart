import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

class HudPanelEmptyState extends StatelessWidget {
  final GameIconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final bool compact;

  const HudPanelEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.accent = GameUiTheme.gold,
    this.padding = const EdgeInsets.all(18),
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;

    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        accent: accent,
        background: GameUiTheme.bg,
        backgroundAlpha: 138,
        border: BorderEmphasis.subtle,
        shape: SurfaceShape.card,
        includeShadow: false,
      ),
      child: Padding(
        padding: padding,
        child: compact
            ? _CompactContent(
                icon: icon,
                title: title,
                body: body,
                actionLabel: actionLabel,
                onAction: onAction,
                accent: accent,
                hasAction: hasAction,
              )
            : _StackedContent(
                icon: icon,
                title: title,
                body: body,
                actionLabel: actionLabel,
                onAction: onAction,
                accent: accent,
                hasAction: hasAction,
              ),
      ),
    );
  }
}

class _StackedContent extends StatelessWidget {
  final GameIconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;
  final bool hasAction;

  const _StackedContent({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    required this.accent,
    required this.hasAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _EmptyIcon(icon: icon, accent: accent),
        const SizedBox(height: 12),
        _EmptyCopy(title: title, body: body, textAlign: TextAlign.center),
        if (hasAction) ...[
          const SizedBox(height: 12),
          _EmptyAction(label: actionLabel!, onPressed: onAction!),
        ],
      ],
    );
  }
}

class _CompactContent extends StatelessWidget {
  final GameIconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;
  final bool hasAction;

  const _CompactContent({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    required this.accent,
    required this.hasAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _EmptyIcon(icon: icon, accent: accent),
        const SizedBox(width: 12),
        Expanded(
          child: _EmptyCopy(title: title, body: body),
        ),
        if (hasAction) ...[
          const SizedBox(width: 12),
          Flexible(
            flex: 0,
            child: _EmptyAction(label: actionLabel!, onPressed: onAction!),
          ),
        ],
      ],
    );
  }
}

class _EmptyIcon extends StatelessWidget {
  final GameIconData icon;
  final Color accent;

  const _EmptyIcon({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.floating.decoration(
        accent: accent,
        background: accent,
        backgroundAlpha: 26,
        border: BorderEmphasis.regular,
        shape: SurfaceShape.button,
        includeShadow: false,
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: GameIcon(icon, color: accent, size: GameIconSize.regular),
        ),
      ),
    );
  }
}

class _EmptyCopy extends StatelessWidget {
  final String title;
  final String body;
  final TextAlign textAlign;

  const _EmptyCopy({
    required this.title,
    required this.body,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: GameUiTheme.sectionHeader.copyWith(
            color: GameUiTheme.goldLight,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          body,
          textAlign: textAlign,
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _EmptyAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _EmptyAction({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: GameUiTheme.textButtonStyle(
        foreground: GameUiTheme.goldLight,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      ),
      child: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}
