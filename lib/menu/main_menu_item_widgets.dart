part of 'main_menu_screen.dart';

class _MenuSynopsis extends ConsumerWidget {
  const _MenuSynopsis({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (MediaQuery.sizeOf(context).height < 760) {
      return const SizedBox.shrink();
    }
    final updateNotice = _updateNoticeFor(ref);
    final title =
        updateNotice?.title(context.l10n) ?? 'BUILD · RESEARCH · COMMAND';
    final body =
        updateNotice?.body(context.l10n) ?? context.l10n.mainMenuWhatsNewBody;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(118),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
        border: Border.all(color: GameUiTheme.gold.withAlpha(82)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.toolbarLabel.copyWith(
                color: updateNotice == null
                    ? GameUiTheme.goldLight
                    : GameUiTheme.gold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              maxLines: compact && updateNotice == null ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                height: 1.32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.active = false,
    this.panelKind,
    this.semanticLabel,
    this.sublabel,
  });

  final IconData icon;
  final String label;
  final String? semanticLabel;
  final String? sublabel;
  final bool primary;
  final bool active;
  final _MenuPanelKind? panelKind;
  final VoidCallback onPressed;
}

enum _MenuPanelKind { developer }

class _AnimatedMenuExpansion extends StatelessWidget {
  const _AnimatedMenuExpansion({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 170),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SizeTransition(
          sizeFactor: curved,
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
      child: open
          ? Padding(
              key: const ValueKey('menuExpansion.open'),
              padding: const EdgeInsets.only(top: 8),
              child: child,
            )
          : const SizedBox.shrink(key: ValueKey('menuExpansion.closed')),
    );
  }
}
