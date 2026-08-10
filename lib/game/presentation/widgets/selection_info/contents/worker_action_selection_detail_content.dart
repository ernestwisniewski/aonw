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

part 'worker_action_selection_controls.dart';
part 'worker_improvement_option_tile.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) => _WorkerActionSelectionLayout(
        workerAction: workerAction,
        compact: compact,
        boundedHeight: constraints.maxHeight.isFinite,
        maxHeight: constraints.maxHeight,
        onSelectImprovement: onSelectImprovement,
        onConfirmImprovement: onConfirmImprovement,
        onCancel: onCancelWorkerActionSelection,
      ),
    );
  }
}

class _WorkerActionSelectionLayout extends StatelessWidget {
  const _WorkerActionSelectionLayout({
    required this.workerAction,
    required this.compact,
    required this.boundedHeight,
    required this.maxHeight,
    required this.onSelectImprovement,
    required this.onConfirmImprovement,
    required this.onCancel,
  });

  final WorkerActionPanelViewModel workerAction;
  final bool compact;
  final bool boundedHeight;
  final double maxHeight;
  final void Function(String unitId, FieldImprovementType type)?
  onSelectImprovement;
  final ValueChanged<String>? onConfirmImprovement;
  final ValueChanged<String>? onCancel;

  @override
  Widget build(BuildContext context) {
    final selected = workerAction.selectedOption;
    final canConfirm = selected != null && selected.buildable;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _WorkerBuildHeader(selected: selected, compact: compact),
        SizedBox(height: compact ? 10 : 12),
        _WorkerImprovementOptions(
          workerAction: workerAction,
          compact: compact,
          boundedHeight: boundedHeight,
          onSelectImprovement: onSelectImprovement,
        ),
        SizedBox(height: compact ? 8 : 10),
        _ConfirmButton(
          selected: selected,
          canConfirm: canConfirm,
          onPressed: canConfirm
              ? () => onConfirmImprovement?.call(workerAction.unitId)
              : null,
        ),
        SizedBox(height: compact ? 6 : 8),
        _CancelButton(onPressed: () => onCancel?.call(workerAction.unitId)),
      ],
    );
    return boundedHeight
        ? SizedBox(height: maxHeight, child: content)
        : content;
  }
}

class _WorkerImprovementOptions extends StatelessWidget {
  const _WorkerImprovementOptions({
    required this.workerAction,
    required this.compact,
    required this.boundedHeight,
    required this.onSelectImprovement,
  });

  final WorkerActionPanelViewModel workerAction;
  final bool compact;
  final bool boundedHeight;
  final void Function(String unitId, FieldImprovementType type)?
  onSelectImprovement;

  @override
  Widget build(BuildContext context) {
    final options = Column(
      mainAxisSize: MainAxisSize.min,
      children: _optionTiles(includeTrailingGap: !boundedHeight),
    );
    if (!boundedHeight) return options;
    return Expanded(
      child: SingleChildScrollView(
        key: const Key('selectionInfo.workerBuild.optionsList'),
        padding: EdgeInsets.zero,
        child: options,
      ),
    );
  }

  List<Widget> _optionTiles({required bool includeTrailingGap}) {
    return [
      for (var index = 0; index < workerAction.options.length; index++) ...[
        _optionTile(workerAction.options[index]),
        if (includeTrailingGap || index < workerAction.options.length - 1)
          const SizedBox(height: 8),
      ],
    ];
  }

  Widget _optionTile(WorkerImprovementOptionViewModel option) {
    return _WorkerImprovementOptionTile(
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
    );
  }
}
