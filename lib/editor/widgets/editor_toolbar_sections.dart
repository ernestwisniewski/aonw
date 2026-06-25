import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/editor/widgets/editor_action_button.dart';
import 'package:aonw/editor/widgets/editor_color_picker.dart';
import 'package:aonw/editor/widgets/editor_toolbar_chips.dart';
import 'package:aonw/editor/widgets/editor_toolbar_row.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/rendering/terrain_theme.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/objective.dart';
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

class EditorResourceToolbarSection extends StatelessWidget {
  final Set<ResourceType> selectedResources;
  final ValueChanged<ResourceType> onToggleResource;

  const EditorResourceToolbarSection({
    required this.selectedResources,
    required this.onToggleResource,
    super.key,
  });

  static const _bonusResources = [
    ResourceType.wheat,
    ResourceType.fish,
    ResourceType.deer,
    ResourceType.sheep,
    ResourceType.rice,
    ResourceType.cow,
    ResourceType.apple,
    ResourceType.banana,
    ResourceType.citrus,
  ];

  static const _luxuryResources = [
    ResourceType.gold,
    ResourceType.silver,
    ResourceType.gems,
    ResourceType.silk,
    ResourceType.spices,
    ResourceType.cotton,
    ResourceType.grapes,
    ResourceType.ivory,
    ResourceType.pearls,
    ResourceType.coffee,
    ResourceType.cocoa,
    ResourceType.tobacco,
    ResourceType.sugar,
  ];

  static const _strategicResources = [
    ResourceType.iron,
    ResourceType.coal,
    ResourceType.oil,
    ResourceType.aluminium,
    ResourceType.uranium,
    ResourceType.horses,
    ResourceType.marble,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResourceGroup(
          label: 'BONUS',
          icon: Icons.eco,
          resources: _bonusResources,
          selectedResources: selectedResources,
          onToggleResource: onToggleResource,
        ),
        _ResourceGroup(
          label: 'LUXURY',
          icon: Icons.diamond_outlined,
          resources: _luxuryResources,
          selectedResources: selectedResources,
          onToggleResource: onToggleResource,
        ),
        _ResourceGroup(
          label: 'STRATEGIC',
          icon: Icons.bolt,
          resources: _strategicResources,
          selectedResources: selectedResources,
          onToggleResource: onToggleResource,
        ),
      ],
    );
  }
}

class _ResourceGroup extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<ResourceType> resources;
  final Set<ResourceType> selectedResources;
  final ValueChanged<ResourceType> onToggleResource;

  const _ResourceGroup({
    required this.label,
    required this.icon,
    required this.resources,
    required this.selectedResources,
    required this.onToggleResource,
  });

  static const Map<ResourceType, String> _labels = {
    ResourceType.wheat: 'Wheat',
    ResourceType.fish: 'Fish',
    ResourceType.deer: 'Deer',
    ResourceType.sheep: 'Sheep',
    ResourceType.rice: 'Rice',
    ResourceType.cow: 'Cattle',
    ResourceType.apple: 'Apple',
    ResourceType.banana: 'Banana',
    ResourceType.citrus: 'Citrus',
    ResourceType.gold: 'Gold',
    ResourceType.silver: 'Silver',
    ResourceType.gems: 'Gems',
    ResourceType.silk: 'Silk',
    ResourceType.spices: 'Spices',
    ResourceType.cotton: 'Cotton',
    ResourceType.grapes: 'Grapes',
    ResourceType.ivory: 'Ivory',
    ResourceType.pearls: 'Pearls',
    ResourceType.coffee: 'Coffee',
    ResourceType.cocoa: 'Cocoa',
    ResourceType.tobacco: 'Tobacco',
    ResourceType.sugar: 'Sugar',
    ResourceType.iron: 'Iron',
    ResourceType.coal: 'Coal',
    ResourceType.oil: 'Oil',
    ResourceType.aluminium: 'Alumin.',
    ResourceType.uranium: 'Uranium',
    ResourceType.horses: 'Horses',
    ResourceType.marble: 'Marble',
  };

  @override
  Widget build(BuildContext context) {
    return EditorToolbarRow(
      label: label,
      icon: icon,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: resources.map((resource) {
            final dotColor =
                TerrainTheme.resourceDotColors[resource] ??
                const Color(0xFF555566);
            return EditorResourceChip(
              label: _labels[resource] ?? resource.name,
              color: dotColor,
              iconPath: TerrainTheme.resourceIcons[resource],
              selected: selectedResources.contains(resource),
              onTap: () => onToggleResource(resource),
            );
          }).toList(),
        ),
      ),
    );
  }
}

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

