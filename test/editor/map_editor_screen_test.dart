import 'package:aonw/editor/engine/editor_world.dart';
import 'package:aonw/editor/map_editor_screen.dart';
import 'package:aonw/editor/providers/editor_providers.dart';
import 'package:aonw/editor/widgets/editor_top_bar.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/application/map_repository.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/map/rendering/hex_tile.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'loads a selected draft, syncs a tile selection, and opens save/export',
    (tester) async {
      const selection = MapSelection(
        name: 'editor_fixture',
        source: MapSource.asset,
      );
      final repository = _FakeMapRepository(
        mapData: MapData(
          cols: 1,
          rows: 1,
          mapName: 'editor_fixture',
          defaultZoom: 1.25,
          tiles: const [
            TileData(
              col: 0,
              row: 0,
              terrains: [TerrainType.hills],
              resources: [ResourceType.iron],
              height: 3,
            ),
          ],
          objectives: const [
            MapObjectiveDefinition(
              id: 'pass_0_0',
              type: MapObjectiveType.strategicPass,
              hex: HexCoord(col: 0, row: 0),
            ),
          ],
        ),
      );
      final container = ProviderContainer(
        overrides: [mapRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: '/editor/fixture',
        routes: [
          GoRoute(path: '/editor', builder: (_, _) => const SizedBox.shrink()),
          GoRoute(
            path: '/editor/fixture',
            builder: (_, _) => const MapEditorScreen(selection: selection),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await _pumpUntil(tester, find.byType(EditorTopBar));

      final draft = container.read(editorMapProvider);
      expect(draft, isNotNull);
      expect(draft!.mapName, 'editor_fixture');
      expect(draft.defaultZoom, 1.25);

      final gameFinder = find.byWidgetPredicate(
        (widget) => widget is GameWidget<EditorWorld>,
      );
      final gameWidget = tester.widget<GameWidget<EditorWorld>>(gameFinder);
      final game = gameWidget.game!;
      final gameState = tester.state<GameWidgetState<EditorWorld>>(gameFinder);
      await tester.runAsync(
        () => gameState.loaderFuture.timeout(const Duration(seconds: 5)),
      );
      await tester.runAsync(
        () => game.ready().timeout(const Duration(seconds: 5)),
      );
      await tester.pump();

      game.grid.children.query<HexTile>().first.onTapped();
      await tester.pump();

      final editorState = container.read(editorStateProvider);
      expect(editorState.selectedTerrains, {TerrainType.hills});
      expect(editorState.selectedResources, {ResourceType.iron});
      expect(editorState.selectedHeight, 3);
      expect(editorState.selectedObjectiveType, MapObjectiveType.strategicPass);

      final topBar = tester.widget<EditorTopBar>(find.byType(EditorTopBar));
      topBar.onAddColumn();
      await tester.pump();
      expect(draft.cols, 2);

      topBar.onExport();
      await tester.pump();
      expect(find.text('Export Map'), findsOneWidget);
      await tester.tap(find.text('CANCEL'));
      await tester.pump();

      topBar.onSave();
      await tester.pump();
      expect(find.text('Save Map'), findsOneWidget);
      await tester.tap(find.text('CANCEL'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 12; attempt++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

final class _FakeMapRepository implements MapRepository {
  const _FakeMapRepository({required this.mapData});

  final MapData mapData;

  @override
  Future<void> deleteSavedMap(String name) async {}

  @override
  Future<List<MapSelection>> listAvailableMaps() async => const [];

  @override
  Future<MapData> loadMap(MapSelection selection) async => mapData;

  @override
  Future<String?> resolveImagePath(MapSelection selection) async => null;
}
