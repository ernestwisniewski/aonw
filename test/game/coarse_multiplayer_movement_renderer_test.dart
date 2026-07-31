import 'package:aonw/api/transport/live_server_event.dart';
import 'package:aonw/game/domain/game_state.dart';
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
    'coarse stream movement animates once after an enemy leaves vision',
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
        toCol: 2,
        toRow: 0,
      );
      final live = LiveServerEvent.fromWire(
        wire: WireEvent(
          matchId: 'match_1',
          offset: 7,
          timestamp: DateTime.utc(2026, 7, 31),
          events: [GameEventSerializer.toJson(event)],
          movementExecutions: WireMovementExecutionList(const []),
        ),
        events: const [event],
        combatAnimations: const [],
      );
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
  cols: 3,
  rows: 1,
  tiles: [
    for (var col = 0; col < 3; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
  ],
);
