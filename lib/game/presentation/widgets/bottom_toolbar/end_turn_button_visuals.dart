part of 'end_turn_button.dart';

/// Resolved colors / labels for one mode. Centralises the per-state knobs that
/// were previously sprinkled through [EndTurnButton.build].
class _EndTurnVisuals {
  final List<Color> gradientColors;
  final Color borderColor;
  final Color glowColor;
  final Color foreground;
  final String label;
  final GameIconData icon;

  const _EndTurnVisuals({
    required this.gradientColors,
    required this.borderColor,
    required this.glowColor,
    required this.foreground,
    required this.label,
    required this.icon,
  });

  factory _EndTurnVisuals.forMode(
    _EndTurnButtonMode mode,
    AppLocalizations l10n,
  ) {
    switch (mode) {
      case _EndTurnButtonMode.waiting:
        const base = GameHudTheme.colorWaiting;
        final dim = SurfaceElevation.flat.fill(
          background: GameUiTheme.surface,
          alpha: 150,
        );
        return _EndTurnVisuals(
          gradientColors: [Color.lerp(dim, Colors.white, 0.08)!, dim],
          borderColor: SurfaceElevation.flat.strokeColor(
            accent: base,
            alpha: 210,
          ),
          glowColor: base,
          foreground: base,
          label: GameText.actionLabel(l10n.waitingTurnButtonLabel),
          icon: GameIcons.hourglass,
        );
      case _EndTurnButtonMode.ready:
        return _EndTurnVisuals(
          gradientColors: const [Color(0xFFD2A856), Color(0xFFB68838)],
          borderColor: GameUiTheme.copperDeep,
          glowColor: GameUiTheme.copper,
          foreground: GameUiTheme.bg,
          label: GameText.actionLabel(l10n.endTurnButtonLabel),
          icon: GameIcons.checkCircle,
        );
      case _EndTurnButtonMode.action:
        const base = GameUiTheme.goldLight;
        final bg = SurfaceElevation.raised.fill(
          background: GameUiTheme.surface,
          alpha: 222,
        );
        return _EndTurnVisuals(
          gradientColors: [Color.lerp(bg, Colors.white, 0.08)!, bg],
          borderColor: SurfaceElevation.raised.strokeColor(
            accent: base,
            alpha: 210,
          ),
          glowColor: base,
          foreground: base,
          label: GameText.actionLabel(l10n.turnActionButtonLabel),
          icon: GameIcons.arrowRight,
        );
    }
  }
}
