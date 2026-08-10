part of 'end_turn_button.dart';

class _EndTurnContent extends StatelessWidget {
  const _EndTurnContent({
    required this.compact,
    required this.turn,
    required this.label,
    required this.actionCount,
    required this.objectiveLinked,
    required this.icon,
    required this.foreground,
    required this.showTurnLabel,
    required this.transitionDuration,
  });

  final bool compact;
  final int turn;
  final String label;
  final int actionCount;
  final bool objectiveLinked;
  final GameIconData icon;
  final Color foreground;
  final bool showTurnLabel;
  final Duration transitionDuration;

  @override
  Widget build(BuildContext context) {
    final actionRow = _EndTurnActionRow(
      compact: compact,
      label: label,
      actionCount: actionCount,
      objectiveLinked: objectiveLinked,
      icon: icon,
      foreground: foreground,
      transitionDuration: transitionDuration,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      child: showTurnLabel
          ? _EndTurnContentWithTurn(
              compact: compact,
              turn: turn,
              foreground: foreground,
              actionRow: actionRow,
            )
          : Center(child: actionRow),
    );
  }
}

class _EndTurnActionRow extends StatelessWidget {
  const _EndTurnActionRow({
    required this.compact,
    required this.label,
    required this.actionCount,
    required this.objectiveLinked,
    required this.icon,
    required this.foreground,
    required this.transitionDuration,
  });

  final bool compact;
  final String label;
  final int actionCount;
  final bool objectiveLinked;
  final GameIconData icon;
  final Color foreground;
  final Duration transitionDuration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: transitionDuration,
      switchInCurve: GameMotion.enter,
      switchOutCurve: GameMotion.exit,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [...previousChildren, ?currentChild],
      ),
      child: Row(
        key: ValueKey('$label:$actionCount'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(
            icon,
            size: compact ? GameIconSize.tiny : GameIconSize.small,
            color: foreground,
          ),
          SizedBox(width: compact ? 4 : 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: GameHudTheme.buttonLabel.copyWith(
                  color: foreground,
                  fontSize: compact ? 10 : 11,
                  height: 1,
                ),
              ),
            ),
          ),
          if (objectiveLinked) ...[
            SizedBox(width: compact ? 3 : 4),
            GameIcon(
              GameIcons.checkCircle,
              key: const Key('endTurnButton.objectiveLink'),
              size: compact ? 9 : 10,
              color: SurfaceElevation.flat.fill(
                background: foreground,
                alpha: 230,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EndTurnContentWithTurn extends StatelessWidget {
  const _EndTurnContentWithTurn({
    required this.compact,
    required this.turn,
    required this.foreground,
    required this.actionRow,
  });

  final bool compact;
  final int turn;
  final Color foreground;
  final Widget actionRow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          AppLocalizations.of(context).endTurnButtonTurnLabel(turn),
          maxLines: 1,
          style: GameHudTheme.buttonTopLabel.copyWith(
            color: SurfaceElevation.flat.fill(
              background: foreground,
              alpha: 210,
            ),
            fontSize: 10,
            height: 1,
            fontFeatures: GameUiTheme.tabularFigures,
          ),
        ),
        const SizedBox(height: 2),
        actionRow,
      ],
    );
  }
}

class _EndTurnMainSegment extends StatelessWidget {
  const _EndTurnMainSegment({
    required this.tooltipLabel,
    required this.waiting,
    required this.onTap,
    required this.child,
  });

  final String tooltipLabel;
  final bool waiting;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipLabel,
      child: Semantics(
        button: true,
        enabled: !waiting,
        label: tooltipLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: waiting ? null : onTap,
          child: child,
        ),
      ),
    );
  }
}
