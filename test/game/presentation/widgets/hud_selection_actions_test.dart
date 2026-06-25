import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_selection_actions.dart';
import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildHudSelectionActionChips', () {
    test('keeps unit actions visible but disabled while locked', () {
      final worker = _worker();

      final actions = _actions(
        gameState: GameState(
          units: [worker],
          selection: GameSelection.unit(worker),
        ),
        actionsLocked: true,
        workerAction: _workerAction(),
      );

      expect(_actionLabels(actions), ['Move', 'Improve', 'Skip', 'Fortify']);
      expect(
        actions.whereType<SelectionCommandChip>(),
        everyElement(
          isA<SelectionCommandChip>().having(
            (action) => action.enabled,
            'enabled',
            isFalse,
          ),
        ),
      );
    });

    test('builds worker unit actions', () {
      final worker = _worker();

      final actions = _actions(
        gameState: GameState(
          units: [worker],
          selection: GameSelection.unit(worker),
        ),
        workerAction: _workerAction(),
      );

      expect(
        _actionLabels(actions),
        containsAll(['Move', 'Improve', 'Skip', 'Fortify']),
      );
    });

    test('uses artifact icon for the unit store artifact action', () {
      final unit = _warrior().copyWithCarriedArtifact('artifact_1');
      final city = _city();

      final actions = _actions(
        gameState: GameState(
          units: [unit],
          cities: [city],
          selection: GameSelection.unit(unit),
        ),
      );
      final action = _action(actions, 'Store');

      expect(action?.actionId, 'storeArtifact');
      expect(action?.icon, GameIcons.artifact);
      expect(action?.color, const Color(0xFFA78BFA));
      expect(action?.enabled, isTrue);
    });

    test('wraps unit special actions with toolbar separators', () {
      final worker = _worker();
      final scout = _scout();
      final settler = _settler();
      final warrior = _warrior();
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');

      expect(
        _actionLayout(
          _actions(
            gameState: GameState(
              units: [worker],
              selection: GameSelection.unit(worker),
            ),
            workerAction: _workerAction(),
          ),
        ),
        ['Move', '|', 'Improve', '|', 'Skip', 'Fortify'],
      );
      expect(
        _actionLayout(
          _actions(
            gameState: GameState(
              units: [warrior],
              selection: GameSelection.unit(warrior),
            ),
          ),
        ),
        ['Move', '|', 'Attack', '|', 'Skip', 'Fortify'],
      );
      expect(
        _actionLayout(
          _actions(
            gameState: GameState(
              units: [scout],
              selection: GameSelection.unit(scout),
            ),
          ),
        ),
        ['Move', '|', 'Attack', '|', 'Explore', '|', 'Skip', 'Fortify'],
      );
      expect(
        _actionLayout(
          _actions(
            gameState: GameState(
              units: [settler],
              selection: GameSelection.unit(settler),
            ),
            canStartCityFounding: true,
          ),
        ),
        ['Move', '|', 'Found city', '|', 'Skip', 'Fortify'],
      );
      expect(
        _actionLayout(
          _actions(
            gameState: GameState(
              units: [commander],
              selection: GameSelection.unit(commander),
            ),
            armyDetailActive: true,
            canStartCityFounding: true,
          ),
        ),
        [
          'Move',
          '|',
          'Attack',
          '|',
          'Army',
          '|',
          'Found city',
          '|',
          'Skip',
          'Fortify',
        ],
      );
    });

    test('builds merchant trade route action instead of movement', () {
      final merchant = _merchant();
      final origin = _city();
      final destination = _city(id: 'city_2', name: 'Port', col: 2);
      var routeSelectionStarted = false;
      var moveToCitySelectionStarted = false;

      final actions = _actions(
        gameState: GameState(
          units: [merchant],
          cities: [origin, destination],
          selection: GameSelection.unit(merchant),
        ),
        mapData: _mapData(cols: 3, rows: 1),
        onStartMerchantTradeRouteSelection: () {
          routeSelectionStarted = true;
        },
        onStartMerchantMoveToCitySelection: () {
          moveToCitySelectionStarted = true;
        },
      );

      expect(_action(actions, 'Move'), isNull);
      final tradeRoute = _action(actions, 'Trade route');
      expect(tradeRoute, isNotNull);
      expect(tradeRoute?.enabled, isTrue);
      final moveToCity = _action(actions, 'Go to city');
      expect(moveToCity, isNotNull);
      expect(moveToCity?.enabled, isTrue);

      tradeRoute?.onTap?.call();
      moveToCity?.onTap?.call();

      expect(routeSelectionStarted, isTrue);
      expect(moveToCitySelectionStarted, isTrue);
    });

    test('builds destination actions while selecting merchant trade route', () {
      final merchant = _merchant();
      final origin = _city();
      final destination = _city(id: 'city_2', name: 'Port', col: 2);
      String? assignedCityId;

      final actions = _actions(
        gameState: GameState(
          units: [merchant],
          cities: [origin, destination],
          selection: GameSelection.unit(merchant),
          pendingAction: PendingMerchantTradeRouteSelection(
            ownerPlayerId: merchant.ownerPlayerId,
            unitId: merchant.id,
          ),
        ),
        mapData: _mapData(cols: 3, rows: 1),
        onAssignMerchantTradeRoute: (cityId) {
          assignedCityId = cityId;
        },
      );

      expect(_actionLabels(actions), [
        'Trade with Port',
        'Cancel trade route selection',
      ]);

      _action(actions, 'Trade with Port')?.onTap?.call();

      expect(assignedCityId, destination.id);
    });

    test('builds destination actions while selecting merchant city travel', () {
      final merchant = _merchant(col: 1);
      final destination = _city(id: 'city_2', name: 'Port', col: 2);
      String? targetCityId;

      final actions = _actions(
        gameState: GameState(
          units: [merchant],
          cities: [destination],
          selection: GameSelection.unit(merchant),
          pendingAction: PendingMerchantMoveToCitySelection(
            ownerPlayerId: merchant.ownerPlayerId,
            unitId: merchant.id,
          ),
        ),
        mapData: _mapData(cols: 3, rows: 1),
        onMoveMerchantToCity: (cityId) {
          targetCityId = cityId;
        },
      );

      expect(_actionLabels(actions), ['Go to Port', 'Cancel city travel']);

      _action(actions, 'Go to Port')?.onTap?.call();

      expect(targetCityId, destination.id);
    });

    test('keeps regular unit toolbar actions icon-only across unit types', () {
      final worker = _actions(
        gameState: GameState(
          units: [_worker()],
          selection: GameSelection.unit(_worker()),
        ),
        workerAction: _workerAction(),
      );
      final scout = _actions(
        gameState: GameState(
          units: [_scout()],
          selection: GameSelection.unit(_scout()),
        ),
      );
      final settler = _actions(
        gameState: GameState(
          units: [_settler()],
          selection: GameSelection.unit(_settler()),
        ),
        canStartCityFounding: true,
      );
      final warrior = _actions(
        gameState: GameState(
          units: [_warrior()],
          selection: GameSelection.unit(_warrior()),
        ),
      );

      for (final actions in [worker, scout, settler, warrior]) {
        expect(
          actions.whereType<SelectionCommandChip>(),
          everyElement(
            isA<SelectionCommandChip>().having(
              (action) => action.showLabel,
              'showLabel',
              isFalse,
            ),
          ),
        );
      }
    });

    test('keeps manual worker improve action', () {
      final worker = _worker();
      var improveStarted = false;

      final actions = _actions(
        gameState: GameState(
          units: [worker],
          selection: GameSelection.unit(worker),
        ),
        workerAction: _workerAction(),
        onStartWorkerActionSelection: () => improveStarted = true,
      );

      expect(_action(actions, 'Improve')?.enabled, isTrue);
      expect(_action(actions, 'Improve')?.color, GameUiTheme.success);
      expect(_action(actions, 'Improve')?.pulseBorder, isTrue);

      _action(actions, 'Improve')?.onTap?.call();

      expect(improveStarted, isTrue);
    });

    test('disables worker improve while a move path is queued', () {
      final worker = _worker().copyWithQueuedPath(
        QueuedMovePath(targetCol: 2, targetRow: 1, steps: const []),
      );

      final actions = _actions(
        gameState: GameState(
          units: [worker],
          selection: GameSelection.unit(worker),
        ),
        workerAction: _workerAction(),
      );
      final improve = _action(actions, 'Improve');

      expect(improve?.enabled, isFalse);
      expect(improve?.disabledReason, 'Cancel the current move first.');
    });

    test('builds scout auto-explore action', () {
      final scout = _scout();
      var autoExploreStarted = false;

      final actions = _actions(
        gameState: GameState(
          units: [scout],
          selection: GameSelection.unit(scout),
        ),
        onAutoExploreSelectedUnit: () => autoExploreStarted = true,
      );

      expect(_actionLabels(actions), [
        'Move',
        'Attack',
        'Explore',
        'Skip',
        'Fortify',
      ]);
      expect(_action(actions, 'Explore')?.enabled, isTrue);
      expect(_action(actions, 'Explore')?.color, GameUiTheme.info);
      expect(_action(actions, 'Explore')?.pulseBorder, isTrue);

      _action(actions, 'Explore')?.onTap?.call();

      expect(autoExploreStarted, isTrue);
    });

    test('active scout auto-explore shows cancel action', () {
      final scout = _scout().copyWith(posture: UnitPosture.autoExploring);
      var cancelled = false;

      final actions = _actions(
        gameState: GameState(
          units: [scout],
          selection: GameSelection.unit(scout),
        ),
        onCancelSelectedUnitAction: () => cancelled = true,
      );
      final finish = _action(actions, 'Cancel exploration');

      expect(_actionLabels(actions), ['Cancel exploration']);
      expect(finish?.active, isTrue);
      expect(finish?.enabled, isTrue);
      expect(finish?.showLabel, isTrue);
      expect(finish?.dangerOutlined, isTrue);
      expect(finish?.mainExtent, SelectionCommandChip.expandedLabeledExtent);

      finish?.onTap?.call();

      expect(cancelled, isTrue);
    });

    test('worker build selection shows cancel action', () {
      final worker = _worker();
      var cancelled = false;

      final actions = _actions(
        gameState: GameState(
          units: [worker],
          selection: GameSelection.unit(worker),
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: worker.ownerPlayerId,
            unitId: worker.id,
          ),
        ),
        workerAction: _workerAction(selectionActive: true),
        onCancelWorkerActionSelection: () => cancelled = true,
      );

      final finish = _action(actions, 'Cancel improvement build');

      expect(_actionLabels(actions), ['Cancel improvement build']);
      expect(finish?.active, isTrue);
      expect(finish?.enabled, isTrue);
      expect(finish?.showLabel, isTrue);
      expect(finish?.dangerOutlined, isTrue);
      expect(finish?.mainExtent, SelectionCommandChip.expandedLabeledExtent);

      finish?.onTap?.call();

      expect(cancelled, isTrue);
    });

    test('active worker job shows cancel action', () {
      final worker = _worker();
      var cancelled = false;

      final actions = _actions(
        gameState: GameState(
          units: [worker],
          selection: GameSelection.unit(worker),
        ),
        workerAction: _workerAction(activeJob: true),
        onCancelWorkerJob: () => cancelled = true,
      );

      final finish = _action(actions, 'Cancel improvement build');

      expect(_actionLabels(actions), ['Cancel improvement build']);
      expect(finish?.active, isTrue);
      expect(finish?.enabled, isTrue);
      expect(finish?.showLabel, isTrue);
      expect(finish?.dangerOutlined, isTrue);
      expect(finish?.mainExtent, SelectionCommandChip.expandedLabeledExtent);

      finish?.onTap?.call();

      expect(cancelled, isTrue);
    });

    test('active settler city founding job shows cancel action', () {
      final settler = _settler().copyWithCityFoundingJob(
        CityFoundingJob(
          center: const CityHex(col: 0, row: 0),
          controlledHexes: const [
            CityHex(col: 0, row: 0),
            CityHex(col: 1, row: 0),
            CityHex(col: 0, row: 1),
          ],
          remainingTurns: 1,
          totalTurns: 1,
        ),
      );
      var cancelled = false;

      final actions = _actions(
        gameState: GameState(
          units: [settler],
          selection: GameSelection.unit(settler),
        ),
        onCancelSelectedUnitAction: () => cancelled = true,
      );

      final finish = _action(actions, 'Cancel city founding');

      expect(_actionLabels(actions), ['Cancel city founding']);
      expect(finish?.active, isTrue);
      expect(finish?.enabled, isTrue);
      expect(finish?.showLabel, isTrue);
      expect(finish?.dangerOutlined, isTrue);
      expect(finish?.mainExtent, SelectionCommandChip.expandedLabeledExtent);

      finish?.onTap?.call();

      expect(cancelled, isTrue);
    });

    test('active artifact excavation shows cancel action', () {
      final scout = _scout().copyWith(excavatingArtifactId: 'artifact_1');
      var cancelled = false;

      final actions = _actions(
        gameState: GameState(
          units: [scout],
          selection: GameSelection.unit(scout),
        ),
        onCancelSelectedUnitAction: () => cancelled = true,
      );

      final finish = _action(actions, 'Cancel artifact excavation');

      expect(_actionLabels(actions), ['Cancel artifact excavation']);
      expect(finish?.active, isTrue);
      expect(finish?.enabled, isTrue);

      finish?.onTap?.call();

      expect(cancelled, isTrue);
    });

    test('keeps move enabled at 0 MP so the player can queue a route', () {
      final warrior = _warrior().copyWith(movementPoints: 0);

      final actions = _actions(
        gameState: GameState(
          units: [warrior],
          selection: GameSelection.unit(warrior),
        ),
      );

      expect(_actionLabels(actions), ['Move', 'Attack', 'Skip', 'Fortify']);
      expect(_action(actions, 'Move')?.enabled, isTrue);
      expect(_action(actions, 'Attack')?.enabled, isFalse);
      expect(_action(actions, 'Skip')?.enabled, isFalse);
      expect(_action(actions, 'Fortify')?.enabled, isFalse);
    });

    test('shows turns-remaining badge on Move when a queued path exists', () {
      // A warrior's max MP is 3 (foot unit). With cumulativeCost = 4 the path
      // takes ceil(4/3) = 2 turns to finish from a fresh 0-MP state.
      final warrior = _warrior()
          .copyWithQueuedPath(
            QueuedMovePath(
              targetCol: 2,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 2,
                  cumulativeCost: 2,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 2,
                  cumulativeCost: 4,
                ),
              ],
            ),
          )
          .copyWith(movementPoints: 0);

      final actions = _actions(
        gameState: GameState(
          units: [warrior],
          selection: GameSelection.unit(warrior),
        ),
      );

      expect(_action(actions, 'Move')?.badgeLabel, '2');
      expect(_action(actions, 'Move')?.dangerOutlined, isTrue);
    });

    test(
      'recomputes Move badge from the unit position after a partial move',
      () {
        // Same path as the previous test (total cumulativeCost 4), but the
        // unit has already advanced to (1,0), so 2 cost is already paid.
        // Remaining cost = 2; ceil(2/3) = 1 turn.
        final warrior = _warrior()
            .copyWith(col: 1, row: 0, movementPoints: 0)
            .copyWithQueuedPath(
              QueuedMovePath(
                targetCol: 2,
                targetRow: 0,
                steps: const [
                  UnitMovementStep(
                    col: 1,
                    row: 0,
                    enterCost: 2,
                    cumulativeCost: 2,
                  ),
                  UnitMovementStep(
                    col: 2,
                    row: 0,
                    enterCost: 2,
                    cumulativeCost: 4,
                  ),
                ],
              ),
            );

        final actions = _actions(
          gameState: GameState(
            units: [warrior],
            selection: GameSelection.unit(warrior),
          ),
        );

        expect(_action(actions, 'Move')?.badgeLabel, '1');
      },
    );

    test('shows no badge on Move when there is no queued path', () {
      final warrior = _warrior();

      final actions = _actions(
        gameState: GameState(
          units: [warrior],
          selection: GameSelection.unit(warrior),
        ),
      );

      expect(_action(actions, 'Move')?.badgeLabel, isNull);
    });

    test('pulses skip action when unit has one movement point', () {
      final lowMovement = _warrior().copyWith(movementPoints: 1);
      final fresh = _warrior(id: 'warrior_2').copyWith(movementPoints: 2);

      final lowMovementActions = _actions(
        gameState: GameState(
          units: [lowMovement],
          selection: GameSelection.unit(lowMovement),
        ),
      );
      final freshActions = _actions(
        gameState: GameState(
          units: [fresh],
          selection: GameSelection.unit(fresh),
        ),
      );

      expect(_action(lowMovementActions, 'Skip')?.pulseBorder, isTrue);
      expect(_action(freshActions, 'Skip')?.pulseBorder, isFalse);
    });

    test('active skip action uses the cancel outline style', () {
      final warrior = _warrior();
      var cancelled = false;

      final actions = _actions(
        gameState: GameState(
          units: [warrior],
          selection: GameSelection.unit(warrior),
          pendingAction: PendingUnitTurnSkip(
            ownerPlayerId: warrior.ownerPlayerId,
            unitId: warrior.id,
            restoreMovementPoints: warrior.movementPoints,
          ),
        ),
        onCancelSelectedUnitAction: () => cancelled = true,
      );
      final action = _action(actions, 'Skip');

      expect(action?.active, isTrue);
      expect(action?.dangerOutlined, isTrue);

      action?.onTap?.call();

      expect(cancelled, isTrue);
    });

    test('queued move action uses the cancel outline style', () {
      final warrior = _warrior().copyWithQueuedPath(_queuedPath());
      var cancelled = false;

      final actions = _actions(
        gameState: GameState(
          units: [warrior],
          selection: GameSelection.unit(warrior),
        ),
        onCancelSelectedUnitAction: () => cancelled = true,
      );
      final action = _action(actions, 'Move');

      expect(action?.active, isTrue);
      expect(action?.dangerOutlined, isTrue);

      action?.onTap?.call();

      expect(cancelled, isTrue);
    });

    test('keeps commander army action available without movement', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
      ).copyWith(movementPoints: 0);

      final actions = _actions(
        gameState: GameState(
          units: [commander],
          selection: GameSelection.unit(commander),
        ),
        armyDetailActive: true,
      );

      expect(_actionLabels(actions), [
        'Move',
        'Attack',
        'Army',
        'Found city',
        'Skip',
        'Fortify',
      ]);
      expect(_action(actions, 'Army')?.enabled, isTrue);
      expect(_action(actions, 'Army')?.active, isTrue);
      expect(_action(actions, 'Found city')?.enabled, isFalse);
      expect(_action(actions, 'Found city')?.pulseBorder, isFalse);
    });

    test('commander merge selection shows descriptive cancel action', () {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      var cancelled = false;

      final actions = _actions(
        gameState: GameState(
          units: [commander],
          selection: GameSelection.unit(commander),
          pendingAction: PendingCommanderMergeSelection(
            ownerPlayerId: commander.ownerPlayerId,
            commanderUnitId: commander.id,
          ),
        ),
        onCancelSelectedUnitAction: () => cancelled = true,
      );

      final action = _action(actions, 'Cancel troop merge');

      expect(_actionLabels(actions), ['Cancel troop merge']);
      expect(action?.actionId, 'cancel');
      expect(action?.active, isTrue);
      expect(action?.showLabel, isTrue);
      expect(action?.dangerOutlined, isTrue);

      action?.onTap?.call();

      expect(cancelled, isTrue);
    });

    test('highlights settler city founding when it can start', () {
      final settler = _settler();

      final actions = _actions(
        gameState: GameState(
          units: [settler],
          selection: GameSelection.unit(settler),
        ),
        canStartCityFounding: true,
      );

      final foundCity = _action(actions, 'Found city');

      expect(foundCity?.enabled, isTrue);
      expect(foundCity?.color, GameUiTheme.success);
      expect(foundCity?.pulseBorder, isTrue);
    });

    test(
      'keeps settler city founding action disabled when it cannot start',
      () {
        final settler = _settler();

        final actions = _actions(
          gameState: GameState(
            units: [settler],
            selection: GameSelection.unit(settler),
          ),
        );

        expect(_actionLabels(actions), [
          'Move',
          'Found city',
          'Skip',
          'Fortify',
        ]);
        expect(_action(actions, 'Found city')?.enabled, isFalse);
        expect(_action(actions, 'Found city')?.disabledReason, isNotNull);
      },
    );

    test('replaces active city founding actions with cancel before ready', () {
      final settler = _settler();
      var started = false;
      var cancelled = false;

      final actions = _actions(
        gameState: GameState(
          units: [settler],
          selection: GameSelection.unit(settler),
        ),
        cityFoundingActive: true,
        onStartCityFounding: () => started = true,
        onCancelCityFounding: () => cancelled = true,
      );

      final action = _action(actions, 'Cancel city founding');

      expect(_actionLabels(actions), ['Cancel city founding']);
      expect(action?.enabled, isTrue);
      expect(action?.active, isTrue);
      expect(action?.showLabel, isTrue);
      expect(action?.dangerOutlined, isTrue);
      expect(action?.mainExtent, SelectionCommandChip.expandedLabeledExtent);

      action?.onTap?.call();

      expect(started, isFalse);
      expect(cancelled, isTrue);
    });

    test('shows found city next to cancel when city founding is ready', () {
      final settler = _settler();
      var confirmed = false;
      var cancelled = false;

      final actions = _actions(
        gameState:
            GameState(
              units: [settler],
              selection: GameSelection.unit(settler),
            ).copyWith(
              cityFoundingDraft: CityFoundingDraft(
                unitId: settler.id,
                ownerPlayerId: settler.ownerPlayerId,
                center: const CityHex(col: 0, row: 0),
                controlledHexes: const [
                  CityHex(col: 1, row: 0),
                  CityHex(col: 0, row: 1),
                ],
              ),
            ),
        cityFoundingActive: true,
        onConfirmCityFounding: () => confirmed = true,
        onCancelCityFounding: () => cancelled = true,
      );

      expect(_actionLabels(actions), ['Found city', 'Cancel']);
      expect(_action(actions, 'Found city')?.enabled, isTrue);
      expect(_action(actions, 'Found city')?.showLabel, isTrue);
      expect(_action(actions, 'Cancel')?.enabled, isTrue);
      expect(_action(actions, 'Cancel')?.showLabel, isTrue);
      expect(_action(actions, 'Cancel')?.dangerOutlined, isTrue);
      expect(
        _action(actions, 'Found city')?.mainExtent,
        SelectionCommandChip.labeledExtent,
      );
      expect(
        _action(actions, 'Cancel')?.mainExtent,
        SelectionCommandChip.labeledExtent,
      );

      _action(actions, 'Found city')?.onTap?.call();
      _action(actions, 'Cancel')?.onTap?.call();

      expect(confirmed, isTrue);
      expect(cancelled, isTrue);
    });

    test('enables attack action when a visible enemy is in range', () {
      final warrior = _warrior();
      final enemy = _warrior(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        col: 1,
        row: 0,
      );

      final actions = _actions(
        gameState: GameState(
          units: [warrior, enemy],
          selection: GameSelection.unit(warrior),
        ),
      );

      expect(_action(actions, 'Attack')?.enabled, isTrue);
      expect(_action(actions, 'Attack')?.badgeLabel, '1');
      expect(_action(actions, 'Attack')?.prominent, isTrue);
      expect(_action(actions, 'Attack')?.pulseBorder, isFalse);
    });

    test('keeps attack action enabled when no enemy is in range', () {
      final warrior = _warrior();
      final enemy = _warrior(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        col: 3,
        row: 0,
      );

      final actions = _actions(
        gameState: GameState(
          units: [warrior, enemy],
          selection: GameSelection.unit(warrior),
        ),
      );

      expect(_action(actions, 'Attack')?.enabled, isTrue);
      expect(_action(actions, 'Attack')?.badgeLabel, isNull);
      expect(_action(actions, 'Attack')?.prominent, isFalse);
    });

    test('counts visible enemy units near the attack action', () {
      final warrior = _warrior();
      final enemy1 = _warrior(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        col: 1,
        row: 0,
      );
      final enemy2 = _warrior(
        id: 'enemy_2',
        ownerPlayerId: 'player_2',
        col: 0,
        row: 1,
      );

      final actions = _actions(
        gameState: GameState(
          units: [warrior, enemy1, enemy2],
          selection: GameSelection.unit(warrior),
        ),
      );

      expect(_action(actions, 'Attack')?.badgeLabel, '2');
    });

    test('replaces active attack actions with cancel', () {
      final warrior = _warrior();
      var cancelled = false;

      final actions = _actions(
        gameState: GameState(
          units: [warrior],
          selection: GameSelection.unit(warrior),
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: warrior.ownerPlayerId,
            attackerUnitId: warrior.id,
          ),
        ),
        onCancelAttackTargeting: () => cancelled = true,
      );

      final action = _action(actions, 'Cancel attack');

      expect(_actionLabels(actions), ['Cancel attack']);
      expect(action?.enabled, isTrue);
      expect(action?.active, isTrue);
      expect(action?.showLabel, isTrue);
      expect(action?.dangerOutlined, isTrue);
      expect(action?.mainExtent, SelectionCommandChip.labeledExtent);

      action?.onTap?.call();

      expect(cancelled, isTrue);
    });

    test(
      'shows stop fortifying as the only fortified unit action at full health',
      () {
        final warrior = _warrior().copyWith(
          movementPoints: 0,
          posture: UnitPosture.fortified,
        );
        var cancelled = false;

        final actions = _actions(
          gameState: GameState(
            units: [warrior],
            selection: GameSelection.unit(warrior),
          ),
          onCancelSelectedUnitAction: () => cancelled = true,
        );

        final action = _action(actions, 'Stop fortifying');

        expect(_actionLabels(actions), ['Stop fortifying']);
        expect(action?.actionId, 'stopFortifying');
        expect(action?.icon, GameIcons.defense);
        expect(action?.enabled, isTrue);
        expect(action?.active, isTrue);
        expect(action?.showLabel, isTrue);
        expect(action?.dangerOutlined, isTrue);
        expect(action?.mainExtent, SelectionCommandChip.expandedLabeledExtent);

        action?.onTap?.call();

        expect(cancelled, isTrue);
      },
    );

    test('shows stop healing as the only wounded fortified unit action', () {
      final warrior = _warrior()
          .copyWith(movementPoints: 0, posture: UnitPosture.fortified)
          .copyWithHitPoints(7);
      var cancelled = false;

      final actions = _actions(
        gameState: GameState(
          units: [warrior],
          selection: GameSelection.unit(warrior),
        ),
        onCancelSelectedUnitAction: () => cancelled = true,
      );

      final action = _action(actions, 'Stop healing');

      expect(_actionLabels(actions), ['Stop healing']);
      expect(action?.actionId, 'stopHealing');
      expect(action?.icon, GameIcons.heartPlus);
      expect(action?.enabled, isTrue);
      expect(action?.active, isTrue);
      expect(action?.showLabel, isTrue);
      expect(action?.dangerOutlined, isTrue);
      expect(action?.mainExtent, SelectionCommandChip.labeledExtent);

      action?.onTap?.call();

      expect(cancelled, isTrue);
    });

    test('builds city detail, expansion, and production actions', () {
      final city = _city();
      var openedDescription = false;
      var openedBuildings = false;

      final actions = _actions(
        gameState: GameState(
          cities: [city],
          selection: GameSelection.city(
            city,
            cityYield: TileYield.zero,
            playerColor: 0,
          ),
        ),
        cityDescriptionActive: true,
        onToggleCityDescription: () => openedDescription = true,
        onToggleCityBuildingDetails: () => openedBuildings = true,
      );

      expect(_actionLabels(actions), [
        'Description',
        'Buildings',
        'City growth',
        'Production',
      ]);
      expect(_action(actions, 'Description')?.active, isTrue);
      expect(_action(actions, 'Buildings')?.active, isFalse);
      expect(
        actions.whereType<SelectionCommandChip>().map((action) {
          return action.color;
        }).toSet(),
        hasLength(1),
      );

      _action(actions, 'Description')?.onTap?.call();
      _action(actions, 'Buildings')?.onTap?.call();

      expect(openedDescription, isTrue);
      expect(openedBuildings, isTrue);
    });

    test('active city expansion action uses the cancel outline style', () {
      final city = _city();

      final actions = _actions(
        gameState: GameState(
          cities: [city],
          selection: GameSelection.city(
            city,
            cityYield: TileYield.zero,
            playerColor: 0,
          ),
          pendingAction: PendingCityExpansionSelection(
            ownerPlayerId: city.ownerPlayerId,
            cityId: city.id,
          ),
        ),
      );
      final action = _action(actions, 'Cancel growth');

      expect(action?.active, isTrue);
      expect(action?.color, GameUiTheme.danger);
      expect(action?.dangerOutlined, isTrue);
    });

    test(
      'keeps city expansion visible when technology raises the hex limit',
      () {
        final city = _city().copyWith(maxHexes: 2);
        final research = ResearchState().updatePlayer(
          'player_1',
          PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.urbanization},
          ),
        );

        final actions = _actions(
          gameState: GameState(
            cities: [city],
            research: research,
            selection: GameSelection.city(
              city,
              cityYield: TileYield.zero,
              playerColor: 0,
            ),
          ),
        );

        expect(_action(actions, 'City growth'), isNotNull);
      },
    );

    test('hides city expansion when the effective hex limit is reached', () {
      final city = _city().copyWith(maxHexes: 2);

      final actions = _actions(
        gameState: GameState(
          cities: [city],
          selection: GameSelection.city(
            city,
            cityYield: TileYield.zero,
            playerColor: 0,
          ),
        ),
      );

      expect(_action(actions, 'City growth'), isNull);
    });
  });
}

