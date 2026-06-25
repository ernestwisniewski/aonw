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
  Widget build(BuildContext context) {
    return SizedBox(
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
  Widget build(BuildContext context) {
    return SizedBox(
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
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final bool active;
  final bool enabled;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? GameUiTheme.goldLight : GameUiTheme.textPrimary;
    return TextButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 16),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 34),
        foregroundColor: foreground,
        disabledForegroundColor: GameUiTheme.textTertiary,
        backgroundColor: active
            ? GameUiTheme.gold.withAlpha(36)
            : GameUiTheme.surface.withAlpha(190),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: GameUiTheme.actionLabel.copyWith(fontSize: 10),
        shape: RoundedRectangleBorder(
          borderRadius: GameUiTheme.borderRadius,
          side: BorderSide(
            color: active ? GameUiTheme.gold : GameUiTheme.gold.withAlpha(74),
          ),
        ),
      ),
    );
  }
}

class _ActionFilterButton extends StatelessWidget {
  const _ActionFilterButton({
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minWidth: 56, minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? GameUiTheme.gold.withAlpha(38)
                : GameUiTheme.surface.withAlpha(190),
            borderRadius: GameUiTheme.borderRadius,
            border: Border.all(
              color: selected
                  ? GameUiTheme.gold
                  : GameUiTheme.gold.withAlpha(74),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.actionLabel.copyWith(
              color: selected ? GameUiTheme.goldLight : GameUiTheme.textPrimary,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  const _IconToggle({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        isSelected: active,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: active
              ? GameUiTheme.gold.withAlpha(36)
              : GameUiTheme.surface.withAlpha(190),
          foregroundColor: active ? GameUiTheme.goldLight : GameUiTheme.gold,
          side: BorderSide(
            color: active ? GameUiTheme.gold : GameUiTheme.gold.withAlpha(74),
          ),
          shape: RoundedRectangleBorder(borderRadius: GameUiTheme.borderRadius),
        ),
        icon: Icon(icon, size: 19),
      ),
    );
  }
}

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

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.gold.withAlpha(28),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(116)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: GameUiTheme.toolbarLabel.copyWith(
            color: GameUiTheme.goldLight,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
