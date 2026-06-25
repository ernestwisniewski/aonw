import 'package:aonw/game/presentation/providers/map_inspection_provider.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_chip_id.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preview tile starts a transient inspection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(mapInspectionControllerProvider.notifier).previewTile(_tile);

    final state = container.read(mapInspectionControllerProvider);
    expect(state.active, isTrue);
    expect(state.previewing, isTrue);
    expect(state.openChipId, SelectionInfoChipId.description);
    expect(state.selection?.tile?.col, 2);
    expect(state.selection?.tile?.row, 1);
  });

  test('confirming preview keeps the inspection open', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const anchor = Offset(120, 160);
    container
        .read(mapInspectionControllerProvider.notifier)
        .previewTile(_tile, anchor: anchor);
    container.read(mapInspectionControllerProvider.notifier).confirmPreview();

    final state = container.read(mapInspectionControllerProvider);
    expect(state.active, isTrue);
    expect(state.previewing, isFalse);
    expect(state.anchor, anchor);
    expect(state.selection?.tile?.col, 2);
    expect(state.selection?.tile?.row, 1);
  });

  test('tile inspection carries map objective progress through preview', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const objective = MapObjectiveProgress(
      definition: MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: CityHex(col: 2, row: 1),
        requiredHoldTurns: 3,
      ),
      controllingPlayerId: 'player_1',
      holdTurns: 2,
    );

    container
        .read(mapInspectionControllerProvider.notifier)
        .previewTile(_tile, objectiveProgress: objective);
    container.read(mapInspectionControllerProvider.notifier).confirmPreview();

    final state = container.read(mapInspectionControllerProvider);
    expect(state.objectiveProgress?.definition.id, 'pass_1');
    expect(state.objectiveProgress?.holdTurns, 2);
    expect(state.previewing, isFalse);
  });

  test('objective inspection opens without a tile selection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const objective = MapObjectiveProgress(
      definition: MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: CityHex(col: 2, row: 1),
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

  test('canceling preview clears only transient inspection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(mapInspectionControllerProvider.notifier).previewTile(_tile);
    container.read(mapInspectionControllerProvider.notifier).cancelPreview();

    expect(container.read(mapInspectionControllerProvider).active, isFalse);
  });

  test('regular inspection is not previewing', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const anchor = Offset(80, 90);
    container
        .read(mapInspectionControllerProvider.notifier)
        .inspectTile(_tile, anchor: anchor);

    final state = container.read(mapInspectionControllerProvider);
    expect(state.active, isTrue);
    expect(state.previewing, isFalse);
    expect(state.anchor, anchor);
    expect(state.anchored, isTrue);
  });
}

const _tile = TileData(
  col: 2,
  row: 1,
  terrains: [TerrainType.grassland],
  resources: [],
  height: 0,
);
