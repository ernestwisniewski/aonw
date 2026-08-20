import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/unit_animation_controller.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/game_renderer_flame_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'keeps A at its intermediate destination through B and camera pre-roll',
    () async {
      final map = _map();
      final unitA = _unit('unit_a', col: 0, row: 0);
      final unitB = _unit('unit_b', col: 0, row: 1);
      final game = GameRenderer(mapData: map, onCommand: (_) async {});

      await gameRendererFlameTester.initializeWithState(
        game,
        GameClientState(units: [unitA, unitB], activePlayerId: 'player_1'),
      );

      final transition = game.applyTransition(
        GameClientState(
          units: [
            unitA.copyWith(col: 2, row: 0),
            unitB.copyWith(col: 1, row: 1),
          ],
          activePlayerId: 'player_1',
        ),
        const [
          AnimateUnitMoveEffect(
            unitId: 'unit_a',
            fromCol: 0,
            fromRow: 0,
            steps: [
              UnitMovementStep(col: 1, row: 0, enterCost: 7, cumulativeCost: 7),
            ],
          ),
          AnimateUnitMoveEffect(
            unitId: 'unit_b',
            fromCol: 0,
            fromRow: 1,
            steps: [
              UnitMovementStep(
                col: 1,
                row: 1,
                enterCost: 11,
                cumulativeCost: 11,
              ),
            ],
          ),
          AnimateUnitMoveEffect(
            unitId: 'unit_a',
            fromCol: 1,
            fromRow: 0,
            steps: [
              UnitMovementStep(
                col: 2,
                row: 0,
                enterCost: 13,
                cumulativeCost: 20,
              ),
            ],
          ),
        ],
      );
      await _flush();

      await _advance(game, 0.29);
      await _advance(game, 0.61);
      _expectAt(game, 'unit_a', 1, 0);
      _expectAt(game, 'unit_b', 0, 1);

      await _advance(game, 0.29);
      await _advance(game, 0.61);
      _expectAt(game, 'unit_a', 1, 0);
      _expectAt(game, 'unit_b', 1, 1);

      await _advance(game, 0.14);
      _expectAt(game, 'unit_a', 1, 0);

      await _advance(game, 0.15);
      await _advance(game, 0.61);
      await transition.timeout(const Duration(seconds: 1));

      _expectAt(game, 'unit_a', 2, 0);
      _expectAt(game, 'unit_b', 1, 1);
    },
  );

  test(
    'pre-load chain prepares every origin before the first camera pre-roll',
    () async {
      final unitA = _unit('unit_a', col: 0, row: 0);
      final unitB = _unit('unit_b', col: 0, row: 1);
      final game = GameRenderer(mapData: _map(), onCommand: (_) async {});
      addTearDown(game.disposeRenderer);
      game.applyState(
        GameClientState(units: [unitA, unitB], activePlayerId: 'player_1'),
      );

      var transitionCompleted = false;
      final transition = game
          .applyTransition(
            GameClientState(
              units: [
                unitA.copyWith(col: 2, row: 0),
                unitB.copyWith(col: 1, row: 1),
              ],
              activePlayerId: 'player_1',
            ),
            const [
              AnimateUnitMoveEffect(
                unitId: 'unit_a',
                fromCol: 0,
                fromRow: 0,
                steps: [
                  UnitMovementStep(
                    col: 1,
                    row: 0,
                    enterCost: 1,
                    cumulativeCost: 1,
                  ),
                ],
              ),
              AnimateUnitMoveEffect(
                unitId: 'unit_b',
                fromCol: 0,
                fromRow: 1,
                steps: [
                  UnitMovementStep(
                    col: 1,
                    row: 1,
                    enterCost: 1,
                    cumulativeCost: 1,
                  ),
                ],
              ),
              AnimateUnitMoveEffect(
                unitId: 'unit_a',
                fromCol: 1,
                fromRow: 0,
                steps: [
                  UnitMovementStep(
                    col: 2,
                    row: 0,
                    enterCost: 1,
                    cumulativeCost: 2,
                  ),
                ],
              ),
            ],
          )
          .then((_) => transitionCompleted = true);
      await _flush();
      expect(transitionCompleted, isFalse);

      game.onGameResize(Vector2(800, 600));
      var loadCompleted = false;
      final load = game.onLoad().then((_) => loadCompleted = true);
      await _waitForMarker(game, unitA.id);
      await _waitForMarker(game, unitB.id);

      expect(loadCompleted, isTrue);
      expect(transitionCompleted, isFalse);
      _expectAt(game, unitA.id, 0, 0);
      _expectAt(game, unitB.id, 0, 1);

      await _advance(game, 0.14);
      _expectAt(game, unitA.id, 0, 0);
      _expectAt(game, unitB.id, 0, 1);
      await _advance(game, 0.15);
      _expectAt(game, unitA.id, 0, 0);
      _expectAt(game, unitB.id, 0, 1);
      await _advance(game, 0.61);
      _expectAt(game, unitA.id, 1, 0);
      _expectAt(game, unitB.id, 0, 1);
      await _advance(game, 0.29);
      _expectAt(game, unitA.id, 1, 0);
      _expectAt(game, unitB.id, 0, 1);
      await _advance(game, 0.61);
      _expectAt(game, unitA.id, 1, 0);
      _expectAt(game, unitB.id, 1, 1);
      await _advance(game, 0.29);
      _expectAt(game, unitA.id, 1, 0);
      await _advance(game, 0.61);

      await Future.wait([load, transition]).timeout(const Duration(seconds: 1));
      expect(loadCompleted, isTrue);
      expect(transitionCompleted, isTrue);
      _expectAt(game, unitA.id, 2, 0);
      _expectAt(game, unitB.id, 1, 1);
    },
  );

  test('dispose settles a queued transition during camera pre-roll', () async {
    final unit = _unit('unit_a', col: 0, row: 0);
    final game = GameRenderer(mapData: _map(), onCommand: (_) async {});
    addTearDown(game.disposeRenderer);
    game.applyState(GameClientState(units: [unit], activePlayerId: 'player_1'));

    final transition = game.applyTransition(
      GameClientState(
        units: [unit.copyWith(col: 1, row: 0)],
        activePlayerId: 'player_1',
      ),
      const [
        AnimateUnitMoveEffect(
          unitId: 'unit_a',
          fromCol: 0,
          fromRow: 0,
          steps: [
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
      ],
    );
    Object? transitionError;
    var transitionSettled = false;
    final observed = transition.then<void>(
      (_) => transitionSettled = true,
      onError: (Object error, StackTrace stackTrace) {
        transitionError = error;
        transitionSettled = true;
      },
    );
    await _flush();

    game.onGameResize(Vector2(800, 600));
    await game.onLoad();
    _expectAt(game, unit.id, 0, 0);
    expect(transitionSettled, isFalse);

    game.disposeRenderer();
    await _flush();

    expect(transitionSettled, isTrue);
    expect(transitionError, isA<StateError>());
    await observed;
  });

  test('dispose settles a transition queued before renderer load', () async {
    final unit = _unit('unit_a', col: 0, row: 0);
    final game = GameRenderer(mapData: _map(), onCommand: (_) async {});
    addTearDown(game.disposeRenderer);
    game.applyState(GameClientState(units: [unit], activePlayerId: 'player_1'));
    final transition = game.applyTransition(
      GameClientState(
        units: [unit.copyWith(col: 1, row: 0)],
        activePlayerId: 'player_1',
      ),
      const [
        AnimateUnitMoveEffect(
          unitId: 'unit_a',
          fromCol: 0,
          fromRow: 0,
          steps: [
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
      ],
    );
    final expectation = expectLater(transition, throwsA(isA<StateError>()));
    await _flush();

    game.disposeRenderer();

    await expectation;
  });

  test('dispose errors every transition queued before renderer load', () async {
    final unit = _unit('unit_a', col: 0, row: 0);
    final game = GameRenderer(mapData: _map(), onCommand: (_) async {});
    addTearDown(game.disposeRenderer);
    game.applyState(GameClientState(units: [unit], activePlayerId: 'player_1'));
    final first = _moveTransition(game, unit: unit, fromCol: 0, toCol: 1);
    final second = _moveTransition(game, unit: unit, fromCol: 1, toCol: 2);
    final firstExpectation = expectLater(first, throwsA(isA<StateError>()));
    final secondExpectation = expectLater(second, throwsA(isA<StateError>()));
    await _flush();

    game.disposeRenderer();

    await Future.wait([firstExpectation, secondExpectation]);
  });

  test('renderer build error fails its queued transition', () async {
    final error = StateError('injected renderer build failure');
    final unit = _unit('unit_a', col: 0, row: 0);
    final game = GameRenderer(
      mapData: _map(),
      onCommand: (_) async {},
      onLoadingProgress: (_) => throw error,
    );
    addTearDown(game.disposeRenderer);
    game.applyState(GameClientState(units: [unit], activePlayerId: 'player_1'));
    final transition = _moveTransition(game, unit: unit, fromCol: 0, toCol: 1);
    final transitionExpectation = expectLater(transition, throwsA(same(error)));
    await _flush();

    game.onGameResize(Vector2(800, 600));
    await expectLater(game.onLoad(), throwsA(same(error)));
    game.disposeRenderer();

    await transitionExpectation;
    expect(game.isDisposedForTesting, isTrue);
  });

  test('reduced motion keeps the same intermediate lock state machine', () {
    final parent = PositionComponent();
    final unitA = _unit('unit_a', col: 0, row: 0);
    final unitB = _unit('unit_b', col: 0, row: 1);
    final finalUnits = [
      unitA.copyWith(col: 2, row: 0),
      unitB.copyWith(col: 1, row: 1),
    ];
    final layer =
        UnitMarkerLayer(
            mapData: _map(),
            colorForPlayer: (_) => 0xFF0000FF,
            reduceMotion: true,
          )
          ..sync(parent: parent, units: [unitA, unitB], selectedUnitId: null)
          ..pinPendingMovePositions({unitA.id, unitB.id})
          ..retainPendingMoveMarkers({unitA.id, unitB.id})
          ..sync(parent: parent, units: finalUnits, selectedUnitId: null);
    var authoritativeSyncs = 0;

    layer.animateMove(
      unitId: unitA.id,
      fromCol: 0,
      fromRow: 0,
      steps: const [
        UnitMovementStep(col: 1, row: 0, enterCost: 7, cumulativeCost: 7),
      ],
      retainAtDestination: true,
      onComplete: () {},
    );

    _expectLayerAt(layer, unitA.id, 1, 0);
    expect(layer.isPositionLockedForTesting(unitA.id), isTrue);
    expect(layer.isAnimationMarkerRetainedForTesting(unitA.id), isTrue);

    layer.animateMove(
      unitId: unitB.id,
      fromCol: 0,
      fromRow: 1,
      steps: const [
        UnitMovementStep(col: 1, row: 1, enterCost: 11, cumulativeCost: 11),
      ],
      onComplete: () {
        authoritativeSyncs += 1;
        layer.sync(parent: parent, units: finalUnits, selectedUnitId: null);
      },
    );

    _expectLayerAt(layer, unitA.id, 1, 0);
    _expectLayerAt(layer, unitB.id, 1, 1);

    layer.animateMove(
      unitId: unitA.id,
      fromCol: 1,
      fromRow: 0,
      steps: const [
        UnitMovementStep(col: 2, row: 0, enterCost: 13, cumulativeCost: 20),
      ],
      onComplete: () {
        authoritativeSyncs += 1;
        layer.sync(parent: parent, units: finalUnits, selectedUnitId: null);
      },
    );

    expect(authoritativeSyncs, 2);
    _expectLayerAt(layer, unitA.id, 2, 0);
    _expectLayerAt(layer, unitB.id, 1, 1);
    expect(layer.isPositionLockedForTesting(unitA.id), isFalse);
    expect(layer.isAnimationMarkerRetainedForTesting(unitA.id), isFalse);
  });

  test('missing marker releases pending lock and retention', () async {
    final layer =
        UnitMarkerLayer(
            mapData: _map(),
            colorForPlayer: (_) => 0xFF0000FF,
            reduceMotion: true,
          )
          ..pinPendingMovePositions(const {'ghost'})
          ..retainPendingMoveMarkers(const {'ghost'});
    final controller = UnitAnimationController(layer);
    addTearDown(controller.dispose);

    await controller.animateUnitMove(
      unitId: 'ghost',
      fromCol: 0,
      fromRow: 0,
      steps: const [
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ],
      retainAtDestination: true,
      onComplete: () {},
    );

    expect(controller.animatingUnitIdsListenable.value, isEmpty);
    expect(layer.isPositionLockedForTesting('ghost'), isFalse);
    expect(layer.isAnimationMarkerRetainedForTesting('ghost'), isFalse);
  });
}

WorldMap _map() => WorldMap(
  cols: 3,
  rows: 2,
  tiles: [
    for (var row = 0; row < 2; row++)
      for (var col = 0; col < 3; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

GameUnit _unit(String id, {required int col, required int row}) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    col: col,
    row: row,
  );
}

Future<void> _moveTransition(
  GameRenderer game, {
  required GameUnit unit,
  required int fromCol,
  required int toCol,
}) {
  return game.applyTransition(
    GameClientState(
      units: [unit.copyWith(col: toCol, row: 0)],
      activePlayerId: 'player_1',
    ),
    [
      AnimateUnitMoveEffect(
        unitId: unit.id,
        fromCol: fromCol,
        fromRow: 0,
        steps: [
          UnitMovementStep(col: toCol, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      ),
    ],
  );
}

Future<void> _advance(GameRenderer game, double seconds) async {
  game.update(seconds);
  await _flush();
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

Future<void> _waitForMarker(GameRenderer game, String unitId) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    if (game.unitMarkerPositionForTesting(unitId) != null) return;
    await _flush();
  }
  fail('Unit marker $unitId was not created');
}

void _expectAt(GameRenderer game, String unitId, int col, int row) {
  expect(
    game.unitMarkerPositionForTesting(unitId),
    UnitMarkerLayer.worldPositionFor(col, row),
  );
}

void _expectLayerAt(UnitMarkerLayer layer, String unitId, int col, int row) {
  expect(
    layer.markerPositionForTesting(unitId),
    UnitMarkerLayer.worldPositionFor(col, row),
  );
}
