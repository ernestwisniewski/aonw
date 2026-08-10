import 'package:aonw/editor/widgets/editor_toolbar_chips.dart';
import 'package:aonw/editor/widgets/editor_toolbar_row.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';

class EditorTerrainToolbarSection extends StatelessWidget {
  final Set<TerrainType> selectedTerrains;
  final ValueChanged<TerrainType> onToggleTerrain;

  const EditorTerrainToolbarSection({
    required this.selectedTerrains,
    required this.onToggleTerrain,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return EditorToolbarRow(
      label: 'TERRAIN',
      icon: Icons.landscape,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: TerrainType.values.map((terrain) {
            return EditorTerrainChip(
              terrain: terrain,
              selected: selectedTerrains.contains(terrain),
              onTap: () => onToggleTerrain(terrain),
            );
          }).toList(),
        ),
      ),
    );
  }
}
