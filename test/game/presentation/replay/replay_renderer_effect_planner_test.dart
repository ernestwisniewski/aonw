import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/replay/replay_renderer_effect_planner.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReplayRendererEffectPlanner', () {
    test('adds movement effect for auto-exploring scout state deltas', () {
      final scout = _scout(col: 1, row: 1);
      final movedScout = scout.copyWith(col: 2, row: 1);

      final effects = ReplayRendererEffectPlanner.effectsForStep(
        commandEffects: const [],
        events: const [],
        previousState: GameState(units: [scout]),
        state: GameState(units: [movedScout]),
      );

      final move = effects.whereType<AnimateUnitMoveEffect>().single;
      expect(move.unitId, scout.id);
      expect(move.fromCol, 1);
      expect(move.fromRow, 1);
      expect(move.steps.single.col, 2);
      expect(move.steps.single.row, 1);
    });

    test('adds movement effect for merchant trade route state deltas', () {
      final merchant = _merchantWithTradeRoute(col: 0, row: 0);
      final movedMerchant = merchant.copyWith(col: 3, row: 0);

      final effects = ReplayRendererEffectPlanner.effectsForStep(
        commandEffects: const [],
        events: const [],
        previousState: GameState(units: [merchant]),
        state: GameState(units: [movedMerchant]),
      );

      final move = effects.whereType<AnimateUnitMoveEffect>().single;
      expect(move.unitId, merchant.id);
      expect(move.fromCol, 0);
      expect(move.fromRow, 0);
      expect(move.steps.map((step) => step.col), [1, 2, 3]);
    });

    test('does not duplicate existing movement command effects', () {
      final scout = _scout(col: 1, row: 1);
      final movedScout = scout.copyWith(col: 2, row: 1);
      const commandEffect = AnimateUnitMoveEffect(
        unitId: 'scout_1',
        fromCol: 1,
        fromRow: 1,
        steps: [
          UnitMovementStep(col: 2, row: 1, enterCost: 0, cumulativeCost: 0),
        ],
      );

      final effects = ReplayRendererEffectPlanner.effectsForStep(
        commandEffects: const [commandEffect],
        events: const [
          UnitMovedEvent(
            unitId: 'scout_1',
            fromCol: 1,
            fromRow: 1,
            toCol: 2,
            toRow: 1,
          ),
        ],
        previousState: GameState(units: [scout]),
        state: GameState(units: [movedScout]),
      );

      expect(effects.whereType<AnimateUnitMoveEffect>(), hasLength(1));
      expect(effects.whereType<AnimateUnitMoveEffect>().single, commandEffect);
    });

    test('adds artifact effect when excavation starts', () {
      final scout = _scout(col: 3, row: 4);
      final artifact = _artifactAt(col: 3, row: 4);
      final excavating = artifact.copyWith(
        location: WorldArtifactLocation.excavation(
          unitId: scout.id,
          col: 3,
          row: 4,
          remainingTurns: 2,
        ),
      );

      final effects = ReplayRendererEffectPlanner.effectsForStep(
        commandEffects: const [],
        events: const [],
        previousState: GameState(units: [scout], artifacts: [artifact]),
        state: GameState(
          units: [scout.copyWith(excavatingArtifactId: artifact.id)],
          artifacts: [excavating],
        ),
      );

      final burst = effects.whereType<SpawnParticleBurstEffect>().single;
      expect(burst.col, 3);
      expect(burst.row, 4);

      final text = effects.whereType<ShowFloatingTextEffect>().single;
      expect(text.text, 'Excavate');
      expect(text.col, 3);
      expect(text.row, 4);
      expect(text.presentation, FloatingTextPresentation.bubble);
    });

    test('adds artifact effect when excavation becomes carried', () {
      final scout = _scout(col: 3, row: 4);
      final artifact = _artifactAt(col: 3, row: 4);
      final excavating = artifact.copyWith(
        location: WorldArtifactLocation.excavation(
          unitId: scout.id,
          col: 3,
          row: 4,
          remainingTurns: 1,
        ),
      );
      final carried = artifact.copyWith(
        location: WorldArtifactLocation.carried(unitId: scout.id),
      );

      final effects = ReplayRendererEffectPlanner.effectsForStep(
        commandEffects: const [],
        events: const [],
        previousState: GameState(
          units: [scout.copyWith(excavatingArtifactId: artifact.id)],
          artifacts: [excavating],
        ),
        state: GameState(
          units: [scout.copyWith(carriedArtifactId: artifact.id)],
          artifacts: [carried],
        ),
      );

      final text = effects.whereType<ShowFloatingTextEffect>().single;
      expect(text.text, 'Artifact carried');
      expect(text.col, 3);
      expect(text.row, 4);
    });

    test('adds artifact effect when carried artifact is stored in a city', () {
      final scout = _scout(col: 8, row: 3);
      final city = _city(col: 8, row: 3);
      final artifact = _artifactAt(col: 3, row: 4);
      final carried = artifact.copyWith(
        location: WorldArtifactLocation.carried(unitId: scout.id),
      );
      final stored = artifact.copyWith(
        location: WorldArtifactLocation.stored(cityId: city.id),
      );

      final effects = ReplayRendererEffectPlanner.effectsForStep(
        commandEffects: const [],
        events: const [],
        previousState: GameState(
          units: [scout.copyWith(carriedArtifactId: artifact.id)],
          cities: [city],
          artifacts: [carried],
        ),
        state: GameState(units: [scout], cities: [city], artifacts: [stored]),
      );

      final text = effects.whereType<ShowFloatingTextEffect>().single;
      expect(text.text, 'Artifact stored');
      expect(text.col, 8);
      expect(text.row, 3);
    });

    test('treats artifact cues in perspective fog as visible', () {
      final city = _city(col: 8, row: 3);
      final artifact = _artifactAt(col: 3, row: 4);
      final carried = artifact.copyWith(
        location: const WorldArtifactLocation.carried(unitId: 'scout_1'),
      );
      final stored = artifact.copyWith(
        location: WorldArtifactLocation.stored(cityId: city.id),
      );
      final previousState = GameState(
        activePlayerId: 'player_1',
        cities: [city],
        artifacts: [carried],
        fogOfWar: _fogForPlayer('player_1', {
          const HexCoordinate(col: 8, row: 3),
        }),
      );
      final state = GameState(
        activePlayerId: 'player_1',
        cities: [city],
        artifacts: [stored],
        fogOfWar: _fogForPlayer('player_1', {
          const HexCoordinate(col: 8, row: 3),
        }),
      );

      final effects = ReplayRendererEffectPlanner.effectsForStep(
        commandEffects: const [],
        events: const [],
        previousState: previousState,
        state: state,
      );

      expect(
        ReplayRendererEffectPlanner.hasPerspectiveVisibleEffect(
          effects: effects,
          previousState: previousState,
          state: state,
          perspectivePlayerId: 'player_1',
        ),
        isTrue,
      );
    });

    test('ignores artifact cues outside perspective fog', () {
      final city = _city(col: 8, row: 3);
      final artifact = _artifactAt(col: 3, row: 4);
      final carried = artifact.copyWith(
        location: const WorldArtifactLocation.carried(unitId: 'scout_1'),
      );
      final stored = artifact.copyWith(
        location: WorldArtifactLocation.stored(cityId: city.id),
      );
      final previousState = GameState(
        activePlayerId: 'player_1',
        cities: [city],
        artifacts: [carried],
        fogOfWar: _fogForPlayer('player_1', const {}),
      );
      final state = GameState(
        activePlayerId: 'player_1',
        cities: [city],
        artifacts: [stored],
        fogOfWar: _fogForPlayer('player_1', const {}),
      );

      final effects = ReplayRendererEffectPlanner.effectsForStep(
        commandEffects: const [],
        events: const [],
        previousState: previousState,
        state: state,
      );

      expect(
        ReplayRendererEffectPlanner.hasPerspectiveVisibleEffect(
          effects: effects,
          previousState: previousState,
          state: state,
          perspectivePlayerId: 'player_1',
        ),
        isFalse,
      );
    });

    test('treats selected player movement as visible in perspective', () {
      final scout = _scout(col: 1, row: 1);
      final movedScout = scout.copyWith(col: 2, row: 1);
      const effect = AnimateUnitMoveEffect(
        unitId: 'scout_1',
        fromCol: 1,
        fromRow: 1,
        steps: [
          UnitMovementStep(col: 2, row: 1, enterCost: 0, cumulativeCost: 0),
        ],
      );

      final visible = ReplayRendererEffectPlanner.hasPerspectiveVisibleMovement(
        effects: const [effect],
        previousState: GameState(
          activePlayerId: 'player_1',
          units: [scout],
          fogOfWar: _fogForPlayer('player_1', const {}),
        ),
        state: GameState(
          activePlayerId: 'player_1',
          units: [movedScout],
          fogOfWar: _fogForPlayer('player_1', const {}),
        ),
        perspectivePlayerId: 'player_1',
      );

      expect(visible, isTrue);
    });

    test('treats enemy movement in perspective fog as visible', () {
      final enemy = _scout(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        col: 4,
        row: 1,
      );
      final movedEnemy = enemy.copyWith(col: 5, row: 1);
      const effect = AnimateUnitMoveEffect(
        unitId: 'enemy_1',
        fromCol: 4,
        fromRow: 1,
        steps: [
          UnitMovementStep(col: 5, row: 1, enterCost: 0, cumulativeCost: 0),
        ],
      );

      final visible = ReplayRendererEffectPlanner.hasPerspectiveVisibleMovement(
        effects: const [effect],
        previousState: GameState(
          activePlayerId: 'player_1',
          units: [enemy],
          fogOfWar: _fogForPlayer('player_1', {
            const HexCoordinate(col: 4, row: 1),
          }),
        ),
        state: GameState(
          activePlayerId: 'player_1',
          units: [movedEnemy],
          fogOfWar: _fogForPlayer('player_1', {
            const HexCoordinate(col: 5, row: 1),
          }),
        ),
        perspectivePlayerId: 'player_1',
      );

      expect(visible, isTrue);
    });

    test('ignores enemy movement outside perspective fog', () {
      final enemy = _scout(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        col: 4,
        row: 1,
      );
      final movedEnemy = enemy.copyWith(col: 5, row: 1);
      const effect = AnimateUnitMoveEffect(
        unitId: 'enemy_1',
        fromCol: 4,
        fromRow: 1,
        steps: [
          UnitMovementStep(col: 5, row: 1, enterCost: 0, cumulativeCost: 0),
        ],
      );

      final visible = ReplayRendererEffectPlanner.hasPerspectiveVisibleMovement(
        effects: const [effect],
        previousState: GameState(
          activePlayerId: 'player_1',
          units: [enemy],
          fogOfWar: _fogForPlayer('player_1', const {}),
        ),
        state: GameState(
          activePlayerId: 'player_1',
          units: [movedEnemy],
          fogOfWar: _fogForPlayer('player_1', const {}),
        ),
        perspectivePlayerId: 'player_1',
      );

      expect(visible, isFalse);
    });
  });
}

