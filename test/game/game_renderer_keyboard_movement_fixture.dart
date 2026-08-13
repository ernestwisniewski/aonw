part of 'game_renderer_keyboard_test.dart';

const _artifactCarrierPreviewSteps = [
  UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
  UnitMovementStep(col: 1, row: 0, enterCost: 2, cumulativeCost: 2),
  UnitMovementStep(col: 2, row: 0, enterCost: 4, cumulativeCost: 6),
  UnitMovementStep(col: 3, row: 0, enterCost: 2, cumulativeCost: 8),
];

CityManagementOverlayHexKind? _overlayKindFor(GameRenderer game, CityHex hex) {
  return _overlayFor(game, hex)?.kind;
}

CityManagementOverlayHex? _overlayFor(GameRenderer game, CityHex hex) {
  for (final overlayHex in game.cityManagementOverlayHexesForTesting) {
    if (overlayHex.hex == hex) return overlayHex;
  }
  return null;
}

Vector2 _visibleCenter(GameRenderer game) {
  final zoom = game.camera.viewfinder.zoom;
  return game.camera.viewfinder.position +
      game.camera.viewport.size / (2 * zoom);
}

FogOfWarState _fog({
  Set<HexCoordinate> discovered = const {},
  Set<HexCoordinate> visible = const {},
}) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}

void _expectVectorClose(
  Vector2 actual,
  Vector2 expected, {
  double tolerance = 0.0001,
}) {
  expect(actual.x, closeTo(expected.x, tolerance));
  expect(actual.y, closeTo(expected.y, tolerance));
}