class EditorHeightToolbarSection extends StatelessWidget {
  final int selectedHeight;
  final bool showHeightBadge;
  final VoidCallback onToggleHeightBadge;
  final ValueChanged<int> onHeightChanged;

  const EditorHeightToolbarSection({
    required this.selectedHeight,
    required this.showHeightBadge,
    required this.onToggleHeightBadge,
    required this.onHeightChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return EditorToolbarRow(
      label: 'HEIGHT',
      icon: Icons.terrain,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _HeightBadgeToggle(
              active: showHeightBadge,
              onTap: onToggleHeightBadge,
            ),
            const SizedBox(width: 6),
            EditorActionButton(
              '-',
              selectedHeight > 0
                  ? () => onHeightChanged(selectedHeight - 1)
                  : null,
            ),
            Container(
              width: 32,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GameUiTheme.chipSurface,
                borderRadius: GameUiTheme.chipBorderRadius,
              ),
              child: Text(
                '$selectedHeight',
                style: const TextStyle(
                  color: GameUiTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            EditorActionButton(
              '+',
              selectedHeight < 5
                  ? () => onHeightChanged(selectedHeight + 1)
                  : null,
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(6, (height) {
                  final active = height == selectedHeight;
                  return Container(
                    width: 10,
                    height: 10 + height * 3.0,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: active
                          ? GameUiTheme.accent
                          : GameUiTheme.chipSurfaceDim,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditorStyleToolbarSection extends StatelessWidget {
  final HexDisplaySettings displaySettings;
  final double defaultZoom;
  final ValueChanged<Color> onHexBorderColorChanged;
  final ValueChanged<Color> onSelectedHexColorChanged;
  final ValueChanged<Color> onWallTintColorChanged;
  final ValueChanged<double> onDefaultZoomChanged;

  const EditorStyleToolbarSection({
    required this.displaySettings,
    required this.defaultZoom,
    required this.onHexBorderColorChanged,
    required this.onSelectedHexColorChanged,
    required this.onWallTintColorChanged,
    required this.onDefaultZoomChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return EditorToolbarRow(
      label: 'STYLE',
      icon: Icons.palette,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EditorColorPickerButton(
              label: 'Border',
              color: displaySettings.hexBorderColor,
              onPicked: onHexBorderColorChanged,
            ),
            const SizedBox(width: 6),
            EditorColorPickerButton(
              label: 'Select',
              color: displaySettings.selectedHexColor,
              onPicked: onSelectedHexColorChanged,
            ),
            const SizedBox(width: 6),
            EditorColorPickerButton(
              label: 'Wall',
              color: displaySettings.wallTintColor,
              onPicked: onWallTintColorChanged,
            ),
            const SizedBox(width: 12),
            _DefaultZoomControl(
              zoom: defaultZoom,
              onChanged: onDefaultZoomChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultZoomControl extends StatelessWidget {
  final double zoom;
  final ValueChanged<double> onChanged;

  const _DefaultZoomControl({required this.zoom, required this.onChanged});

  static const double _step = 0.25;
  static const double _min = 0.25;
  static const double _max = 4.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('ZOOM', style: GameUiTheme.chipLabel),
        const SizedBox(width: 4),
        EditorActionButton(
          '−',
          zoom > _min
              ? () => onChanged((zoom - _step).clamp(_min, _max))
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            '${zoom.toStringAsFixed(zoom.truncateToDouble() == zoom ? 0 : 2)}×',
            style: const TextStyle(
              color: GameUiTheme.textPrimary,
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        EditorActionButton(
          '+',
          zoom < _max
              ? () => onChanged((zoom + _step).clamp(_min, _max))
              : null,
        ),
      ],
    );
  }
}

class _HeightBadgeToggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _HeightBadgeToggle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Show height on map',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active
                ? GameUiTheme.accent.withAlpha(60)
                : GameUiTheme.chipSurface,
            borderRadius: GameUiTheme.chipBorderRadius,
            border: Border.all(
              color: active ? GameUiTheme.accent : GameUiTheme.border,
            ),
          ),
          child: Icon(
            Icons.format_list_numbered,
            size: 14,
            color: active ? GameUiTheme.accent : GameUiTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
