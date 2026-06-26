part of 'replay_screen.dart';

class _ReplayPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReplayPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.surface.withAlpha(210),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GameUiTheme.gold.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: GameUiTheme.goldLight),
            const SizedBox(width: 5),
            Text(label, style: GameUiTheme.cardMeta),
          ],
        ),
      ),
    );
  }
}

class _ReplayIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool emphasized;

  const _ReplayIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = emphasized ? GameUiTheme.goldLight : GameUiTheme.textPrimary;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: emphasized ? 24 : 21),
        color: color,
        disabledColor: GameUiTheme.textTertiary.withAlpha(120),
        style: IconButton.styleFrom(
          backgroundColor: emphasized
              ? GameUiTheme.gold.withAlpha(42)
              : GameUiTheme.surface.withAlpha(215),
          side: BorderSide(
            color: emphasized
                ? GameUiTheme.goldLight.withAlpha(150)
                : GameUiTheme.gold.withAlpha(90),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          fixedSize: const Size.square(42),
        ),
      ),
    );
  }
}

class _ReplayChipButton extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onPressed;

  const _ReplayChipButton({
    required this.selected,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: selected ? GameUiTheme.bg : GameUiTheme.textSecondary,
        backgroundColor: selected
            ? GameUiTheme.goldLight
            : GameUiTheme.surface.withAlpha(210),
        minimumSize: const Size(44, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: GameUiTheme.gold.withAlpha(95)),
        ),
      ),
      child: Text(label, style: const TextStyle(letterSpacing: 0)),
    );
  }
}
