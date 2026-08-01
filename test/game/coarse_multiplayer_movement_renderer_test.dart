import 'package:aonw/api/transport/live_server_event.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'exact stream movement falls back once after an enemy leaves vision',
    () async {
      final enemy = GameUnit.produced(
        id: 'enemy',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final before = GameState(
        activePlayerId: 'player_1',
        fogOfWar: _fog({const HexCoordinate(col: 0, row: 0)}),
        units: [enemy],
      );
      final after = GameState(activePlayerId: 'player_1', fogOfWar: _fog({}));
      const event = UnitMovedEvent(
        unitId: 'enemy',
        fromCol: 0,
        fromRow: 0,
        toCol: 3,
        toRow: 0,
      );
      final live = LiveServerEvent.fromWire(
        wire: WireEvent(
          matchId: 'match_1',
          offset: 7,
          timestamp: DateTime.utc(2026, 7, 31),
          events: [
            GameEventSerializer.toJson(event),
            GameEventSerializer.toJson(
              const UnitMovedEvent(
                unitId: 'enemy',
                fromCol: 1,
                fromRow: 0,
                toCol: 3,
                toRow: 0,
              ),
            ),
          ],
          movementExecutions: WireMovementExecutionList([
            WireMovementExecution(
              unitId: 'enemy',
              fromCol: 0,
              fromRow: 0,
              steps: const [
                WireMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
            WireMovementExecution(
              unitId: 'enemy',
              fromCol: 1,
              fromRow: 0,
              steps: const [
                WireMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                WireMovementStep(
                  col: 3,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 2,
                ),
              ],
            ),
          ]),
        ),
        events: const [
          event,
          UnitMovedEvent(
            unitId: 'enemy',
            fromCol: 1,
            fromRow: 0,
            toCol: 3,
            toRow: 0,
          ),
        ],
        combatAnimations: const [],
      );
      expect(live.movementExecutions, hasLength(2));
      final batch = DomainEventPresentationProjector.projectObservedBatch(
        identity: PresentationBatchIdentity(
          sourceId: live.wire.matchId,
          eventOffset: live.wire.offset,
        ),
        interactionEffects: const [],
        events: live.events,
        visibleMovementExecutions: live.movementExecutions,
        previousState: before,
        state: after,
      );
      final movement = batch.domainEffects.single.effect;
      expect(movement, isA<AnimateUnitMoveEffect>());
      final coarse = movement as AnimateUnitMoveEffect;
      expect((coarse.fromCol, coarse.fromRow), (0, 0));
      expect((coarse.steps.single.col, coarse.steps.single.row), (3, 0));
      expect(coarse.steps.single.cumulativeCost, 0);
      final renderer = GameRenderer(mapData: _map(), onCommand: (_) async {});
      addTearDown(renderer.disposeRenderer);

      renderer
        ..applyState(before)
        ..onGameResize(Vector2(800, 600));
      await renderer.onLoad();

      final transition = renderer.applyProjectedTransition(after, batch);
      await Future<void>.delayed(Duration.zero);

      expect(renderer.animatingUnitIdsListenable.value, contains(enemy.id));

      renderer.update(0.7);
      await transition.timeout(const Duration(seconds: 1));

      await renderer.applyProjectedTransition(after, batch);
      expect(renderer.animatingUnitIdsListenable.value, isEmpty);
    },
  );
}

FogOfWarState _fog(Set<HexCoordinate> visible) => FogOfWarState(
  players: {
    'player_1': PlayerFogOfWar(playerId: 'player_1', visibleHexes: visible),
  },
);

MapData _map() => MapData(
  cols: 4,
  rows: 1,
  tiles: [
    for (var col = 0; col < 4; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
  ],
);
