import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/hover_intent_marker.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HoverIntentMarkerLayer', () {
    test('sync records one marker and clear removes it', () {
      final layer = HoverIntentMarkerLayer();
      final parent = Component();
      const hex = CityHex(col: 1, row: 2);

      layer.sync(
        parent: parent,
        intent: const HoverIntentMarkerSpec(
          hex: hex,
          kind: HoverIntentKind.move,
          color: HudPalette.roadMarking,
        ),
      );

      expect(layer.hexForTesting, hex);
      expect(layer.kindForTesting, HoverIntentKind.move);
      expect(layer.colorForTesting, HudPalette.roadMarking);
      expect(layer.blockedForTesting, isFalse);
      expect(layer.markerForTesting?.blockedForTesting, isFalse);
      expect(layer.markerForTesting?.drawsMoveHexOutlineForTesting, isTrue);
      expect(layer.markerForTesting?.priority, MapPriority.hoverIntentOverlay);

      layer.clear();

      expect(layer.hexForTesting, isNull);
      expect(layer.kindForTesting, isNull);
      expect(layer.markerForTesting, isNull);
    });

    test(
      'reachable move paints a hex, blocked move paints only an X',
      () async {
        final reachable = HoverIntentMarker(
          hex: const CityHex(col: 0, row: 0),
          kind: HoverIntentKind.move,
          color: HudPalette.roadMarking,
        );
        final blocked = HoverIntentMarker(
          hex: const CityHex(col: 0, row: 0),
          kind: HoverIntentKind.move,
          color: HudPalette.danger,
          blocked: true,
        );

        final reachableBounds = await _paintedMoveCueBounds(reachable);
        final blockedBounds = await _paintedMoveCueBounds(blocked);

        expect(reachable.drawsMoveHexOutlineForTesting, isTrue);
        expect(reachableBounds, isNotNull);
        expect(reachableBounds!.width, greaterThan(80));
        expect(blocked.usesBareBlockedCueForTesting, isTrue);
        expect(blockedBounds, isNotNull);
        expect(blockedBounds!.width, lessThan(40));
        expect(blockedBounds.height, lessThan(40));
      },
    );
  });

  group('GameRenderer hover intent', () {
    test('standard mode does not show a hover marker', () async {
      final map = _map();
      final game = await _loadedGame(map);
      game
        ..applyState(GameClientState())
        ..syncHoverIntentForTesting(_tile(map, 1, 1));

      expect(game.hoverIntentKindForTesting, isNull);
      expect(game.hoverIntentTileForTesting, isNull);
    });

    test('move targeting shows a move marker', () async {
      final map = _map();
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final game = await _loadedGame(map);
      game
        ..applyState(
          GameClientState(
            units: [commander],
            interaction: InteractionState(
              selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
              moveCommandActive: true,
            ),
          ),
        )
        ..syncHoverIntentForTesting(_tile(map, 1, 1));

      expect(game.hoverIntentKindForTesting, HoverIntentKind.move);
      expect(game.hoverIntentTileForTesting, (col: 1, row: 1));
      expect(
        game.hoverIntentColorValueForTesting,
        HudPalette.roadMarking.toARGB32(),
      );
      expect(game.hoverIntentBlockedForTesting, isFalse);
    });

    test(
      'gamepad cursor retargets movement without leaving move mode',
      () async {
        final map = _map();
        final commands = <GameIntent>[];
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final game = await _loadedGame(
          map,
          onCommand: (command) async => commands.add(command),
        );

        game
          ..applyState(
            GameClientState(
              activePlayerId: 'player_1',
              units: [commander],
              interaction: InteractionState(
                selection: GameSelection.unit(
                  commander,
                  tile: _tile(map, 0, 0),
                ),
                moveCommandActive: true,
              ),
            ),
          )
          ..moveGamepadCursor(GamepadMapDirection.right);

        expect(commands, isEmpty);
        expect(game.moveCommandActiveForTesting, isTrue);
        expect(game.hoverIntentKindForTesting, HoverIntentKind.move);
        expect(game.hoverIntentTileForTesting, (col: 1, row: 0));

        game.confirmGamepadCursor();
        await Future<void>.delayed(Duration.zero);

        expect(commands, [const TileTappedCommand(1, 0)]);
      },
    );

    test('gamepad cursor selection does not move the camera', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
      );

      game.applyStateWithoutCameraFocus(
        GameClientState(
          activePlayerId: 'player_1',
          units: [commander],
          interaction: InteractionState(
            selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
          ),
        ),
      );
      game.camera.viewfinder
        ..zoom = 2
        ..position = Vector2(900, 700);
      final start = game.camera.viewfinder.position.clone();

      game.moveGamepadCursor(GamepadMapDirection.right);
      await Future<void>.delayed(Duration.zero);
      game.update(0.2);

      expect(commands, [const SelectTileCommand(1, 0)]);
      expect(game.camera.viewfinder.position.x, closeTo(start.x, 0.001));
      expect(game.camera.viewfinder.position.y, closeTo(start.y, 0.001));
    });

    test('gamepad cursor reanchors when the selected unit changes', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final firstUnit = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final secondUnit = GameUnit(
        id: 'scout_2',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 0,
        row: 2,
      );
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
      );

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            units: [firstUnit, secondUnit],
            interaction: InteractionState(
              selection: GameSelection.unit(firstUnit, tile: _tile(map, 0, 0)),
              moveCommandActive: true,
            ),
          ),
        )
        ..moveGamepadCursor(GamepadMapDirection.right);

      expect(game.hoverIntentTileForTesting, (col: 1, row: 0));

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            units: [firstUnit, secondUnit],
            interaction: InteractionState(
              selection: GameSelection.unit(secondUnit, tile: _tile(map, 0, 2)),
              moveCommandActive: true,
            ),
          ),
        )
        ..moveGamepadCursor(GamepadMapDirection.right);

      expect(commands, isEmpty);
      expect(game.moveCommandActiveForTesting, isTrue);
      expect(game.hoverIntentTileForTesting, (col: 1, row: 2));
    });

    test('gamepad cancel prioritizes pending worker action', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 0,
        row: 0,
      );
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
      );

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            units: [worker],
            interaction: InteractionState(
              selection: GameSelection.unit(worker, tile: _tile(map, 0, 0)),
              moveCommandActive: true,
              pendingAction: const PendingWorkerActionSelection(
                ownerPlayerId: 'player_1',
                unitId: 'worker_1',
              ),
            ),
          ),
        )
        ..cancelGamepadAction();
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const CancelWorkerActionSelectionCommand('worker_1')]);
    });

    test('gamepad move toggle ignores pending worker action', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 0,
        row: 0,
      );
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
      );

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            units: [worker],
            interaction: InteractionState(
              selection: GameSelection.unit(worker, tile: _tile(map, 0, 0)),
              pendingAction: const PendingWorkerActionSelection(
                ownerPlayerId: 'player_1',
                unitId: 'worker_1',
              ),
            ),
          ),
        )
        ..toggleGamepadMoveMode();
      await Future<void>.delayed(Duration.zero);

      expect(commands, isEmpty);
    });

    test('move targeting shows a move marker on reachable fog', () async {
      final map = _map();
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final fog = FogOfWarState.empty.updatePlayer(
        PlayerFogOfWar(
          playerId: 'player_1',
          visibleHexes: {const HexCoordinate(col: 0, row: 0)},
        ),
      );
      final game = await _loadedGame(map);

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            fogOfWar: fog,
            units: [commander],
            interaction: InteractionState(
              selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
              moveCommandActive: true,
            ),
          ),
        )
        ..syncHoverIntentForTesting(_tile(map, 1, 1));

      expect(game.hoverIntentKindForTesting, HoverIntentKind.move);
      expect(game.hoverIntentTileForTesting, (col: 1, row: 1));
      expect(
        game.hoverIntentColorValueForTesting,
        HudPalette.roadMarking.toARGB32(),
      );
      expect(game.hoverIntentBlockedForTesting, isFalse);
    });

    test(
      'move targeting shows a red blocked marker on unreachable fog',
      () async {
        final map = _map(cols: 5, rows: 5);
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final fog = FogOfWarState.empty.updatePlayer(
          PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 0, row: 0)},
          ),
        );
        final game = await _loadedGame(map);

        game
          ..applyState(
            GameClientState(
              activePlayerId: 'player_1',
              fogOfWar: fog,
              units: [commander],
              interaction: InteractionState(
                selection: GameSelection.unit(
                  commander,
                  tile: _tile(map, 0, 0),
                ),
                moveCommandActive: true,
              ),
            ),
          )
          ..syncHoverIntentForTesting(_tile(map, 4, 4));

        expect(game.hoverIntentKindForTesting, HoverIntentKind.move);
        expect(game.hoverIntentTileForTesting, (col: 4, row: 4));
        expect(
          game.hoverIntentColorValueForTesting,
          HudPalette.danger.toARGB32(),
        );
        expect(game.hoverIntentBlockedForTesting, isTrue);
      },
    );

    test(
      'move targeting shows a red blocked marker on impassable terrain',
      () async {
        final map = _map(blockedHex: const CityHex(col: 1, row: 1));
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final game = await _loadedGame(map);

        game
          ..applyState(
            GameClientState(
              units: [commander],
              interaction: InteractionState(
                selection: GameSelection.unit(
                  commander,
                  tile: _tile(map, 0, 0),
                ),
                moveCommandActive: true,
              ),
            ),
          )
          ..syncHoverIntentForTesting(_tile(map, 1, 1));

        expect(game.hoverIntentKindForTesting, HoverIntentKind.move);
        expect(game.hoverIntentTileForTesting, (col: 1, row: 1));
        expect(
          game.hoverIntentColorValueForTesting,
          HudPalette.danger.toARGB32(),
        );
        expect(game.hoverIntentBlockedForTesting, isTrue);
      },
    );

    test('attack targeting shows an attack marker', () async {
      final map = _map();
      final attacker = GameUnit.startingWarrior(ownerPlayerId: 'player_1');
      final game = await _loadedGame(map);

      game
        ..applyState(
          GameClientState(
            units: [attacker],
            interaction: InteractionState(
              pendingAction: PendingAttackTargeting(
                ownerPlayerId: attacker.ownerPlayerId,
                attackerUnitId: attacker.id,
              ),
            ),
          ),
        )
        ..syncHoverIntentForTesting(_tile(map, 2, 1));

      expect(game.hoverIntentKindForTesting, HoverIntentKind.attack);
      expect(game.hoverIntentTileForTesting, (col: 2, row: 1));
      expect(
        game.hoverIntentColorValueForTesting,
        HudPalette.danger.toARGB32(),
      );
    });

    test(
      'ending attack targeting clears a stale attack hover marker',
      () async {
        final map = _map();
        final attacker = GameUnit.startingWarrior(ownerPlayerId: 'player_1');
        final game = await _loadedGame(map);

        game
          ..applyState(
            GameClientState(
              units: [attacker],
              interaction: InteractionState(
                pendingAction: PendingAttackTargeting(
                  ownerPlayerId: attacker.ownerPlayerId,
                  attackerUnitId: attacker.id,
                ),
              ),
            ),
          )
          ..syncHoverIntentForTesting(_tile(map, 2, 1));

        expect(game.hoverIntentKindForTesting, HoverIntentKind.attack);

        game.applyState(GameClientState(units: [attacker]));

        expect(game.hoverIntentKindForTesting, isNull);
        expect(game.hoverIntentTileForTesting, isNull);
      },
    );

    test('city founding uses the founding marker and player color', () async {
      final map = _map();
      final game = await _loadedGame(map);

      game
        ..applyState(
          GameClientState(
            playerColors: const {'player_1': 0xFF123456},
            interaction: InteractionState(
              cityFoundingDraft: CityFoundingDraft(
                unitId: 'settler_1',
                ownerPlayerId: 'player_1',
                center: const CityHex(col: 0, row: 0),
              ),
            ),
          ),
        )
        ..syncHoverIntentForTesting(_tile(map, 1, 2));

      expect(game.hoverIntentKindForTesting, HoverIntentKind.founding);
      expect(game.hoverIntentTileForTesting, (col: 1, row: 2));
      expect(game.hoverIntentColorValueForTesting, 0xFF123456);
    });

    test('ending city founding clears a stale founding hover marker', () async {
      final map = _map();
      final game = await _loadedGame(map);

      game
        ..applyState(
          GameClientState(
            interaction: InteractionState(
              cityFoundingDraft: CityFoundingDraft(
                unitId: 'settler_1',
                ownerPlayerId: 'player_1',
                center: const CityHex(col: 0, row: 0),
              ),
            ),
          ),
        )
        ..syncHoverIntentForTesting(_tile(map, 1, 2));

      expect(game.hoverIntentKindForTesting, HoverIntentKind.founding);

      game.applyState(GameClientState());

      expect(game.hoverIntentKindForTesting, isNull);
      expect(game.hoverIntentTileForTesting, isNull);
    });

    test('city worked hex selection shows a worked-hex marker', () async {
      final map = _map();
      final game = await _loadedGame(map);

      game
        ..applyState(
          GameClientState(
            interaction: const InteractionState(
              pendingAction: PendingCityWorkedHexSelection(
                ownerPlayerId: 'player_1',
                cityId: 'city_1',
              ),
            ),
          ),
        )
        ..syncHoverIntentForTesting(_tile(map, 0, 2));

      expect(game.hoverIntentKindForTesting, HoverIntentKind.workedHex);
      expect(game.hoverIntentTileForTesting, (col: 0, row: 2));
      expect(
        game.hoverIntentColorValueForTesting,
        HudPalette.success.toARGB32(),
      );
    });

    test('city expansion selection shows a gold founding marker', () async {
      final map = _map();
      final game = await _loadedGame(map);

      game
        ..applyState(
          GameClientState(
            interaction: const InteractionState(
              pendingAction: PendingCityExpansionSelection(
                ownerPlayerId: 'player_1',
                cityId: 'city_1',
              ),
            ),
          ),
        )
        ..syncHoverIntentForTesting(_tile(map, 0, 2));

      expect(game.hoverIntentKindForTesting, HoverIntentKind.founding);
      expect(game.hoverIntentTileForTesting, (col: 0, row: 2));
      expect(game.hoverIntentColorValueForTesting, HudPalette.gold.toARGB32());
    });

    test('worker action selection shows a worker marker', () async {
      final map = _map();
      final worker = GameUnit.produced(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        col: 0,
        row: 0,
      );
      final game = await _loadedGame(map);

      game
        ..applyState(
          GameClientState(
            units: [worker],
            interaction: const InteractionState(
              pendingAction: PendingWorkerActionSelection(
                ownerPlayerId: 'player_1',
                unitId: 'worker_1',
                improvementType: FieldImprovementType.farm,
              ),
            ),
          ),
        )
        ..syncHoverIntentForTesting(_tile(map, 2, 2));

      expect(game.hoverIntentKindForTesting, HoverIntentKind.worker);
      expect(game.hoverIntentTileForTesting, (col: 2, row: 2));
      expect(game.hoverIntentColorValueForTesting, HudPalette.info.toARGB32());
    });

    test('force inspect shows an inspect marker', () async {
      final map = _map();
      final game = await _loadedGame(map);

      game
        ..applyState(GameClientState())
        ..syncHoverIntentForTesting(_tile(map, 2, 0), forceInspect: true);

      expect(game.hoverIntentKindForTesting, HoverIntentKind.inspect);
      expect(game.hoverIntentTileForTesting, (col: 2, row: 0));
      expect(game.hoverIntentColorValueForTesting, HudPalette.info.toARGB32());
    });

    test(
      'force inspect still suppresses hidden fog during move targeting',
      () async {
        final map = _map();
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final fog = FogOfWarState.empty.updatePlayer(
          PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 0, row: 0)},
          ),
        );
        final game = await _loadedGame(map);

        game
          ..applyState(
            GameClientState(
              activePlayerId: 'player_1',
              fogOfWar: fog,
              units: [commander],
              interaction: InteractionState(
                selection: GameSelection.unit(
                  commander,
                  tile: _tile(map, 0, 0),
                ),
                moveCommandActive: true,
              ),
            ),
          )
          ..syncHoverIntentForTesting(_tile(map, 1, 1), forceInspect: true);

        expect(game.hoverIntentKindForTesting, isNull);
        expect(game.hoverIntentTileForTesting, isNull);
      },
    );

    test('long press previews tile inspection and selects a tile', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final events = <String>[];
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
        onTileInspectionPreviewed: (tile, _) =>
            events.add('preview:${tile.col},${tile.row}'),
        onTileInspectionConfirmed: () => events.add('confirm'),
        onTileInspectionCanceled: () => events.add('cancel'),
      );

      game.handleTileLongPressedForTesting(_tile(map, 2, 1));

      expect(events, ['preview:2,1']);
      expect(commands, [const SelectTileCommand(2, 1)]);
    });

    test(
      'long press on an undiscovered tile does not preview or select',
      () async {
        final map = _map();
        final commands = <GameIntent>[];
        final events = <String>[];
        final fog = FogOfWarState.empty.updatePlayer(
          PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 0, row: 0)},
          ),
        );
        final game = await _loadedGame(
          map,
          onCommand: (command) async => commands.add(command),
          onTileInspectionPreviewed: (tile, _) =>
              events.add('preview:${tile.col},${tile.row}'),
          onTileInspectionConfirmed: () => events.add('confirm'),
          onTileInspectionCanceled: () => events.add('cancel'),
        );
        final tile = _tile(map, 2, 1);

        game
          ..applyState(
            GameClientState(activePlayerId: 'player_1', fogOfWar: fog),
          )
          ..handleTileLongPressedForTesting(tile)
          ..confirmTileInspectionForTesting();
        await game.handleTileTappedForTesting(tile);

        expect(events, isEmpty);
        expect(commands, isEmpty);
        expect(game.hoverIntentKindForTesting, isNull);
      },
    );

    test('confirmed long press suppresses the follow-up tile tap', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
      );
      final tile = _tile(map, 2, 1);

      game
        ..handleTileLongPressedForTesting(tile)
        ..confirmTileInspectionForTesting();
      await game.handleTileTappedForTesting(tile);
      await game.handleTileTappedForTesting(tile);

      expect(commands, [const SelectTileCommand(2, 1)]);

      game
        ..handleViewportPointerDown(99, Vector2.zero())
        ..handleViewportPointerUp(99);
      await game.handleTileTappedForTesting(tile);

      expect(commands, [
        const SelectTileCommand(2, 1),
        const TileTappedCommand(2, 1),
      ]);
    });

    test('long press start suppresses a tile tap before confirm', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
      );
      final tile = _tile(map, 2, 1);

      game.handleTileLongPressedForTesting(tile);
      await game.handleTileTappedForTesting(tile);
      await game.handleTileTappedForTesting(tile);

      expect(commands, [const SelectTileCommand(2, 1)]);

      game
        ..confirmTileInspectionForTesting()
        ..handleViewportPointerDown(99, Vector2.zero())
        ..handleViewportPointerUp(99);
      await game.handleTileTappedForTesting(tile);

      expect(commands, [
        const SelectTileCommand(2, 1),
        const TileTappedCommand(2, 1),
      ]);
    });

    test('long press cancels unit move mode before tile inspection', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final events = <String>[];
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
        onTileInspectionPreviewed: (tile, _) =>
            events.add('preview:${tile.col},${tile.row}'),
      );
      final tile = _tile(map, 2, 1);
      final movingState = GameClientState(
        units: [commander],
        interaction: InteractionState(
          selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
          moveCommandActive: true,
        ),
      );

      game
        ..applyState(movingState)
        ..handleTileLongPressedForTesting(tile)
        ..confirmTileInspectionForTesting();

      expect(events, isEmpty);
      expect(commands, [const ToggleMoveTargetingCommand()]);

      game
        ..applyState(movingState.copyWithInteraction(moveCommandActive: false))
        ..handleViewportPointerDown(99, Vector2.zero())
        ..handleViewportPointerUp(99)
        ..handleTileLongPressedForTesting(tile)
        ..confirmTileInspectionForTesting();

      expect(events, ['preview:2,1']);
      expect(commands, [
        const ToggleMoveTargetingCommand(),
        const SelectTileCommand(2, 1),
      ]);
    });

    test('long press inspects a tile while a city is selected', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final events = <String>[];
      final city = _city(id: 'city_1', col: 0, row: 0);
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
        onTileInspectionPreviewed: (tile, _) =>
            events.add('preview:${tile.col},${tile.row}'),
      );
      final tile = _tile(map, 2, 1);

      game
        ..applyState(
          GameClientState(
            cities: [city],
            interaction: InteractionState(
              selection: GameSelection.city(
                city,
                cityYield: TileYield.zero,
                playerColor: 0xFF4477AA,
              ),
            ),
          ),
        )
        ..handleTileLongPressedForTesting(tile)
        ..confirmTileInspectionForTesting();

      expect(events, ['preview:2,1']);
      expect(commands, [const SelectTileCommand(2, 1)]);
    });

    test('long press cancel clears tile inspection preview', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final events = <String>[];
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
        onTileInspectionPreviewed: (tile, _) =>
            events.add('preview:${tile.col},${tile.row}'),
        onTileInspectionConfirmed: () => events.add('confirm'),
        onTileInspectionCanceled: () => events.add('cancel'),
      );
      final tile = _tile(map, 1, 1);

      game
        ..handleTileLongPressedForTesting(tile)
        ..cancelTileInspectionForTesting();
      await game.handleTileTappedForTesting(tile);

      expect(events, ['preview:1,1', 'cancel']);
      expect(commands, [const SelectTileCommand(1, 1)]);
    });

    test('hidden fog tile suppresses hover markers', () async {
      final map = _map();
      const visibleHex = HexCoordinate(col: 0, row: 0);
      final fog = FogOfWarState.empty.updatePlayer(
        PlayerFogOfWar(playerId: 'player_1', visibleHexes: {visibleHex}),
      );
      final game = await _loadedGame(map);

      game
        ..applyState(
          GameClientState(
            activePlayerId: 'player_1',
            fogOfWar: fog,
            interaction: const InteractionState(moveCommandActive: true),
          ),
        )
        ..syncHoverIntentForTesting(_tile(map, 1, 1));

      expect(game.hoverIntentKindForTesting, isNull);

      game.syncHoverIntentForTesting(_tile(map, 0, 0));

      expect(game.hoverIntentKindForTesting, HoverIntentKind.move);
      expect(game.hoverIntentTileForTesting, (col: 0, row: 0));
    });

    test('pointer exit clears the active hover marker', () async {
      final map = _map();
      final game = await _loadedGame(map);

      game
        ..applyState(
          GameClientState(
            interaction: const InteractionState(moveCommandActive: true),
          ),
        )
        ..syncHoverIntentForTesting(_tile(map, 1, 1));

      expect(game.hoverIntentKindForTesting, HoverIntentKind.move);

      game.handleViewportPointerExit();

      expect(game.hoverIntentKindForTesting, isNull);
    });
  });
}

