import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/combat/application/combat_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'reconciles stable unit IDs and keeps shared render resources',
    AonwFlameGame.new,
    (game) async {
      final stable = testVisibleUnit(id: 'stable');
      final changing = testVisibleUnit(
        id: 'changing',
        coordinate: (col: 1, row: 0),
      );
      final scene = testMapScene(units: [stable, changing]);
      game.replaceScene(_snapshot(scene, player: scene.player));
      await game.ready();
      final stableComponent = game.world.unitLayer.debugComponentForUnit(
        'stable',
      );
      final changingComponent = game.world.unitLayer.debugComponentForUnit(
        'changing',
      );

      game.replaceScene(
        _snapshot(
          scene,
          player: _player(
            units: [
              stable,
              testVisibleUnit(
                id: 'changing',
                coordinate: (col: 1, row: 0),
                movementUnits: 8,
              ),
            ],
          ),
          interaction: MapInteractionState(
            selected: (col: 1, row: 0),
            selectedUnitId: 'changing',
            reachable: testReachableView(unitId: 'changing'),
            route: testRoutePlanView(unitId: 'changing'),
          ),
        ),
      );

      expect(
        game.world.unitLayer.debugComponentForUnit('stable'),
        same(stableComponent),
      );
      expect(
        game.world.unitLayer.debugComponentForUnit('changing'),
        same(changingComponent),
      );
      expect(game.world.unitLayer.debugCreatedCount, 2);
      expect(game.world.unitLayer.debugUpdatedCount, 1);
      expect(game.world.unitLayer.debugSharedPaintCount, 3);
      expect(game.world.reachableLayer.debugPathBuildCount, 1);
      expect(game.world.routeLayer.debugPathBuildCount, 1);
      expect(game.world.selectionLayer.debugUpdateCount, 2);
    },
  );

  testWithGame<AonwFlameGame>(
    'animates an accepted authoritative endpoint without emitting input',
    () {
      final intents = <Object>[];
      return AonwFlameGame(onHexIntent: intents.add)
        ..add(_IntentProbe(intents));
    },
    (game) async {
      final scene = testMapScene(units: [testVisibleUnit()]);
      game.replaceScene(
        _snapshot(
          scene,
          player: scene.player,
          interaction: MapInteractionState(
            selected: (col: 0, row: 0),
            selectedUnitId: 'preview-commander',
            route: testRoutePlanView(),
            movementPending: true,
          ),
        ),
      );
      await game.ready();
      final unit = game.world.unitLayer.debugComponentForUnit(
        'preview-commander',
      )!;
      final start = unit.debugVisualCenter;

      game.setViewportActive(true);
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(
            revision: 1,
            digest: 'd' * 64,
            units: [testVisibleUnit(coordinate: (col: 1, row: 0))],
          ),
          interaction: const MapInteractionState(selected: (col: 1, row: 0)),
        ),
      );

      expect(game.world.effectHost.debugActiveEffectCount, 1);
      expect(game.debugEffectsActive, isTrue);
      expect(game.paused, isFalse);
      expect(unit.debugVisualCenter, start);

      game.world.effectHost.update(0.12);
      expect(unit.debugVisualCenter, isNot(start));
      game.world.effectHost.update(0.12);

      expect(game.world.effectHost.debugActiveEffectCount, 0);
      expect(game.world.effectHost.debugCompletedMovementCount, 1);
      expect(game.debugEffectsActive, isFalse);
      expect(game.paused, isTrue, reason: 'the world returns to idle');
      final expected = game.world.unitLayer.centerFor(
        game.world.debugStaticRenderCache!,
        (col: 1, row: 0),
      );
      expect(unit.debugVisualCenter.dx, closeTo(expected.dx, 0.00001));
      expect(unit.debugVisualCenter.dy, closeTo(expected.dy, 0.00001));
      final idleUpdateCount = game.world.effectHost.debugActiveUpdateCount;
      game.world.effectHost.update(1);
      expect(game.world.effectHost.debugActiveUpdateCount, idleUpdateCount);
      expect(game.children.whereType<_IntentProbe>().single.intents, isEmpty);
    },
  );

  testWithGame<AonwFlameGame>(
    'skip reduced motion and speed only alter presentation effects',
    AonwFlameGame.new,
    (game) async {
      final scene = testMapScene(units: [testVisibleUnit()]);
      game.replaceScene(
        _snapshot(
          scene,
          player: scene.player,
          interaction: const MapInteractionState(
            selectedUnitId: 'preview-commander',
            movementPending: true,
          ),
        ),
      );
      await game.ready();
      game.setEffectPlaybackSpeed(4);
      expect(game.world.effectHost.debugPlaybackSpeed, 4);
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(
            revision: 1,
            digest: 'd' * 64,
            units: [testVisibleUnit(coordinate: (col: 1, row: 0))],
          ),
        ),
      );
      expect(game.world.effectHost.debugActiveEffectCount, 1);
      game.skipEffects();
      expect(game.world.effectHost.debugActiveEffectCount, 0);

      game.setReducedMotion(true);
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(
            revision: 1,
            digest: 'd' * 64,
            units: [testVisibleUnit(coordinate: (col: 1, row: 0))],
          ),
          interaction: const MapInteractionState(
            selectedUnitId: 'preview-commander',
            movementPending: true,
          ),
        ),
      );
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(
            revision: 2,
            digest: 'e' * 64,
            units: [testVisibleUnit(coordinate: (col: 2, row: 0))],
          ),
        ),
      );
      expect(game.world.effectHost.debugActiveEffectCount, 0);
      expect(game.world.effectHost.debugCompletedMovementCount, 2);
    },
  );

  testWithGame<AonwFlameGame>(
    '40 by 30 workload remains indexed by units rather than map cells',
    AonwFlameGame.new,
    (game) async {
      final units = [
        for (var index = 0; index < 120; index++)
          testVisibleUnit(
            id: 'unit-$index',
            coordinate: (col: index % 40, row: index ~/ 40),
          ),
      ];
      final scene = testMapScene(cols: 40, rows: 30, units: units);
      game.replaceScene(_snapshot(scene, player: scene.player));
      await game.ready();

      expect(game.world.unitLayer.debugUnitCount, 120);
      expect(game.world.unitLayer.children, hasLength(120));
      expect(game.world.unitLayer.debugCreatedCount, 120);
      expect(game.world.unitLayer.debugSharedPaintCount, 3);
      expect(game.world.children, hasLength(9));
    },
  );

  testWithGame<AonwFlameGame>(
    'pools a bounded combat pulse and removes it under reduced motion',
    AonwFlameGame.new,
    (game) async {
      final unit = testVisibleUnit();
      final scene = testMapScene(units: [unit]);
      game.replaceScene(_snapshot(scene, player: scene.player));
      await game.ready();
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(revision: 1, digest: 'd' * 64, units: [unit]),
          interaction: CombatState(
            attackerUnitId: unit.id,
            defenderCoordinate: const (col: 1, row: 0),
            lastExecution: testCombatExecutionView(),
          ).asInteraction(),
        ),
      );

      expect(game.world.effectHost.debugActiveCombatEffectCount, 1);
      expect(
        game.world.effectHost.debugActiveCombatEffectCount,
        lessThanOrEqualTo(game.world.effectHost.debugMaximumCombatEffectCount),
      );
      game.world.effectHost.update(0.32);
      expect(game.world.effectHost.debugActiveCombatEffectCount, 0);

      game.setReducedMotion(true);
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(revision: 2, digest: 'e' * 64, units: [unit]),
          interaction: CombatState(
            attackerUnitId: unit.id,
            defenderCoordinate: const (col: 1, row: 0),
            lastExecution: testCombatExecutionView(revision: 2),
          ).asInteraction(),
        ),
      );
      expect(game.world.effectHost.debugActiveCombatEffectCount, 0);
    },
  );

  testWithGame<AonwFlameGame>(
    'reconciles stable city markers without rebuilding unchanged cities',
    AonwFlameGame.new,
    (game) async {
      final stable = testCityView(id: 'stable-city');
      final changing = testCityView(
        id: 'changing-city',
        center: (col: 2, row: 1),
      );
      final scene = testMapScene(cities: [stable, changing]);
      game.replaceScene(_snapshot(scene, player: scene.player));
      await game.ready();
      final stableComponent = game.world.cityLayer.debugComponentForCity(
        stable.id,
      );

      final changed = testCityView(
        id: changing.id,
        name: 'Changed City',
        center: changing.center,
      );
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(units: const [], cities: [stable, changed]),
        ),
      );

      expect(
        game.world.cityLayer.debugComponentForCity(stable.id),
        same(stableComponent),
      );
      expect(game.world.cityLayer.debugCityCount, 2);
      expect(game.world.cityLayer.debugCreatedCount, 2);
      expect(game.world.cityLayer.debugUpdatedCount, 1);
      expect(game.world.cityLayer.debugSharedPaintCount, 3);
    },
  );
}

extension on CombatState {
  MapInteractionState asInteraction() => MapInteractionState(
    selected: defenderCoordinate,
    selectedUnitId: attackerUnitId,
    combat: this,
  );
}

final class _IntentProbe extends PositionComponent {
  _IntentProbe(this.intents);

  final List<Object> intents;
}

MapRenderSnapshot _snapshot(
  MapScene scene, {
  required PlayerMapView player,
  MapInteractionState interaction = const MapInteractionState(),
}) => MapRenderSnapshot(
  map: scene.map,
  interaction: interaction,
  reference: scene.reference,
  player: player,
);

PlayerMapView _player({
  int revision = 0,
  String? digest,
  required List<VisibleUnitView> units,
  List<CityView> cities = const [],
}) => PlayerMapView.preview(
  actorPlayerId: 'preview-player',
  stamp: SessionStampView(
    revision: revision,
    stateDigest: digest ?? 'b' * 64,
    mapHash: 'a' * 64,
    rulesetHash: 'c' * 64,
  ),
  turn: 1,
  pendingAction: null,
  units: units,
  cities: cities,
);
