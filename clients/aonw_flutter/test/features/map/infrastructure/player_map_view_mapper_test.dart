import 'package:aonw_flutter/features/map/infrastructure/player_map_view_mapper.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/turns/read_model/recipient_turn_view.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const mapper = PlayerMapViewMapper();

  test('maps the complete recipient-safe unit snapshot', () {
    final map = testMapScene().map;
    final player = mapper.fromWire(
      _snapshot([
        _unit('unit-a', col: 1, row: 0),
        _unit('unit-b', col: 2, row: 1),
      ]),
      map: map,
      actorPlayerId: 'player-1',
    );

    expect(player.stamp.mapHash, map.contentHash);
    expect(player.stamp.revision, 7);
    expect(player.turn, 7);
    expect(player.turnView.ownState, RecipientTurnStateView.active);
    expect(player.turnView.ownSubmitted, isFalse);
    expect(player.turnView.requiredSubmissionCount, 1);
    expect(player.turnView.submittedCount, 0);
    expect(player.turnView.outcome.condition, GameOutcomeConditionView.ongoing);
    expect(player.turnView.canEndTurn, isTrue);
    expect(player.units.map((unit) => unit.id), ['unit-a', 'unit-b']);
    expect(player.units.first.kind, VisibleUnitKind.commander);
    expect(player.units.first.posture, VisibleUnitPosture.active);
    expect(player.units.first.movementUnits, 12);
  });

  test(
    'indexes controlled logistics details without inventing foreign data',
    () {
      final player = mapper.fromWire(
        _snapshot([
          _unit(
            'unit-a',
            ownedDetails: const AonwOwnedUnitDetails(
              army: [AonwArmyTroop(kind: AonwTroopKind.archer, count: 2)],
              queuedPath: AonwQueuedMovePath(
                target: AonwCoordinate(col: 1, row: 0),
                steps: [],
              ),
              merchantTradeRoute: AonwMerchantTradeRoute(
                originCityId: 'city-a',
                destinationCityId: 'city-b',
                steps: [],
                transportNetworkFingerprint: 'road-network',
              ),
              workerJob: null,
              cityFoundingJob: null,
              workerAssignment: null,
              excavatingArtifactId: null,
              workerBuildCharges: 0,
              experiencePoints: 0,
            ),
          ),
          _unit('unit-b', ownerPlayerId: 'player-2'),
        ]),
        map: testMapScene().map,
        actorPlayerId: 'player-1',
      );

      final controlled = player.controlledUnitById('unit-a')!;
      expect(controlled.army.single.count, 2);
      expect(controlled.queuedTarget, (col: 1, row: 0));
      expect(controlled.merchantRouteDestinationCityId, 'city-b');
      expect(player.controlledUnitById('unit-b'), isNull);
      expect(player.units.last.army, isEmpty);
      expect(player.unitsAt((col: 0, row: 0)), hasLength(2));
    },
  );

  test('rejects a snapshot for another map', () {
    final map = testMapScene();

    expect(
      () => mapper.fromWire(
        _snapshot([], mapHash: 'd' * 64),
        map: map.map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
  });

  test('rejects a non-positive authoritative turn', () {
    final map = testMapScene().map;
    final snapshot = _snapshot([]);
    final invalid = AonwPlayerViewSnapshot(
      stamp: snapshot.stamp,
      turn: 0,
      outcome: snapshot.outcome,
      turnLifecycle: snapshot.turnLifecycle,
      pendingAction: snapshot.pendingAction,
      cityFoundingDraft: snapshot.cityFoundingDraft,
      diplomacy: snapshot.diplomacy,
      units: snapshot.units,
      cities: snapshot.cities,
      artifacts: snapshot.artifacts,
      fieldImprovements: snapshot.fieldImprovements,
      roads: snapshot.roads,
    );

    expect(
      () => mapper.fromWire(invalid, map: map, actorPlayerId: 'player-1'),
      throwsFormatException,
    );
  });

  test('rejects unordered, duplicated, or out-of-map units', () {
    final map = testMapScene().map;

    expect(
      () => mapper.fromWire(
        _snapshot([_unit('unit-b'), _unit('unit-a')]),
        map: map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.fromWire(
        _snapshot([_unit('unit-a'), _unit('unit-a')]),
        map: map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.fromWire(
        _snapshot([_unit('unit-a', col: 99)]),
        map: map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
  });

  test('maps an engine-owned pending action without deriving its rules', () {
    final map = testMapScene().map;
    final player = mapper.fromWire(
      _snapshot(
        [_unit('unit-a')],
        pendingAction: const AonwPendingWorkerActionSelection(
          unitId: 'unit-a',
          improvement: AonwFieldImprovementKind.farm,
        ),
      ),
      map: map,
      actorPlayerId: 'player-1',
    );

    final pending = player.pendingAction;
    expect(pending, isA<PendingWorkerActionSelectionView>());
    expect(
      (pending! as PendingWorkerActionSelectionView).improvement,
      FieldImprovementKind.farm,
    );
  });

  test(
    'rejects pending actions for an uncontrolled unit or invalid target',
    () {
      final map = testMapScene().map;

      expect(
        () => mapper.fromWire(
          _snapshot(
            [_unit('unit-a')],
            pendingAction: const AonwPendingUnitTurnSkip(
              unitId: 'unit-b',
              restoreMovementUnits: 4,
            ),
          ),
          map: map,
          actorPlayerId: 'player-1',
        ),
        throwsFormatException,
      );
      expect(
        () => mapper.fromWire(
          _snapshot(
            [_unit('unit-a')],
            pendingAction: const AonwPendingAttackTargeting(
              unitId: 'unit-a',
              defender: AonwCoordinate(col: 99, row: 99),
            ),
          ),
          map: map,
          actorPlayerId: 'player-1',
        ),
        throwsFormatException,
      );
    },
  );
}

AonwPlayerViewSnapshot _snapshot(
  List<AonwPlayerUnitView> units, {
  String? mapHash,
  AonwPendingActionView? pendingAction,
}) => AonwPlayerViewSnapshot(
  stamp: AonwSessionStamp(
    revision: 7,
    stateDigest: 'b' * 64,
    mapHash: mapHash ?? 'a' * 64,
    rulesetHash: 'c' * 64,
  ),
  turn: 7,
  outcome: AonwGameOutcome(
    condition: AonwGameOutcomeCondition.ongoing,
    winnerPlayerId: null,
    scoreByPlayerId: const {},
  ),
  turnLifecycle: const AonwPlayerTurnLifecycle(
    ownState: AonwPlayerTurnState.active,
    ownSubmitted: false,
    requiredSubmissionCount: 1,
    submittedCount: 0,
  ),
  pendingAction: pendingAction,
  cityFoundingDraft: null,
  diplomacy: const AonwPlayerDiplomacyView(
    relations: [],
    proposals: [],
    messages: [],
    resourceTradeAgreements: [],
  ),
  units: units,
  cities: const [],
  artifacts: const [],
  fieldImprovements: const [],
  roads: const [],
);

AonwPlayerUnitView _unit(
  String id, {
  int col = 0,
  int row = 0,
  String ownerPlayerId = 'player-1',
  AonwOwnedUnitDetails? ownedDetails,
}) => AonwPlayerUnitView(
  id: id,
  ownerPlayerId: ownerPlayerId,
  kind: AonwUnitKind.commander,
  name: 'Commander',
  coordinate: AonwCoordinate(col: col, row: row),
  movementUnits: 12,
  posture: AonwUnitPosture.active,
  workerBuildCharges: 0,
  workerJob: null,
  workerAssignment: null,
  ownedDetails: ownedDetails,
);
