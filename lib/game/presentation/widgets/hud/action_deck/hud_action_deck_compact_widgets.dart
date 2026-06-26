part of 'hud_action_deck.dart';

const _compactSurfaceAlpha = 222,
    _compactSurfaceBorderAlpha = 145,
    _compactCollapsedAlpha = 224,
    _compactCollapsedBorderAlpha = 130,
    _compactToggleAlpha = 215,
    _compactToggleBorderAlpha = 115;

class _CompactSelectionCommandSurface extends StatelessWidget {
  const _CompactSelectionCommandSurface({
    required this.contextLine,
    required this.commandLine,
    required this.toggleTooltip,
    required this.onToggle,
  });

  final Widget? contextLine;
  final Widget commandLine;
  final String toggleTooltip;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('hudActionDeck.compactSurface'),
      decoration: SurfaceElevation.modal.decoration(
        background: GameUiTheme.surface,
        backgroundAlpha: _compactSurfaceAlpha,
        borderColor: GameUiTheme.gold,
        borderAlpha: _compactSurfaceBorderAlpha,
        radius: 8,
        glowColor: GameUiTheme.gold,
        glowAlpha: 42,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (contextLine == null)
              const Spacer()
            else
              Expanded(child: contextLine!),
            const SizedBox(width: 8),
            SizedBox(
              width: HudActionDeck.compactCommandLineWidth,
              child: commandLine,
            ),
            const SizedBox(width: 6),
            _CompactDeckToggleButton(
              collapsed: false,
              tooltip: toggleTooltip,
              onPressed: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactCollapsedDeck extends StatelessWidget {
  const _CompactCollapsedDeck({
    required this.commandLine,
    required this.toggleTooltip,
    required this.onToggle,
  });

  final Widget commandLine;
  final String toggleTooltip;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Align(
      widthFactor: 1,
      heightFactor: 1,
      child: DecoratedBox(
        key: const Key('hudActionDeck.compactCollapsed'),
        decoration: SurfaceElevation.raised.decoration(
          background: GameUiTheme.bg,
          backgroundAlpha: _compactCollapsedAlpha,
          borderColor: GameUiTheme.gold,
          borderAlpha: _compactCollapsedBorderAlpha,
          radius: 8,
          glowColor: GameUiTheme.gold,
          glowAlpha: 38,
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CompactDeckToggleButton(
                collapsed: true,
                tooltip: toggleTooltip,
                onPressed: onToggle,
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: HudActionDeck.compactCommandLineWidth,
                child: commandLine,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactDeckToggleButton extends StatelessWidget {
  const _CompactDeckToggleButton({
    required this.collapsed,
    required this.tooltip,
    required this.onPressed,
  });

  final bool collapsed;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        key: Key(
          collapsed
              ? 'hudActionDeck.compactExpand'
              : 'hudActionDeck.compactCollapse',
        ),
        onPressed: onPressed,
        icon: GameIcon(
          collapsed ? GameIcons.chevronUp : GameIcons.chevronDown,
          size: 22,
          color: GameUiTheme.goldLight,
        ),
        color: GameUiTheme.goldLight,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(38),
          backgroundColor: GameUiTheme.surface.withAlpha(_compactToggleAlpha),
          side: BorderSide(
            color: GameUiTheme.gold.withAlpha(_compactToggleBorderAlpha),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _CityExpansionSelectionToolbar extends StatelessWidget {
  const _CityExpansionSelectionToolbar({
    required this.canConfirm,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  final bool canConfirm;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final dangerFill = Color.lerp(
      GameUiTheme.danger,
      GameUiTheme.copper,
      0.18,
    )!;
    final dangerBorder = Color.lerp(
      GameUiTheme.dangerSubtle,
      GameUiTheme.copperDeep,
      0.22,
    )!;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: canConfirm ? 360 : 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canConfirm) ...[
            Expanded(
              child: _ModeToolbarButton(
                key: const Key('hudActionDeck.cityExpansionConfirm'),
                icon: GameIcons.checkCircle,
                label: confirmLabel,
                onPressed: onConfirm,
                backgroundColor: GameUiTheme.gold,
                foregroundColor: GameUiTheme.bg,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: _ModeToolbarButton(
              key: const Key('hudActionDeck.cityExpansionCancel'),
              icon: GameIcons.close,
              label: cancelLabel,
              onPressed: onCancel,
              backgroundColor: dangerFill,
              foregroundColor: Colors.black,
              borderColor: dangerBorder,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToolbarButton extends StatelessWidget {
  const _ModeToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    super.key,
  });

  final GameIconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: borderColor == null ? null : BorderSide(color: borderColor!),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: GameIcon(icon, size: GameIconSize.small, color: foregroundColor),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.actionLabel.copyWith(color: foregroundColor),
        ),
      ),
    );
  }
}
