import 'package:aonw/game/presentation/widgets/selection/density.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class SelectionYieldStrip extends StatelessWidget {
  const SelectionYieldStrip({
    required this.items,
    required this.density,
    this.title,
    this.tooltip,
    super.key,
  });

  final List<SelectionYieldItem> items;
  final SelectionDensity density;
  final String? title;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final spec = SelectionDensitySpec.of(density);
    final strip = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.toolbarLabel.copyWith(
              fontSize: spec.yieldTitleFontSize,
              color: GameHudTheme.textMuted,
            ),
          ),
          SizedBox(height: spec.yieldTitleGap),
        ],
        Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(
                child: _YieldMetric(item: items[i], spec: spec),
              ),
              if (i != items.length - 1) SizedBox(width: spec.yieldMetricGap),
            ],
          ],
        ),
      ],
    );

    if (tooltip == null) return strip;
    return Tooltip(
      message: tooltip!,
      child: Semantics(label: tooltip, child: strip),
    );
  }
}

class _YieldMetric extends StatelessWidget {
  const _YieldMetric({required this.item, required this.spec});

  final SelectionYieldItem item;
  final SelectionDensitySpec spec;

  @override
  Widget build(BuildContext context) {
    final label = '${item.label}: ${item.value}';
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Container(
          height: spec.yieldMetricHeight,
          padding: spec.yieldMetricPadding,
          decoration: ShapeDecoration(
            color: SurfaceElevation.flat.fill(
              background: item.color,
              alpha: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: SurfaceElevation.flat.strokeColor(
                  color: item.color,
                  alpha: 105,
                ),
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showValue =
                  constraints.maxWidth >= spec.yieldValueBreakpoint;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GameIcon(
                    item.icon,
                    size: spec.yieldIconSize,
                    color: item.color,
                  ),
                  if (showValue) ...[
                    SizedBox(width: spec.yieldIconGap),
                    Flexible(
                      child: Text(
                        '${item.value}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GameHudTheme.yieldValue,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
