import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/editor/providers/editor_providers.dart';
import 'package:aonw/map/domain/map_constraints.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorStateNotifier', () {
    test('initial state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(editorStateProvider);
      expect(state.selectedTerrains, {TerrainType.ocean});
      expect(state.selectedHeight, 0);
      expect(state.heightActive, false);
      expect(state.selectedResources, isEmpty);
      expect(state.selectedObjectiveType, isNull);
      expect(state.objectivePaintMode, EditorObjectivePaintMode.none);
    });

    test('toggleTerrain adds terrain when not selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(editorStateProvider.notifier)
          .toggleTerrain(TerrainType.grassland);
      expect(
        container.read(editorStateProvider).selectedTerrains,
        containsAll([TerrainType.ocean, TerrainType.grassland]),
      );
    });

    test('toggleTerrain removes terrain when already selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(editorStateProvider.notifier)
          .toggleTerrain(TerrainType.ocean);
      expect(
        container.read(editorStateProvider).selectedTerrains,
        isNot(contains(TerrainType.ocean)),
      );
    });

    test('toggleResource adds resource when not selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(editorStateProvider.notifier)
          .toggleResource(ResourceType.iron);
      expect(
        container.read(editorStateProvider).selectedResources,
        contains(ResourceType.iron),
      );
    });

    test('toggleResource removes resource when already selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(editorStateProvider.notifier)
          .toggleResource(ResourceType.iron);
      container
          .read(editorStateProvider.notifier)
          .toggleResource(ResourceType.iron);
      expect(
        container.read(editorStateProvider).selectedResources,
        isNot(contains(ResourceType.iron)),
      );
    });

    test('setHeight sets heightActive true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorStateProvider.notifier).setHeight(3);
      final state = container.read(editorStateProvider);
      expect(state.selectedHeight, 3);
      expect(state.heightActive, true);
    });

    test('setHeight clamps to 0-5', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorStateProvider.notifier).setHeight(99);
      expect(container.read(editorStateProvider).selectedHeight, 5);
      container.read(editorStateProvider.notifier).setHeight(-5);
      expect(container.read(editorStateProvider).selectedHeight, 0);
    });

    test('clearHeightActive sets heightActive false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorStateProvider.notifier).setHeight(2);
      container.read(editorStateProvider.notifier).clearHeightActive();
      expect(container.read(editorStateProvider).heightActive, false);
    });

    test('selectObjective enables objective placement mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(editorStateProvider.notifier)
          .selectObjective(MapObjectiveType.strategicPass);

      final state = container.read(editorStateProvider);
      expect(state.selectedObjectiveType, MapObjectiveType.strategicPass);
      expect(state.objectivePaintMode, EditorObjectivePaintMode.place);
    });

    test('eraseObjective enables objective erase mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorStateProvider.notifier).eraseObjective();

      final state = container.read(editorStateProvider);
      expect(state.selectedObjectiveType, isNull);
      expect(state.objectivePaintMode, EditorObjectivePaintMode.erase);
    });

    test('syncToTile sets terrains, resources, height', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(editorStateProvider.notifier)
          .syncToTile(
            terrains: [TerrainType.desert, TerrainType.hills],
            resources: [ResourceType.iron],
            objectiveType: MapObjectiveType.holySite,
            height: 3,
          );
      final state = container.read(editorStateProvider);
      expect(state.selectedTerrains, {TerrainType.desert, TerrainType.hills});
      expect(state.selectedResources, {ResourceType.iron});
      expect(state.selectedObjectiveType, MapObjectiveType.holySite);
      expect(state.objectivePaintMode, EditorObjectivePaintMode.place);
      expect(state.selectedHeight, 3);
      expect(state.heightActive, true);
    });
  });

  group('EditorMapNotifier', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(editorMapProvider), null);
    });

    test('create populates mapData', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(editorMapProvider.notifier)
          .create(6, 5, TerrainType.ocean);
      final mapData = container.read(editorMapProvider);
      expect(mapData, isNotNull);
      expect(mapData!.cols, 6);
      expect(mapData.rows, 5);
      expect(mapData.tiles.length, 30);
      expect(mapData.tiles.first.terrains, [TerrainType.ocean]);
    });

    test('create clamps mapData to editor dimension limits', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(editorMapProvider.notifier)
          .create(99, 99, TerrainType.grassland);
      final maxMapData = container.read(editorMapProvider);

      expect(maxMapData, isNotNull);
      expect(maxMapData!.cols, MapConstraints.maxCols);
      expect(maxMapData.rows, MapConstraints.maxRows);
      expect(
        maxMapData.tiles.length,
        MapConstraints.maxCols * MapConstraints.maxRows,
      );

      container
          .read(editorMapProvider.notifier)
          .create(1, 1, TerrainType.ocean);
      final minMapData = container.read(editorMapProvider);

      expect(minMapData, isNotNull);
      expect(minMapData!.cols, MapConstraints.minCols);
      expect(minMapData.rows, MapConstraints.minRows);
      expect(
        minMapData.tiles.length,
        MapConstraints.minCols * MapConstraints.minRows,
      );
    });
  });
}
