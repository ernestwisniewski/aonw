import 'package:aonw/game/presentation/widgets/hud/hud_long_press_info_sheet.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_selection_context_metrics.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_selection_context_title.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/city_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/field_improvement_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

export 'package:aonw/game/presentation/widgets/hud/hud_selection_context_metrics.dart';

class SelectionContextSurface extends StatelessWidget {
  const SelectionContextSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      widthFactor: 1,
      heightFactor: 1,
      child: DecoratedBox(
        key: const Key('hudActionDeck.selectionSurface'),
        decoration: SurfaceElevation.flat.decoration(
          accent: GameUiTheme.gold,
          border: BorderEmphasis.regular,
          borderWidth: 1,
          shape: SurfaceShape.button,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: HudSelectionContextMetrics.verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}

class SelectionContextLine extends StatelessWidget {
  const SelectionContextLine({
    required this.selection,
    required this.onChipTap,
    super.key,
  });

  final SelectionViewModel selection;
  final ValueChanged<String> onChipTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visibleChips = [
      for (final chip in SelectionInfoChipsFactory.chipsFor(
        selection,
        l10n: l10n,
      ))
        if (chip.enabled) chip,
    ].take(4).toList();

    return SizedBox(
      key: const Key('hudActionDeck.line.context'),
      height: HudSelectionContextMetrics.lineHeightFor(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 560.0;
          final chipsMaxWidth = visibleChips.isEmpty
              ? 0.0
              : (maxWidth * 0.38).clamp(120.0, 260.0).toDouble();
          final iconSize = HudSelectionContextMetrics.assetIconSizeFor(context);
          final textMaxWidth =
              (maxWidth -
                      iconSize -
                      HudSelectionContextMetrics.iconGap -
                      (visibleChips.isEmpty
                          ? 0
                          : chipsMaxWidth +
                                HudSelectionContextMetrics.chipsGap))
                  .clamp(120.0, 340.0)
                  .toDouble();

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SelectionContextAssetIcon(selection: selection),
              const SizedBox(width: HudSelectionContextMetrics.iconGap),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: textMaxWidth),
                child: SelectionContextTitle(
                  title: selection.title,
                  subtitle: selection.subtitle,
                ),
              ),
              if (visibleChips.isNotEmpty) ...[
                const SizedBox(width: HudSelectionContextMetrics.chipsGap),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: chipsMaxWidth),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < visibleChips.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          _ContextInfoToken(
                            chip: visibleChips[i],
                            onTap: () => onChipTap(visibleChips[i].id),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SelectionContextAssetIcon extends StatelessWidget {
  const _SelectionContextAssetIcon({required this.selection});

  final SelectionViewModel selection;

  @override
  Widget build(BuildContext context) {
    final assetIcon = selection.assetIcon;
    final size = HudSelectionContextMetrics.assetIconSizeFor(context);
    final unitType = assetIcon?.unitType;
    if (unitType != null) {
      return UnitSpriteIcon(
        key: const Key('hudActionDeck.selectionAssetIcon.unit'),
        type: unitType,
        size: size,
        fallback: _fallbackIcon,
      );
    }

    if (assetIcon?.isCity ?? false) {
      return CitySpriteIcon(
        key: const Key('hudActionDeck.selectionAssetIcon.city'),
        visualLevel: assetIcon!.cityVisualLevel ?? 0,
        technologyProfileIndex: assetIcon.cityTechnologyProfileIndex ?? 0,
        size: size,
        fallback: _fallbackIcon,
      );
    }

    if (assetIcon?.isFieldImprovement ?? false) {
      return FieldImprovementSpriteIcon(
        key: const Key('hudActionDeck.selectionAssetIcon.improvement'),
        type: assetIcon!.fieldImprovementType!,
        eraColumn: assetIcon.fieldImprovementEraColumn ?? 0,
        size: size,
        fallback: _fallbackIcon,
      );
    }

    return SizedBox.square(
      dimension: size,
      child: Center(child: _fallbackIcon),
    );
  }

  Widget get _fallbackIcon {
    return GameIcon(
      selection.icon,
      size: GameIconSize.small,
      color: selection.color,
    );
  }
}

class _ContextInfoToken extends StatelessWidget {
  const _ContextInfoToken({required this.chip, required this.onTap});

  final SelectionInfoChipViewModel chip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final toneColor = switch (chip.tone) {
      SelectionInfoChipTone.accent => GameUiTheme.goldLight,
      SelectionInfoChipTone.warning => GameUiTheme.warning,
      SelectionInfoChipTone.neutral => GameUiTheme.textSecondary,
    };
    final label = chip.badge == null
        ? chip.label
        : '${chip.label} ${chip.badge}';

    return Tooltip(
      message: chip.label,
      triggerMode: TooltipTriggerMode.manual,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: () => showHudLongPressInfoSheet(
          context: context,
          icon: chip.icon,
          title: chip.label,
          body: _descriptionFor(l10n, chip),
          accent: toneColor,
          actionLabel: chip.enabled ? l10n.commonOpenAction : null,
          onAction: chip.enabled ? onTap : null,
        ),
        child: Container(
          key: Key('hudActionDeck.context.${chip.id}'),
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: SurfaceElevation.flat.decoration(
            accent: toneColor,
            backgroundAlpha: 96,
            border: BorderEmphasis.regular,
            shape: SurfaceShape.pill,
            includeShadow: false,
          ),
          child: Text(
            label,
            maxLines: 1,
            style: GameHudTheme.selectionTag.copyWith(
              color: toneColor,
              fontSize: 10.5,
            ),
          ),
        ),
      ),
    );
  }

  String _descriptionFor(
    AppLocalizations l10n,
    SelectionInfoChipViewModel chip,
  ) {
    final badge = chip.badge == null
        ? ''
        : l10n.selectionChipBadgeSuffix(chip.badge!);
    if (!chip.enabled) {
      return l10n.selectionChipDisabledDescription(badge);
    }
    return l10n.selectionChipOpenDescription(chip.label, badge);
  }
}
