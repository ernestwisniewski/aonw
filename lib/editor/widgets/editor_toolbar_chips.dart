import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/rendering/terrain_theme.dart';
import 'package:flutter/material.dart';

class EditorTerrainChip extends StatelessWidget {
  final TerrainType terrain;
  final bool selected;
  final VoidCallback onTap;

  const EditorTerrainChip({
    required this.terrain,
    required this.selected,
    required this.onTap,
    super.key,
  });

  static const Map<TerrainType, String> _labels = {
    TerrainType.ocean: 'Ocean',
    TerrainType.coast: 'Coast',
    TerrainType.lake: 'Lake',
    TerrainType.plains: 'Plains',
    TerrainType.grassland: 'Grass',
    TerrainType.desert: 'Desert',
    TerrainType.tundra: 'Tundra',
    TerrainType.snow: 'Snow',
    TerrainType.mountain: 'Mount.',
    TerrainType.hills: 'Hills',
    TerrainType.wetlands: 'Wetland',
    TerrainType.jungle: 'Jungle',
    TerrainType.forest: 'Forest',
    TerrainType.river: 'River',
  };

  @override
  Widget build(BuildContext context) {
    final color = TerrainTheme.topColor(terrain, null);
    final label = _labels[terrain] ?? terrain.name;
    final icon = TerrainTheme.icon(terrain);

    return Tooltip(
      message: selected ? '$label zaznaczone' : 'Zaznacz $label',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(right: 4),
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: selected ? color : color.withAlpha(150),
            borderRadius: BorderRadius.circular(5),
            border: selected
                ? Border.all(color: Colors.white.withAlpha(200), width: 2)
                : Border.all(color: Colors.transparent, width: 2),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withAlpha(100),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                icon,
                width: 16,
                height: 16,
                color: selected ? null : Colors.white.withAlpha(180),
                colorBlendMode: BlendMode.modulate,
                errorBuilder: (context, e, stack) => Icon(
                  Icons.landscape,
                  size: 16,
                  color: selected ? _contrastColor(color) : Colors.white54,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? _contrastColor(color)
                      : Colors.white.withAlpha(200),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditorResourceChip extends StatelessWidget {
  final String label;
  final Color color;
  final String? iconPath;
  final bool selected;
  final VoidCallback onTap;

  const EditorResourceChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.iconPath,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selected ? '$label zaznaczone' : 'Zaznacz $label',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(right: 4),
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(230) : color.withAlpha(80),
            borderRadius: BorderRadius.circular(5),
            border: selected
                ? Border.all(color: Colors.white.withAlpha(200), width: 2)
                : Border.all(color: color.withAlpha(120)),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withAlpha(100),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconPath != null)
                Image.asset(
                  iconPath!,
                  width: 16,
                  height: 16,
                  color: selected ? null : Colors.white.withAlpha(180),
                  colorBlendMode: BlendMode.modulate,
                  errorBuilder: (context, e, stack) => Icon(
                    Icons.category,
                    size: 16,
                    color: selected ? _contrastColor(color) : Colors.white54,
                  ),
                )
              else
                Icon(
                  Icons.block,
                  size: 16,
                  color: selected ? _contrastColor(color) : Colors.white54,
                ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? _contrastColor(color)
                      : Colors.white.withAlpha(200),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _contrastColor(Color color) =>
    color.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;