Future<ui.Rect?> _paintedMoveCueBounds(HoverIntentMarker marker) async {
  const imageSize = 160;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final worldCenter = HexGeometry.topFaceCentroid(col: 0, row: 0);
  canvas.translate(80 - worldCenter.dx, 80 - worldCenter.dy);
  marker.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(imageSize, imageSize);
  picture.dispose();
  final bytes = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  image.dispose();
  if (bytes == null) return null;

  var left = imageSize;
  var top = imageSize;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < imageSize; y++) {
    for (var x = 0; x < imageSize; x++) {
      final alpha = bytes.getUint8(((y * imageSize) + x) * 4 + 3);
      if (alpha == 0) continue;
      left = math.min(left, x);
      top = math.min(top, y);
      right = math.max(right, x);
      bottom = math.max(bottom, y);
    }
  }
  if (right < left || bottom < top) return null;
  return ui.Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    (right + 1).toDouble(),
    (bottom + 1).toDouble(),
  );
}

Future<GameRenderer> _loadedGame(
  WorldMap map, {
  Future<void> Function(GameIntent command)? onCommand,
  TileInspectionCallback? onTileInspectionPreviewed,
  VoidCallback? onTileInspectionConfirmed,
  VoidCallback? onTileInspectionCanceled,
}) async {
  final game = GameRenderer(
    mapData: map,
    onCommand: onCommand ?? (_) async {},
    onTileInspectionPreviewed: onTileInspectionPreviewed,
    onTileInspectionConfirmed: onTileInspectionConfirmed,
    onTileInspectionCanceled: onTileInspectionCanceled,
  );
  addTearDown(game.disposeRenderer);
  game.onGameResize(Vector2(800, 600));
  await game.onLoad();
  return game;
}

WorldMap _map({CityHex? blockedHex, int cols = 3, int rows = 3}) => WorldMap(
  cols: cols,
  rows: rows,
  tiles: [
    for (int row = 0; row < rows; row++)
      for (int col = 0; col < cols; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: blockedHex?.col == col && blockedHex?.row == row
              ? const [TerrainType.grassland, TerrainType.mountain]
              : const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

WorldTile _tile(WorldMap map, int col, int row) {
  return map.tiles.firstWhere((tile) => tile.col == col && tile.row == row);
}

GameCity _city({required String id, required int col, required int row}) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: id,
    center: CityHex(col: col, row: row),
    controlledHexes: [CityHex(col: col, row: row)],
  );
}