List<Widget> _actions({
  required GameState gameState,
  bool actionsLocked = false,
  bool armyDetailActive = false,
  bool canStartCityFounding = false,
  bool cityFoundingActive = false,
  bool cityDescriptionActive = false,
  bool cityBuildingsDetailActive = false,
  MapData? mapData,
  WorkerActionPanelViewModel? workerAction,
  VoidCallback? onStartCityFounding,
  VoidCallback? onConfirmCityFounding,
  VoidCallback? onCancelCityFounding,
  VoidCallback? onAutoExploreSelectedUnit,
  VoidCallback? onCancelSelectedUnitAction,
  VoidCallback? onStartWorkerActionSelection,
  VoidCallback? onCancelWorkerActionSelection,
  VoidCallback? onCancelWorkerJob,
  VoidCallback? onCancelAttackTargeting,
  VoidCallback? onToggleCityDescription,
  VoidCallback? onToggleCityBuildingDetails,
  VoidCallback? onStartMerchantTradeRouteSelection,
  VoidCallback? onCancelMerchantTradeRouteSelection,
  ValueChanged<String>? onAssignMerchantTradeRoute,
  VoidCallback? onStartMerchantMoveToCitySelection,
  VoidCallback? onCancelMerchantMoveToCitySelection,
  ValueChanged<String>? onMoveMerchantToCity,
}) {
  return buildHudSelectionActionChips(
    gameState: gameState,
    mapData: mapData ?? _mapData(cols: 1, rows: 1),
    activePlayerId: 'player_1',
    actionsLocked: actionsLocked,
    moveModeActive: false,
    armyDetailActive: armyDetailActive,
    workerAction: workerAction,
    cityBuildingsModeActive: false,
    cityDescriptionActive: cityDescriptionActive,
    cityBuildingsDetailActive: cityBuildingsDetailActive,
    cityRuleset: CityRulesets.standard,
    technologyRuleset: TechnologyRulesets.standard,
    l10n: AppLocalizationsEn(),
    canStartCityFounding: canStartCityFounding,
    cityFoundingActive: cityFoundingActive,
    onMoveSelectedUnit: () {},
    onAutoExploreSelectedUnit: onAutoExploreSelectedUnit ?? () {},
    onStartAttackTargeting: () {},
    onCancelAttackTargeting: onCancelAttackTargeting ?? () {},
    onShowArmy: () {},
    onStartWorkerActionSelection: onStartWorkerActionSelection ?? () {},
    onCancelWorkerActionSelection: onCancelWorkerActionSelection ?? () {},
    onCancelWorkerJob: onCancelWorkerJob ?? () {},
    onStartArtifactExcavation: () {},
    onStoreArtifactInCity: () {},
    onStartMerchantTradeRouteSelection:
        onStartMerchantTradeRouteSelection ?? () {},
    onCancelMerchantTradeRouteSelection:
        onCancelMerchantTradeRouteSelection ?? () {},
    onAssignMerchantTradeRoute: onAssignMerchantTradeRoute ?? (_) {},
    onStartMerchantMoveToCitySelection:
        onStartMerchantMoveToCitySelection ?? () {},
    onCancelMerchantMoveToCitySelection:
        onCancelMerchantMoveToCitySelection ?? () {},
    onMoveMerchantToCity: onMoveMerchantToCity ?? (_) {},
    onStartCityFounding: onStartCityFounding ?? () {},
    onConfirmCityFounding: onConfirmCityFounding ?? () {},
    onCancelCityFounding: onCancelCityFounding ?? () {},
    onSkipSelectedUnitTurn: () {},
    onFortifySelectedUnit: () {},
    onCancelSelectedUnitAction: onCancelSelectedUnitAction ?? () {},
    onToggleCityDescription: onToggleCityDescription ?? () {},
    onToggleCityBuildingDetails: onToggleCityBuildingDetails ?? () {},
    onStartCityExpansionSelection: () {},
    onCancelCityExpansionSelection: () {},
    onToggleCityBuildings: () {},
  );
}

