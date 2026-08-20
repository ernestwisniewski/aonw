import 'package:aonw/game/presentation/providers/map/map_inspection_provider.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_chip_id.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tile inspection opens the description at the requested anchor', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const anchor = Offset(120, 160);
    container
        .read(mapInspectionControllerProvider.notifier)
        .inspectTile(_tile, anchor: anchor);

    final state = container.read(mapInspectionControllerProvider);
    expect(state.active, isTrue);
    expect(state.openChipId, SelectionInfoChipId.description);
    expect(state.selection?.tile?.col, 2);
    expect(state.selection?.tile?.row, 1);
    expect(state.anchor, anchor);
    expect(state.anchored, isTrue);
  });

  test('tile inspection carries map objective progress', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const objective = MapObjectiveProgress(
      definition: MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: HexCoord(col: 2, row: 1),
        requiredHoldTurns: 3,
      ),
      controllingPlayerId: 'player_1',
      holdTurns: 2,
    );

    container
        .read(mapInspectionControllerProvider.notifier)
        .inspectTile(_tile, objectiveProgress: objective);

    final state = container.read(mapInspectionControllerProvider);
    expect(state.objectiveProgress?.definition.id, 'pass_1');
    expect(state.objectiveProgress?.holdTurns, 2);
  });

  test('objective inspection opens without a tile selection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const objective = MapObjectiveProgress(
      definition: MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: HexCoord(col: 2, row: 1),
        requiredHoldTurns: 3,
      ),
      controllingPlayerId: 'player_1',
      holdTurns: 2,
    );

    container
        .read(mapInspectionControllerProvider.notifier)
        .inspectObjective(objective, anchor: const Offset(120, 160));

    final state = container.read(mapInspectionControllerProvider);
    expect(state.active, isTrue);
    expect(state.selection, isNull);
    expect(state.objectiveProgress?.definition.id, 'pass_1');
    expect(state.anchor, const Offset(120, 160));
  });

  test('clear closes the active inspection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(mapInspectionControllerProvider.notifier).inspectTile(_tile);
    container.read(mapInspectionControllerProvider.notifier).clear();

    expect(container.read(mapInspectionControllerProvider).active, isFalse);
  });
}

final _tile = WorldTile(
  col: 2,
  row: 1,
  terrains: [TerrainType.grassland],
  resources: [],
  height: 0,
);