GameUnit _scout({
  String id = 'scout_1',
  String ownerPlayerId = 'player_1',
  required int col,
  required int row,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.scout,
    name: GameUnitType.scout.defaultNameToken,
    col: col,
    row: row,
    posture: UnitPosture.autoExploring,
  );
}

GameUnit _merchantWithTradeRoute({required int col, required int row}) {
  return GameUnit(
    id: 'merchant_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.merchant,
    name: GameUnitType.merchant.defaultNameToken,
    col: col,
    row: row,
  ).copyWithMerchantTradeRoute(
    MerchantTradeRoute(
      originCityId: 'city_origin',
      destinationCityId: 'city_target',
      steps: const [
        UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
        UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
      ],
    ),
  );
}

WorldArtifact _artifactAt({required int col, required int row}) {
  return WorldArtifact.placed(
    type: WorldArtifactType.ancientImperialCrown,
    col: col,
    row: row,
  );
}

GameCity _city({required int col, required int row}) {
  return GameCity(
    id: 'city_player_1_${col}_$row',
    ownerPlayerId: 'player_1',
    name: 'Warszawa',
    center: CityHex(col: col, row: row),
  );
}

FogOfWarState _fogForPlayer(String playerId, Set<HexCoordinate> visibleHexes) {
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(playerId: playerId, visibleHexes: visibleHexes),
    },
  );
}
