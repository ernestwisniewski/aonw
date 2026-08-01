part of 'game_screen_test.dart';

WorldMap _makeOtherMap() => WorldMap(
  cols: 4,
  rows: 2,
  tiles: [
    for (int r = 0; r < 2; r++)
      for (int c = 0; c < 4; c++)
        WorldTile(
          col: c,
          row: r,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

void _expectWarmPanelSurface(
  WidgetTester tester,
  Key key, {
  required String reason,
}) {
  final surface = tester.widget<DecoratedBox>(find.byKey(key));
  final decoration = surface.decoration;
  expect(decoration, isA<BoxDecoration>(), reason: reason);
  final box = decoration as BoxDecoration;
  expect(box.gradient, isA<LinearGradient>(), reason: reason);
  expect(box.color, isNull, reason: reason);
}
