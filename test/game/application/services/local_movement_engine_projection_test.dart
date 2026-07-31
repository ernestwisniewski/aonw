import 'dart:convert';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/application/services/local_movement_presentation_origin.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

part 'local_movement_engine_projection_test_support.dart';
part 'local_movement_engine_projection_retargeting_test.dart';

const _playerId = 'player_1';

void main() {
  test('direct local move preserves inactive presentation targeting', () {
    final unit = _unit(id: 'mover', movementPoints: 4);
    final state = GameState(
      activePlayerId: _playerId,
      units: [unit],
      interaction: GameInteractionState(selection: GameSelection.unit(unit)),
    );
    final baseSnapshot = _snapshot(state);
    final savedAt = DateTime.utc(2026, 7, 29, 18);

    final result = _resolver(_map(cols: 4)).resolve(
      baseSnapshot: baseSnapshot,
      currentState: state,
      command: const MoveUnitCommand('mover', 2, 0),
      savedAt: savedAt,
      context: const GameCommandContext(
        actorPlayerId: _playerId,
        commandTick: 9,
      ),
    );

    expect(result.state.activePlayerId, _playerId);
    expect(result.state.units.single.col, 2);
    expect(result.state.selectedUnitId, 'mover');
    expect(result.state.selection?.unit, same(result.state.units.single));
    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isFalse);
    expect(result.snapshot.domain.units, result.state.units);
    expect(result.snapshot.save.savedAt, savedAt);
    expect(result.events, [
      isA<UnitMovedEvent>().having((event) => event.toCol, 'toCol', 2),
    ]);
    final execution = result.movementExecutions.single;
    expect(
      (execution.unitId, execution.fromCol, execution.fromRow),
      ('mover', 0, 0),
    );
    expect(execution.steps.map((step) => step.col), [1, 2]);
  });

  test('capacity rejection keeps state and projects stable HUD feedback', () {
    final unit = _unit(id: 'mover', movementPoints: 10);
    final state = GameState(activePlayerId: _playerId, units: [unit]);
    final baseSnapshot = _snapshot(state);

    final result =
        _resolver(
          _map(
            cols: 2,
            terrainOverrides: {
              1: const [
                TerrainType.plains,
                TerrainType.forest,
                TerrainType.jungle,
                TerrainType.hills,
              ],
            },
          ),
        ).resolve(
          baseSnapshot: baseSnapshot,
          currentState: state,
          command: const MoveUnitCommand('mover', 1, 0),
          savedAt: DateTime.utc(2026, 7, 29, 19),
          context: const GameCommandContext(actorPlayerId: _playerId),
        );

    expect(result.state, same(state));
    expect(result.snapshot.domain, baseSnapshot.domain);
    expect(result.events, isEmpty);
    expect(result.uiEffects, [
      isA<ShowHudFeedbackEffect>().having(
        (effect) => effect.reason,
        'reason',
        HudFeedbackReason.movementInsufficientUnitMovement,
      ),
    ]);
  });

  test('rejected preview confirmation keeps targeting available', () {
    final unit = _unit(id: 'mover', movementPoints: 3);
    final preview = UnitMovementPlan(
      unitId: unit.id,
      targetCol: 1,
      targetRow: 0,
      totalCost: 4,
      availableMovementPoints: unit.movementPoints,
      steps: const [
        UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
        UnitMovementStep(col: 1, row: 0, enterCost: 4, cumulativeCost: 4),
      ],
    );
    final state = GameState(
      activePlayerId: _playerId,
      units: [unit],
      interaction: GameInteractionState(
        selection: GameSelection.unit(unit),
        moveCommandActive: true,
        movePreview: preview,
      ),
    );
    final map = _map(
      cols: 2,
      terrainOverrides: {
        1: const [
          TerrainType.plains,
          TerrainType.forest,
          TerrainType.jungle,
          TerrainType.hills,
        ],
      },
    );

    final result = _resolver(map).resolve(
      baseSnapshot: _snapshot(state),
      currentState: state,
      command: const MoveUnitCommand('mover', 1, 0),
      savedAt: DateTime.utc(2026, 7, 29, 19, 15),
      context: const GameCommandContext(actorPlayerId: _playerId),
      movementPresentationOrigin:
          LocalMovementPresentationOrigin.previewConfirmation,
    );

    expect(result.state.moveCommandActive, isTrue);
    expect(result.state.movePreview, isNull);
    expect(result.state.selectedUnitId, unit.id);
    expect(result.uiEffects, [
      isA<ShowHudFeedbackEffect>().having(
        (effect) => effect.reason,
        'reason',
        HudFeedbackReason.movementInsufficientUnitMovement,
      ),
    ]);
  });

  test('preview confirmation ends targeting when the player cannot act', () {
    final unit = _unit(id: 'mover');
    final state = GameState(
      activePlayerId: _playerId,
      units: [unit],
      interaction: GameInteractionState(
        selection: GameSelection.unit(unit),
        moveCommandActive: true,
        movePreview: UnitMovementPlan(
          unitId: unit.id,
          targetCol: 1,
          targetRow: 0,
          totalCost: 1,
          availableMovementPoints: unit.movementPoints,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
      ),
    );

    final result = _resolver(_map(cols: 2)).resolve(
      baseSnapshot: _snapshot(state),
      currentState: state,
      command: const MoveUnitCommand('mover', 1, 0),
      savedAt: DateTime.utc(2026, 7, 29, 19, 20),
      context: const GameCommandContext(
        actorPlayerId: _playerId,
        canAct: false,
      ),
      movementPresentationOrigin:
          LocalMovementPresentationOrigin.previewConfirmation,
    );

    expect(result.state.units, state.units);
    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isFalse);
  });

  _registerLocalMovementRetargetingTests();

  test(
    'cancel refreshes selection and wakes a fortified unit into move mode',
    () {
      final unit = _unit(
        id: 'mover',
        movementPoints: 0,
        posture: UnitPosture.fortified,
      );
      final state = GameState(
        activePlayerId: _playerId,
        units: [unit],
        interaction: GameInteractionState(
          selection: GameSelection.unit(unit),
          pendingAction: const PendingUnitTurnSkip(
            ownerPlayerId: _playerId,
            unitId: 'mover',
            restoreMovementPoints: 3,
          ),
        ),
      );

      final result = _resolver(_map(cols: 2)).resolve(
        baseSnapshot: _snapshot(state),
        currentState: state,
        command: const CancelUnitActionCommand('mover'),
        savedAt: DateTime.utc(2026, 7, 29, 20),
        context: const GameCommandContext(actorPlayerId: _playerId),
      );

      expect(result.state.units.single.posture, UnitPosture.active);
      expect(result.state.units.single.movementPoints, 3);
      expect(result.state.pendingAction, isNull);
      expect(result.state.selection?.unit, same(result.state.units.single));
      expect(result.state.moveCommandActive, isTrue);
      expect(result.uiEffects, isEmpty);
    },
  );

  test(
    'auto explore clears owned interaction and uses its execution delta',
    () {
      final scout = _unit(
        id: 'scout',
        type: GameUnitType.scout,
        movementPoints: 3,
      );
      final state = GameState(
        activePlayerId: _playerId,
        units: [scout],
        fogOfWar: _fog(visibleCols: 1),
        interaction: GameInteractionState(
          selection: GameSelection.unit(scout),
          moveCommandActive: true,
          cityFoundingDraft: CityFoundingDraft(
            unitId: scout.id,
            ownerPlayerId: _playerId,
            center: const CityHex(col: 0, row: 0),
          ),
        ),
      );

      final result = _resolver(_map(cols: 4)).resolve(
        baseSnapshot: _snapshot(state),
        currentState: state,
        command: const AutoExploreUnitCommand('scout'),
        savedAt: DateTime.utc(2026, 7, 29, 21),
        context: const GameCommandContext(actorPlayerId: _playerId),
      );

      expect(result.state.units.single.posture, UnitPosture.autoExploring);
      expect(result.state.cityFoundingDraft, isNull);
      expect(result.state.moveCommandActive, isFalse);
      expect(result.state.movePreview, isNull);
      expect(result.state.selection?.unit, same(result.state.units.single));
      expect(result.movementExecutions, hasLength(1));
      expect(result.movementExecutions.single.unitId, 'scout');
    },
  );

  test('merchant and detachment project their exact interaction cleanup', () {
    final merchant = _unit(id: 'merchant', type: GameUnitType.merchant);
    final merchantState = GameState(
      activePlayerId: _playerId,
      units: [merchant],
      cities: [_city('origin', 0), _city('destination', 3)],
      interaction: GameInteractionState(
        selection: GameSelection.unit(merchant),
        pendingAction: const PendingMerchantTradeRouteSelection(
          ownerPlayerId: _playerId,
          unitId: 'merchant',
        ),
        moveCommandActive: true,
      ),
    );
    final resolver = _resolver(_map(cols: 4, rows: 3));

    final merchantResult = resolver.resolve(
      baseSnapshot: _snapshot(merchantState),
      currentState: merchantState,
      command: const AssignMerchantTradeRouteCommand('merchant', 'destination'),
      savedAt: DateTime.utc(2026, 7, 29, 22),
      context: const GameCommandContext(actorPlayerId: _playerId),
    );

    expect(merchantResult.state.pendingAction, isNull);
    expect(merchantResult.state.moveCommandActive, isFalse);
    expect(
      merchantResult
          .state
          .selection
          ?.unit
          ?.merchantTradeRoute
          ?.destinationCityId,
      'destination',
    );

    final commander = _unit(
      id: 'commander',
      type: GameUnitType.commander,
      col: 1,
      row: 1,
      army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
    );
    final detachmentState = GameState(
      activePlayerId: _playerId,
      units: [commander],
      fogOfWar: _fogGrid(cols: 4, rows: 3),
      interaction: GameInteractionState(
        selection: GameSelection.tile(_map(cols: 4, rows: 3).tileAt(0, 0)!),
        moveCommandActive: true,
        cityFoundingDraft: CityFoundingDraft(
          unitId: commander.id,
          ownerPlayerId: _playerId,
          center: const CityHex(col: 1, row: 1),
        ),
      ),
    );

    final detached = resolver.resolve(
      baseSnapshot: _snapshot(detachmentState),
      currentState: detachmentState,
      command: const DetachTroopCommand('commander', TroopType.warrior),
      savedAt: DateTime.utc(2026, 7, 29, 23),
      context: const GameCommandContext(actorPlayerId: _playerId),
    );

    expect(detached.state.units, hasLength(2));
    expect(detached.state.selectedUnitId, 'commander');
    expect(detached.state.selection?.unit, same(detached.state.units.first));
    expect(detached.state.moveCommandActive, isFalse);
    expect(detached.state.cityFoundingDraft, isNull);
    expect(detached.uiEffects, isEmpty);
  });

  test('accepted merchant identity still clears its presentation draft', () {
    final merchant = _unit(id: 'merchant', type: GameUnitType.merchant);
    final initial = GameState(
      activePlayerId: _playerId,
      units: [merchant],
      cities: [_city('origin', 0), _city('destination', 3)],
    );
    final resolver = _resolver(_map(cols: 4, rows: 3));
    final assigned = resolver.resolve(
      baseSnapshot: _snapshot(initial),
      currentState: initial,
      command: const AssignMerchantTradeRouteCommand('merchant', 'destination'),
      savedAt: DateTime.utc(2026, 7, 29, 22),
      context: const GameCommandContext(actorPlayerId: _playerId),
    );
    final assignedMerchant = assigned.state.units.single;
    final pendingState = assigned.state.copyWithInteraction(
      selection: GameSelection.unit(assignedMerchant),
      pendingAction: const PendingMerchantTradeRouteSelection(
        ownerPlayerId: _playerId,
        unitId: 'merchant',
      ),
      moveCommandActive: true,
      movePreview: UnitMovementPlan(
        unitId: merchant.id,
        targetCol: 1,
        targetRow: 0,
        totalCost: 1,
        availableMovementPoints: 3,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      ),
      cityFoundingDraft: CityFoundingDraft(
        unitId: merchant.id,
        ownerPlayerId: _playerId,
        center: const CityHex(col: 0, row: 0),
      ),
    );

    final repeated = resolver.resolve(
      baseSnapshot: assigned.snapshot,
      currentState: pendingState,
      command: const AssignMerchantTradeRouteCommand('merchant', 'destination'),
      savedAt: DateTime.utc(2026, 7, 29, 22, 1),
      context: const GameCommandContext(actorPlayerId: _playerId),
    );

    expect(repeated.snapshot.domain, same(assigned.snapshot.domain));
    expect(repeated.state.units, pendingState.units);
    expect(repeated.state.pendingAction, isNull);
    expect(repeated.state.moveCommandActive, isFalse);
    expect(repeated.state.movePreview, isNull);
    expect(repeated.state.cityFoundingDraft, isNull);
  });

  test('movement projection preserves sparse raw persistence envelope', () {
    final unit = _unit(id: 'mover', movementPoints: 3);
    final baseSnapshot = SaveSnapshot(
      save: _save().copyWith(players: const [], gameMode: GameMode.multiplayer),
      playerColors: const {_playerId: 0xFF010203},
      playerCountries: const {'country_only': PlayerCountry.canada},
      units: [unit],
      runtimeState: GameRuntimeState.snapshot(
        submittedPlayerIds: const {'session_only'},
        timeoutStreaksByPlayerId: const {'timeout_only': 2},
        afkPlayerIds: const {'afk_only'},
        kickedPlayerIds: const {'kicked_only'},
      ),
      eventLogOffset: 73,
    );
    final before = SaveSnapshotCodec.toJson(baseSnapshot);
    final savedAt = DateTime.utc(2026, 7, 29, 23, 30);

    final result = _resolver(_map(cols: 2)).resolve(
      baseSnapshot: baseSnapshot,
      currentState: baseSnapshot.toGameState(activePlayerId: _playerId),
      command: const MoveUnitCommand('mover', 1, 0),
      savedAt: savedAt,
      context: const GameCommandContext(actorPlayerId: _playerId),
    );
    final after = SaveSnapshotCodec.toJson(result.snapshot);

    expect(
      _unreviewedMovementEnvelopeBytes(after),
      _unreviewedMovementEnvelopeBytes(before),
    );
    expect(result.snapshot.save.players, isEmpty);
    expect(result.snapshot.eventLogOffset, 73);
    expect(result.snapshot.units.single.col, 1);
    expect(result.snapshot.persistedTurnStartedAt, isNull);
    expect(result.snapshot.runtimeState.submittedPlayerIds, {'session_only'});
  });
}
