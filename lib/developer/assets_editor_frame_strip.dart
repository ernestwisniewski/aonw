part of 'assets_editor_screen.dart';

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(42),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: color.withAlpha(160)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: GameUiTheme.toolbarLabel.copyWith(
            color: GameUiTheme.textPrimary,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameUiTheme.surface.withAlpha(172),
          borderRadius: GameUiTheme.borderRadius,
          border: Border.all(color: GameUiTheme.gold.withAlpha(42)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.cardMeta.copyWith(fontSize: 10),
          ),
        ),
      ),
    );
  }
}

class _FrameStrip extends StatelessWidget {
  const _FrameStrip({
    required this.frameCount,
    required this.selectedFrame,
    this.onFrameSelected,
  });

  final int frameCount;
  final int selectedFrame;
  final ValueChanged<int>? onFrameSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < frameCount; index++) ...[
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onFrameSelected == null
                  ? null
                  : () => onFrameSelected!(index),
              child: Semantics(
                button: onFrameSelected != null,
                selected: index == selectedFrame,
                label: 'Frame ${index + 1}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  height: onFrameSelected == null ? 4 : 10,
                  decoration: BoxDecoration(
                    color: index == selectedFrame
                        ? GameUiTheme.goldLight
                        : GameUiTheme.gold.withAlpha(70),
                    borderRadius: GameUiTheme.borderRadius,
                  ),
                ),
              ),
            ),
          ),
          if (index != frameCount - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}
