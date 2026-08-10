part of 'selection_command_chip.dart';

class _SelectionCommandChipSurface extends StatelessWidget {
  const _SelectionCommandChipSurface({
    required this.widget,
    required this.style,
    required this.canTap,
    required this.shouldPulse,
    required this.pulseAnimation,
  });

  final SelectionCommandChip widget;
  final _SelectionCommandChipStyle style;
  final bool canTap;
  final bool shouldPulse;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: canTap ? 1 : widget.disabledOpacity,
      duration: GameMotion.snap,
      child: AnimatedBuilder(
        animation: pulseAnimation,
        child: _SelectionCommandChipContent(widget: widget, style: style),
        builder: (context, child) {
          final pulse = shouldPulse
              ? Curves.easeInOut.transform(pulseAnimation.value)
              : 0.0;
          return AnimatedContainer(
            key: Key('selectionInfo.action.${widget.actionId}'),
            duration: GameMotion.snap,
            curve: GameMotion.enter,
            width: widget.mainExtent,
            height: SelectionCommandChip.extent,
            decoration: style.surface.decoration(
              accent: style.accent,
              background: style.pulseBackground(widget, pulse),
              backgroundAlpha: widget.dangerOutlined ? 245 : null,
              borderColor: widget.dangerOutlined ? style.dangerBorder : null,
              border: style.highlighted
                  ? BorderEmphasis.active
                  : BorderEmphasis.strong,
              borderAlpha: widget.dangerOutlined ? 255 : null,
              borderWidth: style.borderWidth(widget, pulse),
              glowColor: style.highlighted && canTap && !widget.dangerOutlined
                  ? style.accent
                  : null,
              glowAlpha: style.glowAlpha(widget, pulse),
              includeShadow: true,
              shape: SurfaceShape.chip,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

class _SelectionCommandChipContent extends StatelessWidget {
  const _SelectionCommandChipContent({
    required this.widget,
    required this.style,
  });

  final SelectionCommandChip widget;
  final _SelectionCommandChipStyle style;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: _mainContent()),
        if (widget.badgeLabel case final badge?)
          Positioned(
            top: -5,
            right: -5,
            child: _SelectionCommandChipBadge(
              label: badge,
              color: style.accent,
            ),
          ),
      ],
    );
  }

  Widget _mainContent() {
    if (!widget.showLabel) {
      return Center(
        child: GameIcon(
          widget.icon,
          size: SelectionCommandChip.iconExtent,
          color: style.foreground,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SelectionCommandChip._labeledHorizontalPadding / 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(
            widget.icon,
            size: GameIconSize.regular,
            color: style.foreground,
          ),
          const SizedBox(width: SelectionCommandChip._labeledIconGap),
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: GameUiTheme.actionLabel.copyWith(color: style.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionCommandChipBadge extends StatelessWidget {
  const _SelectionCommandChipBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.modal.decoration(
        background: color,
        borderColor: GameUiTheme.bg,
        border: BorderEmphasis.active,
        shape: SurfaceShape.pill,
        includeShadow: true,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            color: GameUiTheme.bg,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontFeatures: GameUiTheme.tabularFigures,
          ),
        ),
      ),
    );
  }
}
