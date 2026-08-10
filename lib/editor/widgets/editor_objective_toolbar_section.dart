import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/editor/widgets/editor_toolbar_chips.dart';
import 'package:aonw/editor/widgets/editor_toolbar_row.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter/material.dart';

class EditorObjectiveToolbarSection extends StatelessWidget {
  final MapObjectiveType? selectedObjectiveType;
  final EditorObjectivePaintMode objectivePaintMode;
  final ValueChanged<MapObjectiveType> onSelectObjective;
  final VoidCallback onEraseObjective;
  final VoidCallback onClearObjectiveTool;

  const EditorObjectiveToolbarSection({
    required this.selectedObjectiveType,
    required this.objectivePaintMode,
    required this.onSelectObjective,
    required this.onEraseObjective,
    required this.onClearObjectiveTool,
    super.key,
  });

  static const Map<MapObjectiveType, String> _labels = {
    MapObjectiveType.ruins: 'Ruins',
    MapObjectiveType.strategicPass: 'Pass',
    MapObjectiveType.holySite: 'Holy',
    MapObjectiveType.legendaryResource: 'Legend',
  };

  static const Map<MapObjectiveType, Color> _colors = {
    MapObjectiveType.ruins: Color(0xFFD1B894),
    MapObjectiveType.strategicPass: Color(0xFFA7B8D9),
    MapObjectiveType.holySite: Color(0xFFDDBB61),
    MapObjectiveType.legendaryResource: Color(0xFF72C6A3),
  };

  @override
  Widget build(BuildContext context) {
    return EditorToolbarRow(
      label: 'OBJECTIVES',
      icon: Icons.change_history,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in MapObjectiveType.values)
              EditorResourceChip(
                label: _labels[type] ?? type.name,
                color: _colors[type] ?? GameUiTheme.accent,
                selected:
                    objectivePaintMode == EditorObjectivePaintMode.place &&
                    selectedObjectiveType == type,
                onTap: () => onSelectObjective(type),
              ),
            EditorResourceChip(
              label: 'Erase',
              color: const Color(0xFFB36B6B),
              selected: objectivePaintMode == EditorObjectivePaintMode.erase,
              onTap: onEraseObjective,
            ),
            EditorResourceChip(
              label: 'Off',
              color: GameUiTheme.textSecondary,
              selected: objectivePaintMode == EditorObjectivePaintMode.none,
              onTap: onClearObjectiveTool,
            ),
          ],
        ),
      ),
    );
  }
}
