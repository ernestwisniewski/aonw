import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_screen.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final class _RecordingGameRepository implements GameRepository {
  NewGameRequest? createdRequest;

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async {
    createdRequest = request;
    return 'save_1';
  }

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<CanonicalGameSnapshot> load(String saveId) async =>
      throw UnimplementedError();

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async {}

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async => throw UnimplementedError();
}

void main() {
  testWidgets('singleplayer blocks starting with an invalid map', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingGameRepository();
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);
    final router = GoRouter(
      initialLocation: '/new-game',
      routes: [
        GoRoute(
          path: '/new-game',
          builder: (context, state) => const NewGameScreen(),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) => const SizedBox(key: Key('game-screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repository),
          availableMapsProvider.overrideWithValue(const AsyncData([selection])),
          activeMapProvider(
            selection,
          ).overrideWithValue(AsyncData(_invalidMap())),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gameToast.surface')), findsOneWidget);
    expect(find.text('Map needs fixes'), findsNWidgets(2));
    expect(repository.createdRequest, isNull);
    expect(find.byKey(const Key('game-screen')), findsNothing);
  });
}

WorldMap _invalidMap() => WorldMap(
  cols: 20,
  rows: 20,
  mapName: 'verdantia',
  tiles: [
    for (var row = 0; row < 20; row++)
      for (var col = 0; col < 20; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.ocean],
          resources: const [],
          height: 0,
        ),
  ],
);
