import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/field_improvement_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter/material.dart';

class WorkerActionSelectionDetailContent extends StatelessWidget {
  const WorkerActionSelectionDetailContent({
    required this.model,
    required this.compact,
    this.onSelectImprovement,
    this.onConfirmImprovement,
    this.onCancelWorkerActionSelection,
    super.key,
  });

  final WorkerActionSelectionDetail model;
  final bool compact;
  final void Function(String unitId, FieldImprovementType type)?
  onSelectImprovement;
  final ValueChanged<String>? onConfirmImprovement;
  final ValueChanged<String>? onCancelWorkerActionSelection;

  @override
  Widget build(BuildContext context) {
    final workerAction = model.workerAction;
    final selected = workerAction.selectedOption;
    final canConfirm = selected != null && selected.buildable;
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.maxHeight.isFinite;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            _WorkerBuildHeader(selected: selected, compact: compact),
            SizedBox(height: compact ? 10 : 12),
            if (boundedHeight)
              Expanded(
                child: SingleChildScrollView(
                  key: const Key('selectionInfo.workerBuild.optionsList'),
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final option in workerAction.options) ...[
                        _WorkerImprovementOptionTile(
                          key: Key(
                            'selectionInfo.workerBuild.option.${option.improvementType.name}',
                          ),
                          option: option,
                          compact: compact,
                          onTap: option.buildable
                              ? () => onSelectImprovement?.call(
                                  workerAction.unitId,
                                  option.improvementType,
                                )
                              : null,
                        ),
                        if (option != workerAction.options.last)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              )
            else
              for (final option in workerAction.options) ...[
                _WorkerImprovementOptionTile(
                  key: Key(
                    'selectionInfo.workerBuild.option.${option.improvementType.name}',
                  ),
                  option: option,
                  compact: compact,
                  onTap: option.buildable
                      ? () => onSelectImprovement?.call(
                          workerAction.unitId,
                          option.improvementType,
                        )
                      : null,
                ),
                const SizedBox(height: 8),
              ],
            SizedBox(height: compact ? 8 : 10),
            _ConfirmButton(
              selected: selected,
              canConfirm: canConfirm,
              onPressed: canConfirm
                  ? () => onConfirmImprovement?.call(workerAction.unitId)
                  : null,
            ),
            SizedBox(height: compact ? 6 : 8),
            _CancelButton(
              onPressed: () =>
                  onCancelWorkerActionSelection?.call(workerAction.unitId),
            ),
          ],
        );
        if (!boundedHeight) return content;
        return SizedBox(height: constraints.maxHeight, child: content);
      },
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        key: const Key('selectionInfo.workerBuild.cancel'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: SurfaceElevation.flat.fill(
            background: GameUiTheme.chipSurface,
            alpha: 128,
          ),
          foregroundColor: GameUiTheme.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const GameIcon(
          GameIcons.close,
          size: GameIconSize.small,
          color: GameUiTheme.textSecondary,
        ),
        label: Text(
          AppLocalizations.of(context).cancelAction,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.actionLabel.copyWith(
            color: GameUiTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _WorkerBuildHeader extends StatelessWidget {
  const _WorkerBuildHeader({required this.selected, required this.compact});

  final WorkerImprovementOptionViewModel? selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BuildIcon(compact: compact),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selected == null
                    ? l10n.workerActionSelectImprovement
                    : l10n.workerActionSelectedImprovement(selected!.title),
                style: GameHudTheme.selectionTitle,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.workerActionSelectionHint,
                style: GameHudTheme.selectionSubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BuildIcon extends StatelessWidget {
  const _BuildIcon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 34 : 38,
      height: compact ? 34 : 38,
      alignment: Alignment.center,
      decoration: SurfaceElevation.flat.decoration(
        accent: GameHudTheme.success,
        backgroundAlpha: 95,
        border: BorderEmphasis.regular,
        shape: SurfaceShape.chip,
      ),
      child: const GameIcon(
        GameIcons.improvement,
        size: GameIconSize.regular,
        color: GameHudTheme.success,
      ),
    );
  }
}

class _WorkerImprovementOptionTile extends StatelessWidget {
  const _WorkerImprovementOptionTile({
    required this.option,
    required this.compact,
    required this.onTap,
    super.key,
  });

  final WorkerImprovementOptionViewModel option;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = option.selected;
    final blocked = option.blocked;
    final accent = blocked
        ? GameUiTheme.textMuted
        : selected
        ? GameUiTheme.goldLight
        : option.recommended
        ? GameUiTheme.success
        : GameUiTheme.gold;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: DecoratedBox(
          decoration: SurfaceElevation.flat.decoration(
            accent: accent,
            backgroundAlpha: selected ? 104 : 54,
            border: selected ? BorderEmphasis.strong : BorderEmphasis.regular,
            shape: SurfaceShape.card,
            includeShadow: false,
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 9 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: blocked ? 0.45 : 1,
                  child: FieldImprovementSpriteIcon(
                    type: option.improvementType,
                    size: compact ? 34 : 40,
                    fallback: GameIcon(
                      GameIcons.improvement,
                      size: GameIconSize.small,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GameHudTheme.selectionTag.copyWith(
                                color: blocked
                                    ? GameUiTheme.textMuted
                                    : GameUiTheme.textBright,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatePill(option: option),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          ..._yieldChips(context, option.yield),
                          _InfoChip(
                            label: l10n.turnCountLabel(option.buildTurns),
                            color: GameUiTheme.textSecondary,
                          ),
                        ],
                      ),
                      if (option.reason.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          option.reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GameHudTheme.selectionSubtitle.copyWith(
                            color: blocked
                                ? GameUiTheme.warning
                                : GameUiTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static List<Widget> _yieldChips(BuildContext context, TileYield yield) {
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[];
    if (yield.food != 0) {
      chips.add(
        _InfoChip(
          label: _signed(yield.food, l10n.yieldFoodShort),
          color: GameUiTheme.success,
        ),
      );
    }
    if (yield.production != 0) {
      chips.add(
        _InfoChip(
          label: _signed(yield.production, l10n.yieldProductionShort),
          color: GameUiTheme.gold,
        ),
      );
    }
    if (yield.gold != 0) {
      chips.add(
        _InfoChip(
          label: _signed(yield.gold, l10n.yieldGoldShort),
          color: GameUiTheme.resourcesAccent,
        ),
      );
    }
    if (yield.defense != 0) {
      chips.add(
        _InfoChip(
          label: _signed(yield.defense, l10n.yieldDefenseShort),
          color: GameUiTheme.info,
        ),
      );
    }
    if (chips.isEmpty) {
      chips.add(
        _InfoChip(
          label: l10n.workerActionNoYieldChange,
          color: GameUiTheme.textMuted,
        ),
      );
    }
    return chips;
  }

  static String _signed(int value, String suffix) {
    return '${value > 0 ? '+' : ''}$value $suffix';
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.option});

  final WorkerImprovementOptionViewModel option;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (:label, :color) = switch (option.state) {
      WorkerImprovementOptionState.selected => (
        label: l10n.commonSelectedAction,
        color: GameUiTheme.goldLight,
      ),
      WorkerImprovementOptionState.recommended => (
        label: l10n.cityBuildingSortRecommended,
        color: GameHudTheme.success,
      ),
      WorkerImprovementOptionState.available => (
        label: l10n.commonAvailable,
        color: GameUiTheme.gold,
      ),
      WorkerImprovementOptionState.blocked => (
        label: l10n.commonBlocked,
        color: GameUiTheme.textMuted,
      ),
    };
    return _InfoChip(label: label, color: color);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        accent: color,
        backgroundAlpha: 58,
        border: BorderEmphasis.subtle,
        shape: SurfaceShape.pill,
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          maxLines: 1,
          style: GameHudTheme.selectionTag.copyWith(color: color, fontSize: 10),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.selected,
    required this.canConfirm,
    required this.onPressed,
  });

  final WorkerImprovementOptionViewModel? selected;
  final bool canConfirm;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = selected == null
        ? l10n.workerActionSelectImprovement
        : l10n.workerActionBuildImprovement(selected!.title);
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        key: const Key('selectionInfo.workerBuild.confirm'),
        onPressed: canConfirm ? onPressed : null,
        style: TextButton.styleFrom(
          backgroundColor: canConfirm
              ? GameUiTheme.gold
              : SurfaceElevation.flat.fill(
                  background: GameUiTheme.chipSurface,
                  alpha: 150,
                ),
          foregroundColor: canConfirm ? GameUiTheme.bg : GameUiTheme.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: GameIcon(
          GameIcons.production,
          size: GameIconSize.small,
          color: canConfirm ? GameUiTheme.bg : GameUiTheme.textMuted,
        ),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.actionLabel.copyWith(
            color: canConfirm ? GameUiTheme.bg : GameUiTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