List<String> _actionLabels(List<Widget> actions) {
  return [
    for (final action in actions)
      if (action is SelectionCommandChip) action.label,
  ];
}

List<String> _actionLayout(List<Widget> actions) {
  return [
    for (final action in actions)
      switch (action) {
        SelectionCommandChip(:final label) => label,
        SelectionActionGroupBreak() => '|',
        _ => '?',
      },
  ];
}

SelectionCommandChip? _action(List<Widget> actions, String label) {
  return actions
      .whereType<SelectionCommandChip>()
      .where((action) => action.label == label)
      .firstOrNull;
}

GameUnit _scout() {
  return GameUnit(
    id: 'scout_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.scout,
    name: GameUnitType.scout.defaultNameToken,
    col: 0,
    row: 0,
  );
}

GameUnit _worker() {
  return GameUnit(
    id: 'worker_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.worker,
    name: GameUnitType.worker.defaultNameToken,
    col: 0,
    row: 0,
  );
}

GameUnit _merchant({String id = 'merchant_1', int col = 0, int row = 0}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.merchant,
    name: GameUnitType.merchant.defaultNameToken,
    col: col,
    row: row,
  );
}

MapData _mapData({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

WorkerActionPanelViewModel _workerAction({
  bool selectionActive = false,
  bool activeJob = false,
}) {
  return WorkerActionPanelViewModel(
    unitId: 'worker_1',
    unitName: 'Worker',
    currentHex: const CityHex(col: 0, row: 0),
    movementPoints: 2,
    selectionActive: selectionActive,
    selectedImprovementType: null,
    activeJob: activeJob
        ? const WorkerJobProgressViewModel(
            improvementType: FieldImprovementType.farm,
            improvementName: 'Farm',
            targetHex: CityHex(col: 0, row: 0),
            remainingTurns: 2,
            totalTurns: 2,
          )
        : null,
    options: const [
      WorkerImprovementOptionViewModel(
        improvementType: FieldImprovementType.farm,
        title: 'Farm',
        yield: TileYield(food: 1, production: 0, gold: 0, defense: 0),
        buildTurns: 2,
        state: WorkerImprovementOptionState.available,
        reason: 'Can build',
        canSelect: true,
        score: 1,
      ),
    ],
  );
}

GameUnit _warrior({
  String id = 'warrior_1',
  String ownerPlayerId = 'player_1',
  int col = 0,
  int row = 0,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: col,
    row: row,
  );
}

GameUnit _settler() {
  return GameUnit(
    id: 'settler_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.settler,
    name: GameUnitType.settler.defaultNameToken,
    col: 0,
    row: 0,
  );
}

QueuedMovePath _queuedPath() {
  return QueuedMovePath(
    targetCol: 2,
    targetRow: 0,
    steps: const [
      UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
    ],
  );
}

GameCity _city({
  String id = 'city_1',
  String name = 'City',
  String ownerPlayerId = 'player_1',
  int col = 0,
  int row = 0,
}) {
  return GameCity(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: name,
    center: CityHex(col: col, row: row),
    controlledHexes: [CityHex(col: col, row: row)],
  );
}
