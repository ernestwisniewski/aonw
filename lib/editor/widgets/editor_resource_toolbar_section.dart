import 'package:aonw/editor/widgets/editor_toolbar_chips.dart';
import 'package:aonw/editor/widgets/editor_toolbar_row.dart';
import 'package:aonw/map/rendering/terrain_theme.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';

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
