import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_panel.dart';
import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/description_info_list.dart';
import 'package:aonw/game/presentation/widgets/theme/city_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/field_improvement_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter/material.dart';

class DescriptionDetailContent extends StatelessWidget {
  final SelectionDescriptionDetail model;
  final bool compact;

  const DescriptionDetailContent({
    required this.model,
    required this.compact,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final assetIcon = model.assetIcon;
    final improvementIcon = assetIcon?.isFieldImprovement ?? false;
    final cityIcon = assetIcon?.isCity ?? false;
    final assetFocusedDescription = improvementIcon || cityIcon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!assetFocusedDescription && model.heading.isNotEmpty)
          Text(model.heading, style: GameHudTheme.selectionTitle),
        if (!assetFocusedDescription && model.subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(model.subtitle, style: GameHudTheme.selectionSubtitle),
        ],
        if (!assetFocusedDescription && model.body.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            model.body,
            style: GameHudTheme.selectionSubtitle.copyWith(
              color: GameHudTheme.textSecondary,
              height: 1.35,
            ),
          ),
        ],
        if (model.cityYieldBreakdown != null) ...[
          if (model.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            DescriptionInfoList(items: model.items),
          ],
          const SizedBox(height: 10),
          CityYieldBreakdownPanel(model: model.cityYieldBreakdown!),
        ] else ...[
          if (model.yields.isNotEmpty && improvementIcon) ...[
            SelectionYieldStrip(
              items: model.yields,
              density: compact
                  ? SelectionDensity.compact
                  : SelectionDensity.comfortable,
              title: model.yieldTitle,
              tooltip: model.yieldTooltip,
            ),
          ],
          if (model.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectionTagStrip(
              tags: model.tags,
              density: compact
                  ? SelectionDensity.compact
                  : SelectionDensity.comfortable,
            ),
          ],
          if (model.yields.isNotEmpty && !improvementIcon) ...[
            const SizedBox(height: 10),
            SelectionYieldStrip(
              items: model.yields,
              density: compact
                  ? SelectionDensity.compact
                  : SelectionDensity.comfortable,
              title: model.yieldTitle,
              tooltip: model.yieldTooltip,
            ),
          ],
          if (model.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            SelectionDetailsChips(
              items: model.items,
              density: compact
                  ? SelectionDensity.compact
                  : SelectionDensity.comfortable,
            ),
          ],
        ],
        if (assetFocusedDescription && assetIcon != null) ...[
          SizedBox(height: compact ? 10 : 12),
          _DescriptionAssetPreview(
            assetIcon: assetIcon,
            compact: compact,
            fallbackColor:
                model.yields.firstOrNull?.color ?? GameHudTheme.accentFallback,
          ),
        ],
      ],
    );
  }
}

class _DescriptionAssetPreview extends StatelessWidget {
  const _DescriptionAssetPreview({
    required this.assetIcon,
    required this.compact,
    required this.fallbackColor,
  });

  static const double _sourceAspectRatio = 500 / 370;
  static const double _maxAssetWidth = 250;

  final SelectionAssetIconViewModel assetIcon;
  final bool compact;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : _maxAssetWidth;
        final width = availableWidth.clamp(0.0, _maxAssetWidth).toDouble();
        final height = width / _sourceAspectRatio;

        return Center(
          child: _buildIcon(width: width, height: height),
        );
      },
    );
  }

  Widget _buildIcon({required double width, required double height}) {
    if (assetIcon.isFieldImprovement) {
      return FieldImprovementSpriteIcon(
        key: const Key('selectionDescription.improvementSprite'),
        type: assetIcon.fieldImprovementType!,
        eraColumn: assetIcon.fieldImprovementEraColumn ?? 0,
        size: width,
        width: width,
        height: height,
        fallback: GameIcon(
          GameIcons.improvement,
          size: compact ? GameIconSize.regular : GameIconSize.large,
          color: fallbackColor,
        ),
      );
    }

    if (assetIcon.isCity) {
      return CitySpriteIcon(
        key: const Key('selectionDescription.citySprite'),
        visualLevel: assetIcon.cityVisualLevel ?? 0,
        technologyProfileIndex: assetIcon.cityTechnologyProfileIndex ?? 0,
        size: width,
        width: width,
        height: height,
        fallback: GameIcon(
          GameIcons.cityFilled,
          size: compact ? GameIconSize.regular : GameIconSize.large,
          color: fallbackColor,
        ),
      );
    }

    return SizedBox(width: width, height: height);
  }
}
