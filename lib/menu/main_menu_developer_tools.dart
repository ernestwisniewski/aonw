part of 'main_menu_screen.dart';

class _DeveloperToolsPanel extends ConsumerWidget {
  const _DeveloperToolsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(232),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(86)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.construction_outlined,
                  size: 17,
                  color: GameUiTheme.gold,
                ),
                const SizedBox(width: 8),
                Text(
                  GameText.sectionLabel(l10n.mainMenuToolsTitle),
                  style: GameUiTheme.sectionHeader.copyWith(
                    color: GameUiTheme.goldLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DeveloperToolButton(
              icon: Icons.map_outlined,
              label: GameText.actionLabel(l10n.mainMenuMapEditor),
              semanticLabel: l10n.mainMenuMapEditor,
              onPressed: ref.withMenuClick(() => context.go('/editor')),
            ),
            const SizedBox(height: 8),
            _DeveloperToolButton(
              icon: Icons.photo_library_outlined,
              label: GameText.actionLabel(l10n.mainMenuAssetsEditor),
              semanticLabel: l10n.mainMenuAssetsEditor,
              onPressed: ref.withMenuClick(
                () => context.go('/developer/assets'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeveloperToolButton extends StatefulWidget {
  const _DeveloperToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final String? semanticLabel;
  final VoidCallback onPressed;

  @override
  State<_DeveloperToolButton> createState() => _DeveloperToolButtonState();
}

class _DeveloperToolButtonState extends State<_DeveloperToolButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MenuGamepadAction(
      onActivate: widget.onPressed,
      borderRadius: GameUiTheme.borderRadius,
      builder: (context, focused) {
        final highlighted = focused || _hovered;
        final foreground = highlighted
            ? GameUiTheme.goldLight
            : GameUiTheme.textPrimary;
        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Semantics(
            button: true,
            label: widget.semanticLabel ?? widget.label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                constraints: const BoxConstraints(minHeight: 42),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: highlighted
                      ? GameUiTheme.gold.withAlpha(28)
                      : GameUiTheme.surface.withAlpha(190),
                  borderRadius: GameUiTheme.borderRadius,
                  border: Border.all(
                    color: highlighted
                        ? GameUiTheme.gold
                        : GameUiTheme.gold.withAlpha(70),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 18, color: GameUiTheme.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GameUiTheme.actionLabel.copyWith(
                          color: foreground,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 17,
                      color: GameUiTheme.gold.withAlpha(
                        highlighted ? 220 : 130,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
