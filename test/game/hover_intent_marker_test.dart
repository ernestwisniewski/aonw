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
import 'package:flutter_test/flutter_test.dart';

part 'hover_intent_marker_test_support.dart';

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

    test('rapid double tap directly selects a plain hex', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
      );
      final tile = _tile(map, 2, 1);

      await game.handleRapidTileDoubleTapForTesting(tile);

      expect(commands, [
        const TileTappedCommand(2, 1),
        const SelectTileCommand(2, 1),
      ]);
    });

    test(
      'long press opens a terrain selection palette without selecting',
      () async {
        final map = _map();
        final commands = <GameIntent>[];
        final game = await _loadedGame(
          map,
          onCommand: (command) async => commands.add(command),
        );

        game.handleTileLongPressedForTesting(_tile(map, 2, 1));

        expect(game.hexSelectionPaletteVisibleForTesting, isTrue);
        expect(
          game.hexSelectionPaletteForTesting!.targets.map(
            (target) => target.key,
          ),
          ['terrain:2:1'],
        );
        expect(commands, isEmpty);
      },
    );

    test(
      'long press on an undiscovered tile does not open a palette',
      () async {
        final map = _map();
        final commands = <GameIntent>[];
        final fog = FogOfWarState.empty.updatePlayer(
          PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 0, row: 0)},
          ),
        );
        final game = await _loadedGame(
          map,
          onCommand: (command) async => commands.add(command),
        );
        final tile = _tile(map, 2, 1);

        game
          ..applyState(
            GameClientState(activePlayerId: 'player_1', fogOfWar: fog),
          )
          ..handleTileLongPressedForTesting(tile)
          ..finishTileLongPressForTesting();
        await game.handleTileTappedForTesting(tile);

        expect(game.hexSelectionPaletteVisibleForTesting, isFalse);
        expect(commands, isEmpty);
        expect(game.hoverIntentKindForTesting, isNull);
      },
    );

    test(
      'finished long press keeps the palette and suppresses its tap',
      () async {
        final map = _map();
        final commands = <GameIntent>[];
        final game = await _loadedGame(
          map,
          onCommand: (command) async => commands.add(command),
        );
        final tile = _tile(map, 2, 1);

        game
          ..handleTileLongPressedForTesting(tile)
          ..finishTileLongPressForTesting();
        await game.handleTileTappedForTesting(tile);

        expect(commands, isEmpty);
        expect(game.hexSelectionPaletteVisibleForTesting, isTrue);

        game
          ..handleViewportPointerDown(99, Vector2.zero())
          ..handleViewportPointerUp(99);
        await game.handleTileTappedForTesting(tile);

        expect(commands, [const TileTappedCommand(2, 1)]);
        expect(game.hexSelectionPaletteVisibleForTesting, isFalse);
      },
    );

    test(
      'terrain palette target selects the hex and opens inspection',
      () async {
        final map = _map();
        final commands = <GameIntent>[];
        final inspections = <String>[];
        final game = await _loadedGame(
          map,
          onCommand: (command) async => commands.add(command),
          onTileInspected: (tile, _) =>
              inspections.add('${tile.col},${tile.row}'),
        );

        game.handleTileLongPressedForTesting(_tile(map, 1, 2));
        game.hexSelectionPaletteForTesting!.selectForTesting('terrain:1:2');
        await Future<void>.delayed(Duration.zero);

        expect(commands, [const SelectTileCommand(1, 2)]);
        expect(inspections, ['1,2']);
        expect(game.hexSelectionPaletteVisibleForTesting, isFalse);
      },
    );

    test('long press cancels unit move mode before opening palette', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
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
        ..finishTileLongPressForTesting();

      expect(game.hexSelectionPaletteVisibleForTesting, isFalse);
      expect(commands, [const ToggleMoveTargetingCommand()]);

      game
        ..applyState(movingState.copyWithInteraction(moveCommandActive: false))
        ..handleViewportPointerDown(99, Vector2.zero())
        ..handleViewportPointerUp(99)
        ..handleTileLongPressedForTesting(tile)
        ..finishTileLongPressForTesting();

      expect(game.hexSelectionPaletteVisibleForTesting, isTrue);
      expect(commands, [const ToggleMoveTargetingCommand()]);
    });

    test(
      'long press palette is independent from the current city selection',
      () async {
        final map = _map();
        final commands = <GameIntent>[];
        final city = _city(id: 'city_1', col: 0, row: 0);
        final game = await _loadedGame(
          map,
          onCommand: (command) async => commands.add(command),
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
          ..finishTileLongPressForTesting();

        expect(game.hexSelectionPaletteVisibleForTesting, isTrue);
        expect(commands, isEmpty);
      },
    );

    test('canceling long press clears its palette', () async {
      final map = _map();
      final commands = <GameIntent>[];
      final game = await _loadedGame(
        map,
        onCommand: (command) async => commands.add(command),
      );
      final tile = _tile(map, 1, 1);

      game
        ..handleTileLongPressedForTesting(tile)
        ..cancelTileLongPressForTesting();
      await game.handleTileTappedForTesting(tile);

      expect(game.hexSelectionPaletteVisibleForTesting, isFalse);
      expect(commands, isEmpty);
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
