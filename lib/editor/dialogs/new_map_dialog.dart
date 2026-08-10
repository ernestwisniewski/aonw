import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/map/domain/map_constraints.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';

typedef NewMapDialogResult = ({int cols, int rows, TerrainType defaultTerrain});

Future<NewMapDialogResult?> showNewMapDialog(BuildContext context) {
  int cols = 10;
  int rows = 8;
  TerrainType defaultTerrain = TerrainType.ocean;

  return showGameModal<NewMapDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => GameModalScaffold(
        header: const GameModalHeader(title: 'New Map'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogSlider(
              label: 'Columns: $cols',
              value: cols.toDouble(),
              min: MapConstraints.minCols.toDouble(),
              max: MapConstraints.maxCols.toDouble(),
              onChanged: (value) => setDialogState(() => cols = value.round()),
            ),
            _DialogSlider(
              label: 'Rows: $rows',
              value: rows.toDouble(),
              min: MapConstraints.minRows.toDouble(),
              max: MapConstraints.maxRows.toDouble(),
              onChanged: (value) => setDialogState(() => rows = value.round()),
            ),
            const SizedBox(height: 8),
            DropdownButton<TerrainType>(
              value: defaultTerrain,
              dropdownColor: GameUiTheme.bg,
              style: const TextStyle(color: GameUiTheme.textPrimary),
              items: TerrainType.values
                  .map(
                    (terrain) => DropdownMenuItem(
                      value: terrain,
                      child: Text(terrain.name),
                    ),
                  )
                  .toList(),
              onChanged: (terrain) =>
                  setDialogState(() => defaultTerrain = terrain!),
            ),
          ],
        ),
        actions: [
          GameModalAction(
            label: 'CREATE',
            variant: EpicButtonVariant.primary,
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop((cols: cols, rows: rows, defaultTerrain: defaultTerrain)),
          ),
        ],
      ),
    ),
  );
}

class _DialogSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _DialogSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: GameUiTheme.textPrimary, fontSize: 13),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
