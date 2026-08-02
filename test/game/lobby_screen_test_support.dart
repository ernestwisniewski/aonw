part of 'lobby_screen_test.dart';

WorldMap _map({
  int cols = 8,
  int rows = 8,
  TerrainType terrain = TerrainType.grassland,
  List<ResourceType> resources = const [
    ResourceType.wheat,
    ResourceType.iron,
    ResourceType.gold,
  ],
}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          WorldTile(
            col: col,
            row: row,
            terrains: [terrain],
            resources: resources,
            height: 0,
          ),
    ],
  );
}

Future<void> _selectGameLength(WidgetTester tester, String label) async {
  final dropdown = find.byKey(const Key('game-length-dropdown'));
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void _registerLobbyMapCapacityTests() {
  testWidgets('synchronizes player limit with loaded custom map capacity', (
    tester,
  ) async {
    final repository = _FakeGameRepository();
    await _pumpLobby(
      tester,
      repository,
      mapName: 'custom',
      mapData: _map(cols: 8, rows: 8),
    );

    await tester.pump();

    expect(find.text('+ ADD PLAYER'), findsNothing);
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    expect(repository.createdRequest?.players, hasLength(2));
  });
}
