part of 'assets_editor_screen.dart';

class _FrameEditPanel extends StatelessWidget {
  const _FrameEditPanel({
    required this.adjustment,
    required this.frameDuration,
    required this.frameCount,
    required this.frameIndex,
    required this.onAdjustmentChanged,
    required this.onResetAdjustment,
    this.onAnimationFrameDurationChanged,
    this.onResetAnimationFrameDuration,
  });

  final AnimationFrameAdjustment adjustment;
  final double frameDuration;
  final int frameCount;
  final int frameIndex;
  final ValueChanged<AnimationFrameAdjustment> onAdjustmentChanged;
  final ValueChanged<double>? onAnimationFrameDurationChanged;
  final VoidCallback? onResetAnimationFrameDuration;
  final VoidCallback onResetAdjustment;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.surface.withAlpha(168),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(48)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'FRAME ${frameIndex + 1}/$frameCount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.toolbarLabel.copyWith(
                      color: GameUiTheme.goldLight,
                      fontSize: 9,
                    ),
                  ),
                ),
                _TinyIconButton(
                  icon: Icons.center_focus_strong,
                  tooltip: 'Reset frame',
                  onTap: onResetAdjustment,
                ),
              ],
            ),
            if (frameCount > 1 &&
                onAnimationFrameDurationChanged != null &&
                onResetAnimationFrameDuration != null) ...[
              const SizedBox(height: 6),
              _AnimationTimingControl(
                frameCount: frameCount,
                frameDuration: frameDuration,
                onChanged: onAnimationFrameDurationChanged!,
                onReset: onResetAnimationFrameDuration!,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                const _EditLabel('ALIGN'),
                const SizedBox(width: 6),
                _TinyIconButton(
                  icon: Icons.keyboard_arrow_left,
                  tooltip: 'Move left',
                  onTap: () => onAdjustmentChanged(adjustment.nudge(dx: -2)),
                ),
                _TinyIconButton(
                  icon: Icons.keyboard_arrow_up,
                  tooltip: 'Move up',
                  onTap: () => onAdjustmentChanged(adjustment.nudge(dy: -2)),
                ),
                _TinyIconButton(
                  icon: Icons.keyboard_arrow_down,
                  tooltip: 'Move down',
                  onTap: () => onAdjustmentChanged(adjustment.nudge(dy: 2)),
                ),
                _TinyIconButton(
                  icon: Icons.keyboard_arrow_right,
                  tooltip: 'Move right',
                  onTap: () => onAdjustmentChanged(adjustment.nudge(dx: 2)),
                ),
                Expanded(
                  child: Text(
                    '${adjustment.offsetX.round()}, ${adjustment.offsetY.round()}',
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.cardMeta.copyWith(fontSize: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const _EditLabel('SCALE'),
                const SizedBox(width: 6),
                _TinyIconButton(
                  icon: Icons.zoom_out,
                  tooltip: 'Scale down',
                  onTap: () => onAdjustmentChanged(
                    adjustment.scaleBy(dx: -0.05, dy: -0.05),
                  ),
                ),
                _TinyIconButton(
                  icon: Icons.zoom_in,
                  tooltip: 'Scale up',
                  onTap: () => onAdjustmentChanged(
                    adjustment.scaleBy(dx: 0.05, dy: 0.05),
                  ),
                ),
                _TinyIconButton(
                  icon: Icons.aspect_ratio,
                  tooltip: 'Reset scale',
                  onTap: () => onAdjustmentChanged(adjustment.resetScale()),
                ),
                Expanded(
                  child: Text(
                    '${adjustment.scaleX.toStringAsFixed(2)}x, ${adjustment.scaleY.toStringAsFixed(2)}x',
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.cardMeta.copyWith(fontSize: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const _EditLabel('CROP'),
                const SizedBox(width: 6),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _CropButton(
                        label: 'L-',
                        onTap: () => onAdjustmentChanged(
                          adjustment.adjustCrop(left: -2),
                        ),
                      ),
                      _CropButton(
                        label: 'L+',
                        onTap: () =>
                            onAdjustmentChanged(adjustment.adjustCrop(left: 2)),
                      ),
                      _CropButton(
                        label: 'T-',
                        onTap: () =>
                            onAdjustmentChanged(adjustment.adjustCrop(top: -2)),
                      ),
                      _CropButton(
                        label: 'T+',
                        onTap: () =>
                            onAdjustmentChanged(adjustment.adjustCrop(top: 2)),
                      ),
                      _CropButton(
                        label: 'R-',
                        onTap: () => onAdjustmentChanged(
                          adjustment.adjustCrop(right: -2),
                        ),
                      ),
                      _CropButton(
                        label: 'R+',
                        onTap: () => onAdjustmentChanged(
                          adjustment.adjustCrop(right: 2),
                        ),
                      ),
                      _CropButton(
                        label: 'B-',
                        onTap: () => onAdjustmentChanged(
                          adjustment.adjustCrop(bottom: -2),
                        ),
                      ),
                      _CropButton(
                        label: 'B+',
                        onTap: () => onAdjustmentChanged(
                          adjustment.adjustCrop(bottom: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimationTimingControl extends StatelessWidget {
  const _AnimationTimingControl({
    required this.frameCount,
    required this.frameDuration,
    required this.onChanged,
    required this.onReset,
  });

  final int frameCount;
  final double frameDuration;
  final ValueChanged<double> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final totalDuration = frameDuration * frameCount;
    final sliderValue = totalDuration
        .clamp(_animationTotalDurationMin, _animationTotalDurationMax)
        .toDouble();
    return Row(
      children: [
        const _EditLabel('TIME'),
        const SizedBox(width: 6),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: GameUiTheme.gold,
              inactiveTrackColor: GameUiTheme.gold.withAlpha(58),
              thumbColor: GameUiTheme.goldLight,
              overlayColor: GameUiTheme.gold.withAlpha(24),
              trackHeight: 2,
            ),
            child: Slider(
              min: _animationTotalDurationMin,
              max: _animationTotalDurationMax,
              divisions:
                  ((_animationTotalDurationMax - _animationTotalDurationMin) *
                          100)
                      .round(),
              value: sliderValue,
              label: '${totalDuration.toStringAsFixed(2)}s',
              onChanged: (value) => onChanged(value / frameCount),
            ),
          ),
        ),
        SizedBox(
          width: 47,
          child: Text(
            '${totalDuration.toStringAsFixed(2)}s',
            maxLines: 1,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.cardMeta.copyWith(fontSize: 9),
          ),
        ),
        const SizedBox(width: 4),
        _TinyIconButton(
          icon: Icons.restore,
          tooltip: 'Reset animation time',
          onTap: onReset,
        ),
      ],
    );
  }
}

class _EditLabel extends StatelessWidget {
  const _EditLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 42,
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GameUiTheme.toolbarLabel.copyWith(
        color: GameUiTheme.textTertiary,
        fontSize: 8,
      ),
    ),
  );
}

class _TinyIconButton extends StatelessWidget {
  const _TinyIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: GameUiTheme.bg.withAlpha(150),
            borderRadius: GameUiTheme.borderRadius,
          ),
          child: SizedBox(
            width: 27,
            height: 27,
            child: Icon(icon, size: 17, color: GameUiTheme.goldLight),
          ),
        ),
      ),
    );
  }
}

class _CropButton extends StatelessWidget {
  const _CropButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 30,
    height: 24,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: GameUiTheme.goldLight,
        minimumSize: Size.zero,
        side: BorderSide(color: GameUiTheme.gold.withAlpha(76)),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: GameUiTheme.toolbarLabel.copyWith(fontSize: 8),
        shape: RoundedRectangleBorder(borderRadius: GameUiTheme.borderRadius),
      ),
      child: Text(label),
    ),
  );
}
