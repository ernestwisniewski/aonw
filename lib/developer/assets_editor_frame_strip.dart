part of 'assets_editor_screen.dart';

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
