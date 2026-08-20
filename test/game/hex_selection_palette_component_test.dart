import 'dart:math' as math;

import 'package:aonw/game/presentation/engine/hex_selection/hex_selection_target.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/hex_selection_palette/hex_selection_palette_component.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tile = WorldTile(
    col: 1,
    row: 2,
    terrains: const [TerrainType.grassland],
    resources: const [],
    height: 0,
  );
  final target = TerrainHexSelectionTarget(tile: tile, label: 'Terrain');

  test('terrain occupies the center direction of the radial fan', () {
    final component = HexSelectionPaletteComponent(
      targets: [target],
      directionAngle: -math.pi / 2,
      onSelected: (_) {},
      onCanceled: () {},
    );

    final targetCenter = component.targetRectsForTesting.single.center;
    final paletteCenter = Offset(component.size.x / 2, component.size.y / 2);

    expect(targetCenter.dx, closeTo(paletteCenter.dx, 0.001));
    expect(targetCenter.dy, lessThan(paletteCenter.dy));
  });

  test('selecting an icon emits its typed target', () {
    HexSelectionTarget? selected;
    HexSelectionPaletteComponent(
      targets: [target],
      directionAngle: 0,
      onSelected: (value) => selected = value,
      onCanceled: () {},
    ).selectForTesting(target.key);

    expect(selected, same(target));
  });
}
